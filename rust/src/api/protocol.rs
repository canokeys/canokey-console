//! Owned libcanokey operations. Dart owns the selected connection and every I/O.
use std::sync::Mutex;

use canokey::{
    admin, ctap, ndef, oath, openpgp, piv, Error, ErrorKind, Operation, OperationOptions, Phase,
    SecretBytes, Step,
};
use canokey_protocol::operation::{conversation, ResponseData};

/// Initial PIV operations; reads require an already selected PIV application.
#[derive(Clone, Copy)]
pub enum PivReadOperation {
    Select,
    Version,
    AlgorithmConfiguration,
    PinStatus,
}

/// Explicit actions in an already prepared lease; never SELECT or probe.
#[derive(Clone, Copy)]
pub enum PivCredentialOperation {
    VerifyPin,
    ChangePin,
    ChangePuk,
    UnblockPin,
    Logout,
}

/// Connection-bootstrap identity steps; raw Admin commands without a profile.
/// Upstream builders own encoding and safe Le correction; no authentication,
/// no other applet selection and no device observations are created.
#[derive(Clone, Copy)]
pub enum BootstrapIdentityStep {
    SelectAdmin,
    Serial,
}

/// Admin operations always SELECT, then verify only an explicitly supplied PIN.
#[derive(Clone, Copy)]
pub enum AdminReadOperation {
    Firmware,
    Model,
    Serial,
    ChipId,
    CoreCommit,
    Configuration,
    FlashUsage,
    AppletUsage,
    KeyboardLayout,
    KeyboardKeymap,
    NfcStatus,
    Sm2Configuration,
}
#[derive(Clone, Copy)]
pub enum AdminAction {
    VerifyPin,
    ChangePin,
    KeyboardInterface,
    KeyboardReturn,
    KeyboardKeymap,
    ClearKeyboardKeymap,
    LegacyPivExtensions,
    LegacyTouch,
    WriteSm2,
    Nfc,
    ResetOpenPgp,
    ResetPiv,
    ResetOath,
    ResetNdef,
    ResetCtap,
    ResetPass,
    FactoryReset,
}
pub struct AdminConfigurationPatch {
    pub led_on: Option<bool>,
    pub ndef_read_only: Option<bool>,
    pub ndef_enabled: Option<bool>,
    pub webusb_landing: Option<bool>,
    pub feature_mask: u8,
    pub feature_values: u8,
}
#[derive(Clone, Copy)]
pub enum AdminValueKind {
    None,
    Bytes,
    Configuration,
    LegacyConfiguration,
    FlashUsage,
    AppletUsage,
    NfcStatus,
    Sm2Configuration,
    LegacySm2Configuration,
    PinStatus,
    KeyboardLayout,
    KeyboardKeymap,
    PassSlots,
}
/// Copy progress before close, including on transport failure or cancellation.
pub struct AdminProgress {
    pub confirmed_writes: u32,
    pub reprobe_required: bool,
}
pub struct AdminResult {
    pub kind: AdminValueKind,
    pub data: Vec<u8>,
    pub progress: AdminProgress,
}
fn admin_progress(outcome: &admin::Outcome) -> AdminProgress {
    AdminProgress {
        confirmed_writes: outcome.confirmed_writes as u32,
        reprobe_required: outcome.reprobe_required,
    }
}
fn admin_result(outcome: admin::Outcome) -> AdminResult {
    let progress = admin_progress(&outcome);
    use admin::Value;
    let (kind, data) = match outcome.value {
        Value::None => (AdminValueKind::None, vec![]),
        Value::Bytes(data) => (AdminValueKind::Bytes, data),
        Value::Configuration(c) => (AdminValueKind::Configuration, c.raw().to_vec()),
        Value::LegacyConfiguration(c) => (AdminValueKind::LegacyConfiguration, c.raw().to_vec()),
        Value::FlashUsage(v) => (AdminValueKind::FlashUsage, vec![v.used_kib, v.total_kib]),
        Value::AppletUsage(values) => (
            AdminValueKind::AppletUsage,
            values
                .into_iter()
                .flat_map(|v| {
                    let mut data = vec![v.applet_id, v.flags];
                    data.extend(v.logical_bytes.to_be_bytes());
                    data
                })
                .collect(),
        ),
        Value::NfcStatus(on) => (AdminValueKind::NfcStatus, vec![u8::from(on)]),
        Value::Sm2Configuration(c) => (AdminValueKind::Sm2Configuration, c.to_bytes().to_vec()),
        Value::LegacySm2Configuration(c) => {
            (AdminValueKind::LegacySm2Configuration, c.raw().to_vec())
        }
        Value::PinStatus(v) => (
            AdminValueKind::PinStatus,
            vec![
                u8::from(v.verified),
                v.retries_remaining.unwrap_or(0xff),
                u8::from(v.blocked),
            ],
        ),
        Value::KeyboardLayout(v) => (AdminValueKind::KeyboardLayout, vec![v]),
        Value::KeyboardKeymap(v) => (AdminValueKind::KeyboardKeymap, v.as_bytes().to_vec()),
        Value::PassSlots(v) => (AdminValueKind::PassSlots, pass_slots_data(v)),
    };
    AdminResult {
        kind,
        data,
        progress,
    }
}

/// PASS slot states are self-delimiting, but each state is additionally
/// length-prefixed so Dart never re-implements the type dispatch:
/// `short_len | short | long_len | long`. One state is its type byte plus
/// payload: 0x00 off; 0x02 enter; 0x03 (HMAC-SHA1); 0x01 len name enter;
/// any other byte is an unknown type carried verbatim. Firmware never
/// returns secret slot material, so no secret bytes cross the bridge here.
fn pass_slots_data(slots: admin::PassSlots) -> Vec<u8> {
    fn state(state: admin::PassSlotState) -> Vec<u8> {
        use admin::PassSlotState;
        match state {
            PassSlotState::Off => vec![0x00],
            PassSlotState::Static { append_enter } => vec![0x02, u8::from(append_enter)],
            PassSlotState::HmacSha1 => vec![0x03],
            PassSlotState::Oath { name, append_enter } => {
                let mut data = Vec::with_capacity(name.len() + 3);
                data.push(0x01);
                data.push(name.len() as u8);
                data.extend_from_slice(&name);
                data.push(u8::from(append_enter));
                data
            }
            PassSlotState::Unknown(kind) => vec![kind],
        }
    }
    let short = state(slots.short);
    let long = state(slots.long);
    let mut data = Vec::with_capacity(short.len() + long.len() + 2);
    data.push(short.len() as u8);
    data.extend(short);
    data.push(long.len() as u8);
    data.extend(long);
    data
}

/// Structured, payload-free protocol failure. Transport errors remain in Dart.
pub struct ProtocolError {
    pub kind: String,
    pub phase: String,
    pub status_word: Option<u16>,
    pub reference: Option<String>,
    pub retries_remaining: Option<u8>,
}

impl From<Error> for ProtocolError {
    fn from(error: Error) -> Self {
        Self {
            kind: format!("{:?}", error.kind),
            phase: format!("{:?}", error.phase),
            status_word: error.status_word.map(|sw| sw.raw()),
            reference: error.reference.map(|reference| format!("{reference:?}")),
            retries_remaining: error.retries_remaining,
        }
    }
}

/// Exactly one field is present: exchange a command, consume a result, or fail.
/// Command and result copies belong to Dart; getters never perform I/O.
pub struct ProtocolStep {
    pub command: Option<Vec<u8>>,
    pub data: Option<Vec<u8>>,
    pub error: Option<ProtocolError>,
    pub profile: Option<ProtocolProfile>,
    pub admin: Option<AdminResult>,
}

impl ProtocolStep {
    fn failure(error: Error) -> Self {
        Self {
            command: None,
            data: None,
            error: Some(error.into()),
            profile: None,
            admin: None,
        }
    }
}

enum Inner {
    Bytes(Operation<SecretBytes>),
    PinStatus(Operation<piv::PinStatus>),
    Configuration(Operation<canokey::compatibility::AlgorithmConfig>),
    Certificate(Operation<piv::Certificate>),
    Probe(Operation<canokey::DeviceProfile>),
    Metadata(Operation<piv::Metadata>),
    Directory(Operation<piv::MetadataDirectory>),
    PublicKey(Operation<piv::PublicKey>),
    Signature(Operation<piv::Signature>),
    Sm2Agreement(Operation<piv::Sm2Agreement>),
    Oath(Operation<oath::Outcome>),
    OpenPgp(Operation<openpgp::Outcome>),
    Credential(Operation<piv::MutationResult>),
    Management(Operation<()>),
    Admin(Operation<admin::Outcome>),
    BootstrapSelect(Operation<ResponseData>),
    BootstrapSerial(Operation<ResponseData>),
    NdefCapability(Operation<ndef::NdefCapability>),
    NdefMessage(Operation<ndef::NdefMessage>),
    Ctap(Operation<ctap::CtapResponse>),
}

/// Immutable observations of one device. Dart binds this owner to a card lease.
/// It is not an authentication token; constructors copy their required evidence.
#[flutter_rust_bridge::frb(opaque)]
pub struct ProtocolProfile {
    inner: Option<canokey::DeviceProfile>,
}

impl ProtocolProfile {
    /// Bootstrap observations, not an authenticated session or cached credential.
    #[flutter_rust_bridge::frb(sync)]
    pub fn firmware(&self) -> Option<Vec<u8>> {
        self.inner
            .as_ref()
            .map(|p| p.info().firmware_text().to_vec())
    }
    #[flutter_rust_bridge::frb(sync)]
    pub fn model(&self) -> Option<String> {
        self.inner.as_ref()?.info().model().map(str::to_owned)
    }
    /// `existing` reuses the caller's selected, already authorized Admin
    /// transaction and forbids a PIN; otherwise the operation SELECTs and
    /// verifies only an explicitly supplied PIN.
    #[flutter_rust_bridge::frb(sync)]
    pub fn admin_read(
        &self,
        kind: AdminReadOperation,
        pin: Option<Vec<u8>>,
        existing: bool,
    ) -> ProtocolOperation {
        use admin::Request;
        let request = match kind {
            AdminReadOperation::Firmware => Request::Firmware,
            AdminReadOperation::Model => Request::Model,
            AdminReadOperation::Serial => Request::Serial,
            AdminReadOperation::ChipId => Request::ChipId,
            AdminReadOperation::CoreCommit => Request::CoreCommit,
            AdminReadOperation::Configuration => Request::Configuration,
            AdminReadOperation::FlashUsage => Request::FlashUsage,
            AdminReadOperation::AppletUsage => Request::AppletUsage,
            AdminReadOperation::KeyboardLayout => Request::KeyboardLayout,
            AdminReadOperation::KeyboardKeymap => Request::KeyboardKeymap,
            AdminReadOperation::NfcStatus => Request::NfcStatus,
            AdminReadOperation::Sm2Configuration => Request::Sm2Configuration,
        };
        self.admin_operation(Ok(request), pin, existing)
    }
    /// `existing` reuses the caller's authorized Admin transaction and forbids
    /// a PIN; otherwise the operation SELECTs and verifies the supplied PIN.
    #[flutter_rust_bridge::frb(sync)]
    pub fn admin_configure(
        &self,
        patch: AdminConfigurationPatch,
        pin: Option<Vec<u8>>,
        existing: bool,
    ) -> ProtocolOperation {
        self.admin_operation(
            Ok(admin::Request::Configure(admin::ConfigurationPatch {
                led_on: patch.led_on,
                ndef_read_only: patch.ndef_read_only,
                ndef_enabled: patch.ndef_enabled,
                webusb_landing: patch.webusb_landing,
                feature_mask: patch.feature_mask,
                feature_values: patch.feature_values,
            })),
            pin,
            existing,
        )
    }
    #[flutter_rust_bridge::frb(sync)]
    pub fn admin_action(
        &self,
        kind: AdminAction,
        pin: Option<Vec<u8>>,
        data: Vec<u8>,
        index: u8,
        value: u8,
        existing: bool,
    ) -> ProtocolOperation {
        let data = SecretBytes::new(data);
        let request = (|| {
            use admin::Request;
            let boolean = || match value {
                0 => Ok(false),
                1 => Ok(true),
                _ => Err(Error::new(ErrorKind::InvalidArgument)),
            };
            Ok(match kind {
                AdminAction::VerifyPin => Request::VerifyPin,
                AdminAction::ChangePin => {
                    Request::ChangePin(admin::Pin::from_bytes(data.as_bytes())?)
                }
                AdminAction::KeyboardInterface => Request::SetKeyboardInterface(boolean()?),
                AdminAction::KeyboardReturn => Request::SetKeyboardReturn(boolean()?),
                AdminAction::KeyboardKeymap => {
                    let keymap: [u8; 256] = data
                        .as_bytes()
                        .try_into()
                        .map_err(|_| Error::new(ErrorKind::InvalidArgument))?;
                    Request::SetKeyboardKeymap {
                        layout_id: index,
                        keymap: admin::KeyboardKeymap::from_bytes(&keymap)?,
                    }
                }
                AdminAction::ClearKeyboardKeymap => Request::ClearKeyboardKeymap,
                AdminAction::LegacyPivExtensions => Request::SetLegacyPivExtensions(boolean()?),
                AdminAction::LegacyTouch => Request::SetLegacyOpenPgpTouch(match index {
                    0 => admin::LegacyOpenPgpTouch::Signature(boolean()?),
                    1 => admin::LegacyOpenPgpTouch::Decryption(boolean()?),
                    2 => admin::LegacyOpenPgpTouch::Authentication(boolean()?),
                    3 => admin::LegacyOpenPgpTouch::CacheSeconds(value),
                    _ => return Err(Error::new(ErrorKind::InvalidArgument)),
                }),
                AdminAction::WriteSm2 => {
                    let profile = self
                        .inner
                        .as_ref()
                        .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
                    if profile
                        .capability(canokey::compatibility::Capability::AdminLegacySm2)
                        .support
                        == canokey::compatibility::Support::Supported
                    {
                        Request::WriteLegacySm2(admin::LegacySm2Configuration::from_bytes(
                            data.as_bytes(),
                        )?)
                    } else {
                        let c = admin::Sm2Configuration::parse(data.as_bytes())?;
                        Request::ConfigureSm2(admin::Sm2Patch {
                            curve_id: Some(c.curve_id),
                            algorithm_id: Some(c.algorithm_id),
                        })
                    }
                }
                AdminAction::Nfc => Request::SetNfc(boolean()?),
                AdminAction::ResetOpenPgp => Request::ResetApplet(admin::Applet::OpenPgp),
                AdminAction::ResetPiv => Request::ResetApplet(admin::Applet::Piv),
                AdminAction::ResetOath => Request::ResetApplet(admin::Applet::Oath),
                AdminAction::ResetNdef => Request::ResetApplet(admin::Applet::Ndef),
                AdminAction::ResetCtap => Request::ResetApplet(admin::Applet::Ctap),
                AdminAction::ResetPass => Request::ResetApplet(admin::Applet::Pass),
                AdminAction::FactoryReset => Request::FactoryReset,
            })
        })();
        self.admin_operation(request, pin, existing)
    }

    /// Read both typed PASS slot configurations (INS 43). `existing` reuses the
    /// caller's selected, already authorized Admin transaction and forbids a
    /// PIN; otherwise the operation SELECTs and verifies the supplied PIN.
    /// Secret slot material is never returned by firmware.
    #[flutter_rust_bridge::frb(sync)]
    pub fn admin_pass_slots(&self, pin: Option<Vec<u8>>, existing: bool) -> ProtocolOperation {
        self.admin_operation(Ok(admin::Request::PassSlots), pin, existing)
    }

    /// Replace one PASS slot (INS 44): slot 0 = short touch, 1 = long touch;
    /// kind 0 = off, 1 = static password (data, append_enter), 2 = HMAC-SHA1
    /// (data = 20-byte key). OATH slots are configured through the OATH
    /// applet, never here. The write is validated before any I/O.
    #[flutter_rust_bridge::frb(sync)]
    pub fn admin_set_pass_slot(
        &self,
        slot: u8,
        kind: u8,
        data: Vec<u8>,
        append_enter: bool,
        pin: Option<Vec<u8>>,
        existing: bool,
    ) -> ProtocolOperation {
        let data = SecretBytes::new(data);
        let request = (move || {
            let slot = match slot {
                0 => admin::PassSlotId::Short,
                1 => admin::PassSlotId::Long,
                _ => return Err(Error::new(ErrorKind::InvalidArgument)),
            };
            let config = match kind {
                0 => admin::PassSlotConfig::Off,
                1 => admin::PassSlotConfig::Static {
                    password: data,
                    append_enter,
                },
                2 => admin::PassSlotConfig::HmacSha1 { key: data },
                _ => return Err(Error::new(ErrorKind::InvalidArgument)),
            };
            Ok(admin::Request::SetPassSlot { slot, config })
        })();
        self.admin_operation(request, pin, existing)
    }
    fn admin_operation(
        &self,
        request: Result<admin::Request, Error>,
        pin: Option<Vec<u8>>,
        existing: bool,
    ) -> ProtocolOperation {
        let pin = pin.map(SecretBytes::new);
        ProtocolOperation::from_operation((|| {
            let profile = self
                .inner
                .as_ref()
                .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
            let pin = pin
                .as_ref()
                .map(|p| admin::Pin::from_bytes(p.as_bytes()))
                .transpose()?;
            // Existing reuses the caller's selected, already authorized Admin
            // transaction; carrying a PIN under it would be meaningless.
            let access = match (existing, pin) {
                (true, None) => admin::Access::Existing,
                (true, Some(_)) => return Err(Error::new(ErrorKind::InvalidArgument)),
                (false, None) => admin::Access::None,
                (false, Some(pin)) => admin::Access::Pin(pin),
            };
            admin::operation_with_access(profile, request?, access, OperationOptions::default())
                .map(Inner::Admin)
        })())
    }

    /// The serial observed during explicit discovery. Missing observations stay absent.
    #[flutter_rust_bridge::frb(sync)]
    pub fn serial(&self) -> Option<Vec<u8>> {
        self.inner.as_ref()?.info().serial().map(<[u8]>::to_vec)
    }

    /// Credentials are copied into upstream zeroizing owners before returning.
    /// Success does not turn this immutable profile into an authorization token.
    #[flutter_rust_bridge::frb(sync)]
    pub fn piv_credential(
        &self,
        kind: PivCredentialOperation,
        current: Vec<u8>,
        replacement: Vec<u8>,
    ) -> ProtocolOperation {
        let current = SecretBytes::new(current);
        let replacement = SecretBytes::new(replacement);
        let operation = (|| {
            let profile = self
                .inner
                .as_ref()
                .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
            use piv::CredentialAction;
            let action = match kind {
                PivCredentialOperation::VerifyPin => {
                    CredentialAction::VerifyPin(piv::Pin::from_bytes(current.as_bytes())?)
                }
                PivCredentialOperation::ChangePin => CredentialAction::ChangePin {
                    old: piv::Pin::from_bytes(current.as_bytes())?,
                    new: piv::Pin::from_bytes(replacement.as_bytes())?,
                },
                PivCredentialOperation::ChangePuk => CredentialAction::ChangePuk {
                    old: piv::Puk::from_bytes(current.as_bytes())?,
                    new: piv::Puk::from_bytes(replacement.as_bytes())?,
                },
                PivCredentialOperation::UnblockPin => CredentialAction::UnblockPin {
                    puk: piv::Puk::from_bytes(current.as_bytes())?,
                    new_pin: piv::Pin::from_bytes(replacement.as_bytes())?,
                },
                PivCredentialOperation::Logout => CredentialAction::Logout,
            };
            piv::credential(profile, action, false, OperationOptions::default())
                .map(Inner::Credential)
        })();
        ProtocolOperation::from_operation(operation)
    }

    /// Preserve Console's explicit external authentication mode. libcanokey owns
    /// the full challenge exchange and cryptography; no host login is inferred.
    #[flutter_rust_bridge::frb(sync)]
    pub fn piv_authenticate_management(&self, algorithm: u8, key: Vec<u8>) -> ProtocolOperation {
        let key = SecretBytes::new(key);
        let operation = (|| {
            let profile = self
                .inner
                .as_ref()
                .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
            let algorithm = match algorithm {
                0x03 => piv::ManagementKeyAlgorithm::Tdes,
                0x0a => piv::ManagementKeyAlgorithm::Aes192,
                _ => return Err(Error::new(ErrorKind::UnsupportedAlgorithm)),
            };
            let key = piv::ManagementKey::from_bytes(algorithm, key.as_bytes())?;
            piv::authenticate_management_key(
                profile,
                piv::ManagementAuthentication::external(key),
                false,
                OperationOptions::default(),
            )
            .map(Inner::Management)
        })();
        ProtocolOperation::from_operation(operation)
    }
    /// Read metadata in the caller's already selected PIV session. No probing,
    /// SELECT or authentication is inserted, including after VERIFY.
    #[flutter_rust_bridge::frb(sync)]
    pub fn piv_metadata(&self, reference: u8) -> ProtocolOperation {
        let operation = (|| {
            let profile = self
                .inner
                .as_ref()
                .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
            let reference = match reference {
                0x80 => piv::MetadataReference::Pin,
                0x81 => piv::MetadataReference::Puk,
                0x9b => piv::MetadataReference::Management,
                value => piv::MetadataReference::Key(piv_slot(value)?),
            };
            piv::get_metadata(
                profile,
                reference,
                piv::Access::Existing,
                OperationOptions::default(),
            )
            .map(Inner::Metadata)
        })();
        ProtocolOperation::from_operation(operation)
    }

    /// Read the PIV metadata directory in the caller's selected transaction.
    /// The upstream parser validates framing and preserves the raw directory.
    #[flutter_rust_bridge::frb(sync)]
    pub fn piv_metadata_directory(&self) -> ProtocolOperation {
        ProtocolOperation::from_operation((|| {
            let profile = self
                .inner
                .as_ref()
                .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
            piv::read_metadata_directory(
                profile,
                piv::Access::Existing,
                OperationOptions::default(),
            )
            .map(Inner::Directory)
        })())
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn piv_generate_key(
        &self,
        slot: u8,
        algorithm: u8,
        pin_policy: u8,
        touch_policy: u8,
    ) -> ProtocolOperation {
        ProtocolOperation::from_operation((|| {
            let profile = self
                .inner
                .as_ref()
                .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
            let parameters = piv::KeyParameters {
                slot: piv_slot(slot)?,
                algorithm: profile
                    .algorithm_from_wire_id(algorithm)
                    .ok_or_else(|| Error::new(ErrorKind::UnsupportedAlgorithm))?,
                pin_policy: match pin_policy {
                    0 => piv::PinPolicy::Default,
                    1 => piv::PinPolicy::Never,
                    2 => piv::PinPolicy::Once,
                    3 => piv::PinPolicy::Always,
                    _ => return Err(Error::new(ErrorKind::InvalidArgument)),
                },
                touch_policy: match touch_policy {
                    0 => piv::TouchPolicy::Default,
                    1 => piv::TouchPolicy::Never,
                    2 => piv::TouchPolicy::Always,
                    3 => piv::TouchPolicy::Cached,
                    _ => return Err(Error::new(ErrorKind::InvalidArgument)),
                },
            };
            piv::generate_key(
                profile,
                parameters,
                piv::Access::Existing,
                OperationOptions::default(),
            )
            .map(Inner::PublicKey)
        })())
    }

    /// Reuse the caller's selected transaction; the profile is evidence only.
    #[flutter_rust_bridge::frb(sync)]
    pub fn piv_certificate(&self, object_id: u8) -> ProtocolOperation {
        ProtocolOperation::from_operation((|| {
            let profile = self
                .inner
                .as_ref()
                .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
            let slot = match object_id {
                0x05 => piv::Slot::Authentication,
                0x0a => piv::Slot::Signature,
                0x0b => piv::Slot::KeyManagement,
                0x01 => piv::Slot::CardAuthentication,
                0x0d..=0x20 => piv::Slot::Retired(piv::RetiredSlot::new(object_id - 0x0c)?),
                _ => return Err(Error::new(ErrorKind::InvalidArgument)),
            };
            piv::read_certificate(
                profile,
                slot,
                piv::Access::Existing,
                OperationOptions::default(),
            )
            .map(Inner::Certificate)
        })())
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn piv_delete_certificate(&self, object_id: u8) -> ProtocolOperation {
        ProtocolOperation::from_operation((|| {
            let profile = self
                .inner
                .as_ref()
                .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
            piv::delete_certificate(
                profile,
                piv_slot(object_id)?,
                piv::Access::Existing,
                OperationOptions::default(),
            )
            .map(Inner::Credential)
        })())
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn piv_delete_key(&self, slot: u8) -> ProtocolOperation {
        ProtocolOperation::from_operation((|| {
            let profile = self
                .inner
                .as_ref()
                .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
            piv::delete_key(
                profile,
                piv_slot(slot)?,
                piv::Access::Existing,
                OperationOptions::default(),
            )
            .map(Inner::Credential)
        })())
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn piv_move_key(&self, source: u8, target: u8) -> ProtocolOperation {
        ProtocolOperation::from_operation((|| {
            let profile = self
                .inner
                .as_ref()
                .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
            piv::move_key(
                profile,
                piv_slot(source)?,
                piv_slot(target)?,
                piv::Access::Existing,
                OperationOptions::default(),
            )
            .map(Inner::Credential)
        })())
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn piv_set_management_key(
        &self,
        algorithm: u8,
        key: Vec<u8>,
        touch: u8,
        update_protected: bool,
    ) -> ProtocolOperation {
        let key = SecretBytes::new(key);
        ProtocolOperation::from_operation((|| {
            let profile = self
                .inner
                .as_ref()
                .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
            let alg = match algorithm {
                0x03 => piv::ManagementKeyAlgorithm::Tdes,
                0x0a => piv::ManagementKeyAlgorithm::Aes192,
                _ => return Err(Error::new(ErrorKind::UnsupportedAlgorithm)),
            };
            let key = piv::ManagementKey::from_bytes(alg, key.as_bytes())?;
            let touch = match touch {
                0 => piv::ManagementTouchPolicy::Never,
                1 => piv::ManagementTouchPolicy::Always,
                _ => return Err(Error::new(ErrorKind::InvalidArgument)),
            };
            piv::set_management_key(
                profile,
                key,
                touch,
                update_protected,
                piv::Access::Existing,
                OperationOptions::default(),
            )
            .map(Inner::Credential)
        })())
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn piv_set_algorithm_config(&self, raw: Vec<u8>) -> ProtocolOperation {
        ProtocolOperation::from_operation((|| {
            let profile = self
                .inner
                .as_ref()
                .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
            let config = canokey::compatibility::AlgorithmConfig::parse(&raw)?;
            piv::set_algorithm_config(
                profile,
                config,
                piv::Access::Existing,
                OperationOptions::default(),
            )
            .map(Inner::Credential)
        })())
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn piv_set_container_name(&self, slot: u8, name: String) -> ProtocolOperation {
        ProtocolOperation::from_operation((|| {
            let profile = self
                .inner
                .as_ref()
                .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
            let name = piv::ContainerName::from_text(&name)?;
            piv::set_container_name(
                profile,
                piv_slot(slot)?,
                name,
                piv::Access::Existing,
                OperationOptions::default(),
            )
            .map(Inner::Credential)
        })())
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn piv_reset_pin_puk_retries(&self, pin_retries: u8, puk_retries: u8) -> ProtocolOperation {
        ProtocolOperation::from_operation((|| {
            let profile = self
                .inner
                .as_ref()
                .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
            piv::reset_pin_puk_retries(
                profile,
                pin_retries,
                puk_retries,
                piv::Access::Existing,
                OperationOptions::default(),
            )
            .map(Inner::Credential)
        })())
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn piv_sign(
        &self,
        slot: u8,
        algorithm: u8,
        input: Vec<u8>,
        input_kind: u8,
    ) -> ProtocolOperation {
        let input = SecretBytes::new(input);
        ProtocolOperation::from_operation((|| {
            let profile = self
                .inner
                .as_ref()
                .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
            let algorithm = profile
                .algorithm_from_wire_id(algorithm)
                .ok_or_else(|| Error::new(ErrorKind::UnsupportedAlgorithm))?;
            let input = match input_kind {
                0 => piv::SignInput::RsaEncodedBlock(input),
                1 => piv::SignInput::Digest(input),
                2 => piv::SignInput::Message(input),
                _ => return Err(Error::new(ErrorKind::InvalidArgument)),
            };
            piv::sign(
                profile,
                piv_slot(slot)?,
                algorithm,
                input,
                piv::Access::Existing,
                OperationOptions::default(),
            )
            .map(Inner::Signature)
        })())
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn piv_decrypt(&self, slot: u8, algorithm: u8, ciphertext: Vec<u8>) -> ProtocolOperation {
        let ciphertext = SecretBytes::new(ciphertext);
        ProtocolOperation::from_operation((|| {
            let profile = self
                .inner
                .as_ref()
                .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
            let algorithm = profile
                .algorithm_from_wire_id(algorithm)
                .ok_or_else(|| Error::new(ErrorKind::UnsupportedAlgorithm))?;
            piv::decrypt(
                profile,
                piv_slot(slot)?,
                algorithm,
                ciphertext,
                piv::Access::Existing,
                OperationOptions::default(),
            )
            .map(Inner::Bytes)
        })())
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn piv_derive(&self, slot: u8, algorithm: u8, peer: Vec<u8>) -> ProtocolOperation {
        ProtocolOperation::from_operation((|| {
            let profile = self
                .inner
                .as_ref()
                .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
            let algorithm = profile
                .algorithm_from_wire_id(algorithm)
                .ok_or_else(|| Error::new(ErrorKind::UnsupportedAlgorithm))?;
            piv::derive(
                profile,
                piv_slot(slot)?,
                algorithm,
                peer,
                piv::Access::Existing,
                OperationOptions::default(),
            )
            .map(Inner::Bytes)
        })())
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn piv_decapsulate(&self, slot: u8, ciphertext: Vec<u8>) -> ProtocolOperation {
        let ciphertext = SecretBytes::new(ciphertext);
        ProtocolOperation::from_operation((|| {
            let profile = self
                .inner
                .as_ref()
                .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
            piv::decapsulate(
                profile,
                piv_slot(slot)?,
                ciphertext,
                piv::Access::Existing,
                OperationOptions::default(),
            )
            .map(Inner::Bytes)
        })())
    }

    #[allow(clippy::too_many_arguments)]
    #[flutter_rust_bridge::frb(sync)]
    pub fn piv_sm2_agreement(
        &self,
        slot: u8,
        role: u8,
        peer_static: Vec<u8>,
        peer_ephemeral: Vec<u8>,
        user_id: Option<Vec<u8>>,
        peer_id: Option<Vec<u8>>,
        key_len: u16,
    ) -> ProtocolOperation {
        ProtocolOperation::from_operation((|| {
            let profile = self
                .inner
                .as_ref()
                .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
            let role = match role {
                0 => piv::Sm2Role::Initiator,
                1 => piv::Sm2Role::Responder,
                _ => return Err(Error::new(ErrorKind::InvalidArgument)),
            };
            let input = piv::Sm2AgreementInput {
                role,
                peer_static,
                peer_ephemeral,
                user_id,
                peer_id,
                key_len,
            };
            piv::agree_sm2(
                profile,
                piv_slot(slot)?,
                input,
                piv::Access::Existing,
                OperationOptions::default(),
            )
            .map(Inner::Sm2Agreement)
        })())
    }

    /// INS F9 attestation certificate for a generated slot. The selected-context
    /// factory asserts no credential and consumes no authentication state.
    #[flutter_rust_bridge::frb(sync)]
    pub fn piv_attest(&self, slot: u8) -> ProtocolOperation {
        ProtocolOperation::from_operation((|| {
            let profile = self
                .inner
                .as_ref()
                .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
            piv::attest(profile, piv_slot(slot)?, false, OperationOptions::default())
                .map(Inner::Bytes)
        })())
    }

    /// Firmware streaming signature modes: 0 = ML-DSA-65 with the empty context,
    /// 1 = randomized Ed25519 (wire mode FF), 2 = SM2 full message with an
    /// optional user ID. Classic digest/padded signing stays with `piv_sign`.
    #[flutter_rust_bridge::frb(sync)]
    pub fn piv_sign_streaming(
        &self,
        slot: u8,
        mode: u8,
        message: Vec<u8>,
        user_id: Option<Vec<u8>>,
    ) -> ProtocolOperation {
        let message = SecretBytes::new(message);
        ProtocolOperation::from_operation((|| {
            let profile = self
                .inner
                .as_ref()
                .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
            let input = match mode {
                0 => piv::StreamingSignInput::MlDsa65(message),
                1 => piv::StreamingSignInput::Ed25519Randomized(message),
                2 => piv::StreamingSignInput::Sm2 { message, user_id },
                _ => return Err(Error::new(ErrorKind::InvalidArgument)),
            };
            piv::sign_streaming(
                profile,
                piv_slot(slot)?,
                input,
                piv::Access::Existing,
                OperationOptions::default(),
            )
            .map(Inner::Signature)
        })())
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn piv_import_ec_key(
        &self,
        slot: u8,
        algorithm: u8,
        scalar: Vec<u8>,
        pin_policy: u8,
        touch_policy: u8,
    ) -> ProtocolOperation {
        let scalar = SecretBytes::new(scalar);
        ProtocolOperation::from_operation((|| {
            let profile = self
                .inner
                .as_ref()
                .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
            let algorithm = profile
                .algorithm_from_wire_id(algorithm)
                .ok_or_else(|| Error::new(ErrorKind::UnsupportedAlgorithm))?;
            let parameters = piv::KeyParameters {
                slot: piv_slot(slot)?,
                algorithm,
                pin_policy: match pin_policy {
                    0 => piv::PinPolicy::Default,
                    1 => piv::PinPolicy::Never,
                    2 => piv::PinPolicy::Once,
                    3 => piv::PinPolicy::Always,
                    _ => return Err(Error::new(ErrorKind::InvalidArgument)),
                },
                touch_policy: match touch_policy {
                    0 => piv::TouchPolicy::Default,
                    1 => piv::TouchPolicy::Never,
                    2 => piv::TouchPolicy::Always,
                    3 => piv::TouchPolicy::Cached,
                    _ => return Err(Error::new(ErrorKind::InvalidArgument)),
                },
            };
            let material = piv::PrivateKeyMaterial::ec_scalar(algorithm, scalar.as_bytes())?;
            piv::import_key(
                profile,
                parameters,
                material,
                piv::Access::Existing,
                OperationOptions::default(),
            )
            .map(Inner::Credential)
        })())
    }

    #[allow(clippy::too_many_arguments)]
    #[flutter_rust_bridge::frb(sync)]
    pub fn piv_import_rsa_key(
        &self,
        slot: u8,
        algorithm: u8,
        p: Vec<u8>,
        q: Vec<u8>,
        dp: Vec<u8>,
        dq: Vec<u8>,
        qinv: Vec<u8>,
        pin_policy: u8,
        touch_policy: u8,
    ) -> ProtocolOperation {
        ProtocolOperation::from_operation((|| {
            let profile = self
                .inner
                .as_ref()
                .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
            let algorithm = profile
                .algorithm_from_wire_id(algorithm)
                .ok_or_else(|| Error::new(ErrorKind::UnsupportedAlgorithm))?;
            let parameters = piv::KeyParameters {
                slot: piv_slot(slot)?,
                algorithm,
                pin_policy: match pin_policy {
                    0 => piv::PinPolicy::Default,
                    1 => piv::PinPolicy::Never,
                    2 => piv::PinPolicy::Once,
                    3 => piv::PinPolicy::Always,
                    _ => return Err(Error::new(ErrorKind::InvalidArgument)),
                },
                touch_policy: match touch_policy {
                    0 => piv::TouchPolicy::Default,
                    1 => piv::TouchPolicy::Never,
                    2 => piv::TouchPolicy::Always,
                    3 => piv::TouchPolicy::Cached,
                    _ => return Err(Error::new(ErrorKind::InvalidArgument)),
                },
            };
            let material = piv::PrivateKeyMaterial::rsa_crt(algorithm, [&p, &q, &dp, &dq, &qinv])?;
            piv::import_key(
                profile,
                parameters,
                material,
                piv::Access::Existing,
                OperationOptions::default(),
            )
            .map(Inner::Credential)
        })())
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn piv_import_ed25519_key(
        &self,
        slot: u8,
        seed: Vec<u8>,
        pin_policy: u8,
        touch_policy: u8,
    ) -> ProtocolOperation {
        let seed = SecretBytes::new(seed);
        ProtocolOperation::from_operation((|| {
            let profile = self
                .inner
                .as_ref()
                .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
            let algorithm = piv::Algorithm::Ed25519;
            let parameters = piv::KeyParameters {
                slot: piv_slot(slot)?,
                algorithm,
                pin_policy: match pin_policy {
                    0 => piv::PinPolicy::Default,
                    1 => piv::PinPolicy::Never,
                    2 => piv::PinPolicy::Once,
                    3 => piv::PinPolicy::Always,
                    _ => return Err(Error::new(ErrorKind::InvalidArgument)),
                },
                touch_policy: match touch_policy {
                    0 => piv::TouchPolicy::Default,
                    1 => piv::TouchPolicy::Never,
                    2 => piv::TouchPolicy::Always,
                    3 => piv::TouchPolicy::Cached,
                    _ => return Err(Error::new(ErrorKind::InvalidArgument)),
                },
            };
            let material = piv::PrivateKeyMaterial::ed25519_seed(seed.as_bytes())?;
            piv::import_key(
                profile,
                parameters,
                material,
                piv::Access::Existing,
                OperationOptions::default(),
            )
            .map(Inner::Credential)
        })())
    }

    /// Import a post-quantum seed (INS FE): kind 0 = ML-DSA-65 (32-byte seed),
    /// 1 = ML-KEM-768 (64-byte d||z seed). Semantics match the EC/RSA/Ed25519
    /// imports: Access::Existing inside the caller's reserved transaction.
    #[flutter_rust_bridge::frb(sync)]
    pub fn piv_import_pq_seed(
        &self,
        slot: u8,
        kind: u8,
        seed: Vec<u8>,
        pin_policy: u8,
        touch_policy: u8,
    ) -> ProtocolOperation {
        let seed = SecretBytes::new(seed);
        ProtocolOperation::from_operation((|| {
            let profile = self
                .inner
                .as_ref()
                .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
            let material = match kind {
                0 => piv::PrivateKeyMaterial::mldsa65_seed(seed.as_bytes())?,
                1 => piv::PrivateKeyMaterial::mlkem768_seed(seed.as_bytes())?,
                _ => return Err(Error::new(ErrorKind::InvalidArgument)),
            };
            let parameters = piv::KeyParameters {
                slot: piv_slot(slot)?,
                algorithm: material.algorithm(),
                pin_policy: match pin_policy {
                    0 => piv::PinPolicy::Default,
                    1 => piv::PinPolicy::Never,
                    2 => piv::PinPolicy::Once,
                    3 => piv::PinPolicy::Always,
                    _ => return Err(Error::new(ErrorKind::InvalidArgument)),
                },
                touch_policy: match touch_policy {
                    0 => piv::TouchPolicy::Default,
                    1 => piv::TouchPolicy::Never,
                    2 => piv::TouchPolicy::Always,
                    3 => piv::TouchPolicy::Cached,
                    _ => return Err(Error::new(ErrorKind::InvalidArgument)),
                },
            };
            piv::import_key(
                profile,
                parameters,
                material,
                piv::Access::Existing,
                OperationOptions::default(),
            )
            .map(Inner::Credential)
        })())
    }

    /// Mark an existing HOTP credential as the touch keyboard-emulation
    /// default: slot 0 = short, 1 = long. The legacy (pre-3.0) single-slot
    /// dialect is chosen from the probed profile; a long slot or append-enter
    /// there fails construction with InvalidArgument before any I/O.
    #[flutter_rust_bridge::frb(sync)]
    pub fn oath_set_default(
        &self,
        slot: u8,
        append_enter: bool,
        name: String,
        access_key: Option<Vec<u8>>,
        access_challenge: Option<Vec<u8>>,
    ) -> ProtocolOperation {
        ProtocolOperation::from_operation((|| {
            let profile = self
                .inner
                .as_ref()
                .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
            let slot = match slot {
                0 => oath::DefaultSlot::Short,
                1 => oath::DefaultSlot::Long,
                _ => return Err(Error::new(ErrorKind::InvalidArgument)),
            };
            let request = oath::Request::SetDefault {
                slot,
                append_enter,
                name: oath::Name::from_bytes(name.as_bytes())?,
            };
            oath::operation(
                profile,
                request,
                oath_access(access_key, access_challenge)?,
                OperationOptions::default(),
            )
            .map(Inner::Oath)
        })())
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn oath_delete(
        &self,
        name: Vec<u8>,
        access_key: Option<Vec<u8>>,
        access_challenge: Option<Vec<u8>>,
    ) -> ProtocolOperation {
        ProtocolOperation::from_operation((|| {
            let profile = self
                .inner
                .as_ref()
                .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
            let request = oath::Request::Delete(oath::Name::from_bytes(&name)?);
            oath::operation(
                profile,
                request,
                oath_access(access_key, access_challenge)?,
                OperationOptions::default(),
            )
            .map(Inner::Oath)
        })())
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn oath_rename(
        &self,
        old: Vec<u8>,
        new: Vec<u8>,
        access_key: Option<Vec<u8>>,
        access_challenge: Option<Vec<u8>>,
    ) -> ProtocolOperation {
        ProtocolOperation::from_operation((|| {
            let profile = self
                .inner
                .as_ref()
                .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
            let request = oath::Request::Rename {
                old: oath::Name::from_bytes(&old)?,
                new: oath::Name::from_bytes(&new)?,
            };
            oath::operation(
                profile,
                request,
                oath_access(access_key, access_challenge)?,
                OperationOptions::default(),
            )
            .map(Inner::Oath)
        })())
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn oath_list(
        &self,
        access_key: Option<Vec<u8>>,
        access_challenge: Option<Vec<u8>>,
    ) -> ProtocolOperation {
        ProtocolOperation::from_operation((|| {
            let profile = self
                .inner
                .as_ref()
                .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
            oath::operation(
                profile,
                oath::Request::List,
                oath_access(access_key, access_challenge)?,
                OperationOptions::default(),
            )
            .map(Inner::Oath)
        })())
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn oath_select(&self) -> ProtocolOperation {
        ProtocolOperation::from_operation((|| {
            let profile = self
                .inner
                .as_ref()
                .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
            oath::operation(
                profile,
                oath::Request::Select,
                None,
                OperationOptions::default(),
            )
            .map(Inner::Oath)
        })())
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn oath_validate(&self, key: Vec<u8>, challenge: Vec<u8>) -> ProtocolOperation {
        ProtocolOperation::from_operation((|| {
            let profile = self
                .inner
                .as_ref()
                .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
            let key = oath::AccessKey::from_bytes(&key)?;
            let challenge: [u8; 8] = challenge
                .try_into()
                .map_err(|_| Error::new(ErrorKind::InvalidArgument))?;
            oath::operation(
                profile,
                oath::Request::Validate,
                Some(oath::Access { key, challenge }),
                OperationOptions::default(),
            )
            .map(Inner::Oath)
        })())
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn openpgp_logout(&self, reference: u8) -> ProtocolOperation {
        ProtocolOperation::from_operation((|| {
            let profile = self
                .inner
                .as_ref()
                .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
            let reference = match reference {
                0 => openpgp::PasswordReference::Pw1Sign,
                1 => openpgp::PasswordReference::Pw1Other,
                2 => openpgp::PasswordReference::Pw3,
                _ => return Err(Error::new(ErrorKind::InvalidArgument)),
            };
            openpgp::operation(
                profile,
                openpgp::Request::Logout(reference),
                None,
                OperationOptions::default(),
            )
            .map(Inner::OpenPgp)
        })())
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn openpgp_read_data(&self, tag: u16) -> ProtocolOperation {
        ProtocolOperation::from_operation((|| {
            let profile = self
                .inner
                .as_ref()
                .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
            openpgp::operation(
                profile,
                openpgp::Request::ReadData(tag),
                None,
                OperationOptions::default(),
            )
            .map(Inner::OpenPgp)
        })())
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn openpgp_verify(&self, reference: u8, password: Vec<u8>) -> ProtocolOperation {
        let password = SecretBytes::new(password);
        ProtocolOperation::from_operation((|| {
            let profile = self
                .inner
                .as_ref()
                .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
            let reference = match reference {
                0 => openpgp::PasswordReference::Pw1Sign,
                1 => openpgp::PasswordReference::Pw1Other,
                2 => openpgp::PasswordReference::Pw3,
                _ => return Err(Error::new(ErrorKind::InvalidArgument)),
            };
            let password = openpgp::Password::from_bytes(password.as_bytes())?;
            openpgp::operation(
                profile,
                openpgp::Request::Verify,
                Some(openpgp::Access {
                    reference,
                    password,
                }),
                OperationOptions::default(),
            )
            .map(Inner::OpenPgp)
        })())
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn openpgp_read_certificate(&self, slot: u8) -> ProtocolOperation {
        ProtocolOperation::from_operation((|| {
            let profile = self
                .inner
                .as_ref()
                .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
            let slot = match slot {
                0 => openpgp::Slot::Signature,
                1 => openpgp::Slot::Decryption,
                2 => openpgp::Slot::Authentication,
                _ => return Err(Error::new(ErrorKind::InvalidArgument)),
            };
            openpgp::operation(
                profile,
                openpgp::Request::ReadCertificate(slot),
                None,
                OperationOptions::default(),
            )
            .map(Inner::OpenPgp)
        })())
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn openpgp_write_certificate(
        &self,
        slot: u8,
        certificate: Vec<u8>,
        password: Vec<u8>,
    ) -> ProtocolOperation {
        let certificate = SecretBytes::new(certificate);
        let password = SecretBytes::new(password);
        ProtocolOperation::from_operation((|| {
            let profile = self
                .inner
                .as_ref()
                .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
            let slot = match slot {
                0 => openpgp::Slot::Signature,
                1 => openpgp::Slot::Decryption,
                2 => openpgp::Slot::Authentication,
                _ => return Err(Error::new(ErrorKind::InvalidArgument)),
            };
            let password = openpgp::Password::from_bytes(password.as_bytes())?;
            openpgp::operation(
                profile,
                openpgp::Request::WriteCertificate(slot, certificate),
                Some(openpgp::Access {
                    reference: openpgp::PasswordReference::Pw3,
                    password,
                }),
                OperationOptions::default(),
            )
            .map(Inner::OpenPgp)
        })())
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn openpgp_change_password(
        &self,
        reference: u8,
        old: Vec<u8>,
        new: Vec<u8>,
    ) -> ProtocolOperation {
        let old = SecretBytes::new(old);
        let new = SecretBytes::new(new);
        ProtocolOperation::from_operation((|| {
            let profile = self
                .inner
                .as_ref()
                .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
            let reference = match reference {
                0 => openpgp::PasswordReference::Pw1Sign,
                2 => openpgp::PasswordReference::Pw3,
                _ => return Err(Error::new(ErrorKind::InvalidArgument)),
            };
            let request = openpgp::Request::ChangePassword {
                reference,
                old: openpgp::Password::from_bytes(old.as_bytes())?,
                new: openpgp::Password::from_bytes(new.as_bytes())?,
            };
            openpgp::operation(profile, request, None, OperationOptions::default())
                .map(Inner::OpenPgp)
        })())
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn openpgp_pin_status(&self, reference: u8) -> ProtocolOperation {
        ProtocolOperation::from_operation((|| {
            let profile = self
                .inner
                .as_ref()
                .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
            let reference = match reference {
                0 => openpgp::PasswordReference::Pw1Sign,
                1 => openpgp::PasswordReference::Pw1Other,
                2 => openpgp::PasswordReference::Pw3,
                _ => return Err(Error::new(ErrorKind::InvalidArgument)),
            };
            openpgp::operation(
                profile,
                openpgp::Request::PinStatus(reference),
                None,
                OperationOptions::default(),
            )
            .map(Inner::OpenPgp)
        })())
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn openpgp_write_name(&self, name: Vec<u8>, password: Vec<u8>) -> ProtocolOperation {
        let password = SecretBytes::new(password);
        ProtocolOperation::from_operation((|| {
            let profile = self
                .inner
                .as_ref()
                .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
            let password = openpgp::Password::from_bytes(password.as_bytes())?;
            openpgp::operation(
                profile,
                openpgp::Request::WriteData(openpgp::DataWrite::Name(name)),
                Some(openpgp::Access {
                    reference: openpgp::PasswordReference::Pw3,
                    password,
                }),
                OperationOptions::default(),
            )
            .map(Inner::OpenPgp)
        })())
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn openpgp_write_login(&self, login: Vec<u8>, password: Vec<u8>) -> ProtocolOperation {
        let login = SecretBytes::new(login);
        let password = SecretBytes::new(password);
        ProtocolOperation::from_operation((|| {
            let profile = self
                .inner
                .as_ref()
                .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
            let password = openpgp::Password::from_bytes(password.as_bytes())?;
            openpgp::operation(
                profile,
                openpgp::Request::WriteData(openpgp::DataWrite::Login(login)),
                Some(openpgp::Access {
                    reference: openpgp::PasswordReference::Pw3,
                    password,
                }),
                OperationOptions::default(),
            )
            .map(Inner::OpenPgp)
        })())
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn openpgp_write_language(
        &self,
        language: Vec<u8>,
        password: Vec<u8>,
    ) -> ProtocolOperation {
        let password = SecretBytes::new(password);
        ProtocolOperation::from_operation((|| {
            let profile = self
                .inner
                .as_ref()
                .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
            let password = openpgp::Password::from_bytes(password.as_bytes())?;
            openpgp::operation(
                profile,
                openpgp::Request::WriteData(openpgp::DataWrite::Language(language)),
                Some(openpgp::Access {
                    reference: openpgp::PasswordReference::Pw3,
                    password,
                }),
                OperationOptions::default(),
            )
            .map(Inner::OpenPgp)
        })())
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn openpgp_write_sex(&self, sex: u8, password: Vec<u8>) -> ProtocolOperation {
        let password = SecretBytes::new(password);
        ProtocolOperation::from_operation((|| {
            let profile = self
                .inner
                .as_ref()
                .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
            let password = openpgp::Password::from_bytes(password.as_bytes())?;
            openpgp::operation(
                profile,
                openpgp::Request::WriteData(openpgp::DataWrite::Sex(sex)),
                Some(openpgp::Access {
                    reference: openpgp::PasswordReference::Pw3,
                    password,
                }),
                OperationOptions::default(),
            )
            .map(Inner::OpenPgp)
        })())
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn openpgp_write_url(&self, url: Vec<u8>, password: Vec<u8>) -> ProtocolOperation {
        let password = SecretBytes::new(password);
        ProtocolOperation::from_operation((|| {
            let profile = self
                .inner
                .as_ref()
                .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
            let password = openpgp::Password::from_bytes(password.as_bytes())?;
            openpgp::operation(
                profile,
                openpgp::Request::WriteData(openpgp::DataWrite::Url(url)),
                Some(openpgp::Access {
                    reference: openpgp::PasswordReference::Pw3,
                    password,
                }),
                OperationOptions::default(),
            )
            .map(Inner::OpenPgp)
        })())
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn openpgp_generate_key(&self, slot: u8, password: Vec<u8>) -> ProtocolOperation {
        let password = SecretBytes::new(password);
        ProtocolOperation::from_operation((|| {
            let profile = self
                .inner
                .as_ref()
                .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
            let slot = match slot {
                0 => openpgp::Slot::Signature,
                1 => openpgp::Slot::Decryption,
                2 => openpgp::Slot::Authentication,
                _ => return Err(Error::new(ErrorKind::InvalidArgument)),
            };
            let password = openpgp::Password::from_bytes(password.as_bytes())?;
            openpgp::operation(
                profile,
                openpgp::Request::GenerateKey(slot),
                Some(openpgp::Access {
                    reference: openpgp::PasswordReference::Pw3,
                    password,
                }),
                OperationOptions::default(),
            )
            .map(Inner::OpenPgp)
        })())
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn openpgp_terminate(&self, password: Vec<u8>) -> ProtocolOperation {
        let password = SecretBytes::new(password);
        ProtocolOperation::from_operation((|| {
            let profile = self
                .inner
                .as_ref()
                .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
            let password = openpgp::Password::from_bytes(password.as_bytes())?;
            openpgp::operation(
                profile,
                openpgp::Request::Terminate,
                Some(openpgp::Access {
                    reference: openpgp::PasswordReference::Pw3,
                    password,
                }),
                OperationOptions::default(),
            )
            .map(Inner::OpenPgp)
        })())
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn openpgp_activate(&self, password: Vec<u8>) -> ProtocolOperation {
        let password = SecretBytes::new(password);
        ProtocolOperation::from_operation((|| {
            let profile = self
                .inner
                .as_ref()
                .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
            let password = openpgp::Password::from_bytes(password.as_bytes())?;
            openpgp::operation(
                profile,
                openpgp::Request::Activate,
                Some(openpgp::Access {
                    reference: openpgp::PasswordReference::Pw3,
                    password,
                }),
                OperationOptions::default(),
            )
            .map(Inner::OpenPgp)
        })())
    }

    /// Set (Some) or clear (None) the reset code after explicit PW3 verification.
    #[flutter_rust_bridge::frb(sync)]
    pub fn openpgp_write_reset_code(
        &self,
        reset_code: Option<Vec<u8>>,
        password: Vec<u8>,
    ) -> ProtocolOperation {
        let reset_code = reset_code.map(SecretBytes::new);
        let password = SecretBytes::new(password);
        ProtocolOperation::from_operation((|| {
            let profile = self
                .inner
                .as_ref()
                .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
            let reset_code = reset_code
                .map(|code| openpgp::Password::from_bytes(code.as_bytes()))
                .transpose()?;
            let password = openpgp::Password::from_bytes(password.as_bytes())?;
            openpgp::operation(
                profile,
                openpgp::Request::WriteData(openpgp::DataWrite::ResetCode(reset_code)),
                Some(openpgp::Access {
                    reference: openpgp::PasswordReference::Pw3,
                    password,
                }),
                OperationOptions::default(),
            )
            .map(Inner::OpenPgp)
        })())
    }

    /// Set PW1/reset-code/PW3 retry limits after explicit PW3 verification.
    /// The card resets PW1/PW3 to firmware defaults and clears authorization;
    /// the retry-reset capability gates construction before any I/O.
    #[flutter_rust_bridge::frb(sync)]
    pub fn openpgp_reset_retries(&self, retries: Vec<u8>, password: Vec<u8>) -> ProtocolOperation {
        let password = SecretBytes::new(password);
        ProtocolOperation::from_operation((|| {
            let profile = self
                .inner
                .as_ref()
                .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
            let retries: [u8; 3] = retries
                .try_into()
                .map_err(|_| Error::new(ErrorKind::InvalidArgument))?;
            let password = openpgp::Password::from_bytes(password.as_bytes())?;
            openpgp::operation(
                profile,
                openpgp::Request::ResetRetries(retries),
                Some(openpgp::Access {
                    reference: openpgp::PasswordReference::Pw3,
                    password,
                }),
                OperationOptions::default(),
            )
            .map(Inner::OpenPgp)
        })())
    }

    /// Whether one explicit PW1-sign verification may authorize multiple
    /// signatures (PW status bytes policy). Written after PW3 verification.
    #[flutter_rust_bridge::frb(sync)]
    pub fn openpgp_write_signature_pin_policy(
        &self,
        reuse: bool,
        password: Vec<u8>,
    ) -> ProtocolOperation {
        let password = SecretBytes::new(password);
        ProtocolOperation::from_operation((|| {
            let profile = self
                .inner
                .as_ref()
                .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
            let password = openpgp::Password::from_bytes(password.as_bytes())?;
            openpgp::operation(
                profile,
                openpgp::Request::WriteData(openpgp::DataWrite::ReuseSignaturePin(reuse)),
                Some(openpgp::Access {
                    reference: openpgp::PasswordReference::Pw3,
                    password,
                }),
                OperationOptions::default(),
            )
            .map(Inner::OpenPgp)
        })())
    }

    /// Reset PW1 after explicit PW3 verification; does not change PW3.
    #[flutter_rust_bridge::frb(sync)]
    pub fn openpgp_unblock_with_admin(
        &self,
        new_pin: Vec<u8>,
        password: Vec<u8>,
    ) -> ProtocolOperation {
        let new_pin = SecretBytes::new(new_pin);
        let password = SecretBytes::new(password);
        ProtocolOperation::from_operation((|| {
            let profile = self
                .inner
                .as_ref()
                .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
            let new_pin = openpgp::Password::from_bytes(new_pin.as_bytes())?;
            let password = openpgp::Password::from_bytes(password.as_bytes())?;
            openpgp::operation(
                profile,
                openpgp::Request::UnblockWithAdmin(new_pin),
                Some(openpgp::Access {
                    reference: openpgp::PasswordReference::Pw3,
                    password,
                }),
                OperationOptions::default(),
            )
            .map(Inner::OpenPgp)
        })())
    }

    /// Reset PW1 using reset-code||new-PW1; no password verification is inserted.
    #[flutter_rust_bridge::frb(sync)]
    pub fn openpgp_unblock_with_code(&self, code: Vec<u8>, new_pin: Vec<u8>) -> ProtocolOperation {
        let code = SecretBytes::new(code);
        let new_pin = SecretBytes::new(new_pin);
        ProtocolOperation::from_operation((|| {
            let profile = self
                .inner
                .as_ref()
                .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
            let code = openpgp::Password::from_bytes(code.as_bytes())?;
            let new_pin = openpgp::Password::from_bytes(new_pin.as_bytes())?;
            openpgp::operation(
                profile,
                openpgp::Request::UnblockWithCode { code, new: new_pin },
                None,
                OperationOptions::default(),
            )
            .map(Inner::OpenPgp)
        })())
    }

    /// Slot touch policy (0 off, 1 on, 2 permanent) after PW3 verification.
    /// Emits the standard two-byte UIF field; the UIF capability gates it.
    #[flutter_rust_bridge::frb(sync)]
    pub fn openpgp_write_touch_policy(
        &self,
        slot: u8,
        policy: u8,
        password: Vec<u8>,
    ) -> ProtocolOperation {
        let password = SecretBytes::new(password);
        ProtocolOperation::from_operation((|| {
            let profile = self
                .inner
                .as_ref()
                .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
            let slot = openpgp_slot(slot)?;
            let policy = match policy {
                0 => openpgp::TouchPolicy::Off,
                1 => openpgp::TouchPolicy::On,
                2 => openpgp::TouchPolicy::Permanent,
                _ => return Err(Error::new(ErrorKind::InvalidArgument)),
            };
            let password = openpgp::Password::from_bytes(password.as_bytes())?;
            openpgp::operation(
                profile,
                openpgp::Request::WriteData(openpgp::DataWrite::TouchPolicy(slot, policy)),
                Some(openpgp::Access {
                    reference: openpgp::PasswordReference::Pw3,
                    password,
                }),
                OperationOptions::default(),
            )
            .map(Inner::OpenPgp)
        })())
    }

    /// Touch cache duration in seconds after PW3 verification; UIF-gated.
    #[flutter_rust_bridge::frb(sync)]
    pub fn openpgp_write_touch_cache_time(
        &self,
        seconds: u8,
        password: Vec<u8>,
    ) -> ProtocolOperation {
        let password = SecretBytes::new(password);
        ProtocolOperation::from_operation((|| {
            let profile = self
                .inner
                .as_ref()
                .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
            let password = openpgp::Password::from_bytes(password.as_bytes())?;
            openpgp::operation(
                profile,
                openpgp::Request::WriteData(openpgp::DataWrite::TouchCacheTime(seconds)),
                Some(openpgp::Access {
                    reference: openpgp::PasswordReference::Pw3,
                    password,
                }),
                OperationOptions::default(),
            )
            .map(Inner::OpenPgp)
        })())
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn oath_clear_code(
        &self,
        key: Option<Vec<u8>>,
        challenge: Option<Vec<u8>>,
    ) -> ProtocolOperation {
        ProtocolOperation::from_operation((|| {
            let profile = self
                .inner
                .as_ref()
                .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
            oath::operation(
                profile,
                oath::Request::ClearCode,
                oath_access(key, challenge)?,
                OperationOptions::default(),
            )
            .map(Inner::Oath)
        })())
    }

    /// The current key validates in the same operation only when supplied;
    /// setting the first code on an unprotected applet passes no old key.
    #[flutter_rust_bridge::frb(sync)]
    pub fn oath_set_code(
        &self,
        old_key: Option<Vec<u8>>,
        new_key: Vec<u8>,
        challenge: Vec<u8>,
    ) -> ProtocolOperation {
        ProtocolOperation::from_operation((|| {
            let profile = self
                .inner
                .as_ref()
                .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
            let new_key = oath::AccessKey::from_bytes(&new_key)?;
            let challenge: [u8; 8] = challenge
                .try_into()
                .map_err(|_| Error::new(ErrorKind::InvalidArgument))?;
            let access = old_key
                .map(|old_key| {
                    let key = oath::AccessKey::from_bytes(&old_key)?;
                    Ok::<_, Error>(oath::Access { key, challenge })
                })
                .transpose()?;
            oath::operation(
                profile,
                oath::Request::SetCode {
                    key: new_key,
                    challenge,
                },
                access,
                OperationOptions::default(),
            )
            .map(Inner::Oath)
        })())
    }

    #[allow(clippy::too_many_arguments)]
    #[flutter_rust_bridge::frb(sync)]
    pub fn oath_put(
        &self,
        name: Vec<u8>,
        kind: u8,
        algorithm: u8,
        digits: u8,
        secret: Vec<u8>,
        require_touch: bool,
        increasing: bool,
        initial_counter: u32,
        access_key: Option<Vec<u8>>,
        access_challenge: Option<Vec<u8>>,
    ) -> ProtocolOperation {
        ProtocolOperation::from_operation((|| {
            let profile = self
                .inner
                .as_ref()
                .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
            let kind = match kind {
                1 => oath::Kind::Hotp,
                2 => oath::Kind::Totp,
                _ => return Err(Error::new(ErrorKind::InvalidArgument)),
            };
            let algorithm = match algorithm {
                1 => oath::Algorithm::Sha1,
                2 => oath::Algorithm::Sha256,
                3 => oath::Algorithm::Sha512,
                _ => return Err(Error::new(ErrorKind::InvalidArgument)),
            };
            let request = oath::Request::Put(oath::Credential {
                name: oath::Name::from_bytes(&name)?,
                kind,
                algorithm,
                digits,
                secret: SecretBytes::new(secret),
                require_touch,
                increasing,
                initial_counter,
            });
            oath::operation(
                profile,
                request,
                oath_access(access_key, access_challenge)?,
                OperationOptions::default(),
            )
            .map(Inner::Oath)
        })())
    }

    #[allow(clippy::too_many_arguments)]
    #[flutter_rust_bridge::frb(sync)]
    pub fn oath_calculate(
        &self,
        name: Vec<u8>,
        kind: u8,
        algorithm: u8,
        challenge: Option<Vec<u8>>,
        format: u8,
        access_key: Option<Vec<u8>>,
        access_challenge: Option<Vec<u8>>,
    ) -> ProtocolOperation {
        ProtocolOperation::from_operation((|| {
            let profile = self
                .inner
                .as_ref()
                .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
            let kind = match kind {
                1 => oath::Kind::Hotp,
                2 => oath::Kind::Totp,
                _ => return Err(Error::new(ErrorKind::InvalidArgument)),
            };
            let algorithm = match algorithm {
                1 => oath::Algorithm::Sha1,
                2 => oath::Algorithm::Sha256,
                3 => oath::Algorithm::Sha512,
                _ => return Err(Error::new(ErrorKind::InvalidArgument)),
            };
            let challenge = challenge
                .map(|v| {
                    v.try_into()
                        .map_err(|_| Error::new(ErrorKind::InvalidArgument))
                })
                .transpose()?;
            let format = match format {
                0 => oath::Format::Truncated,
                1 => oath::Format::Full,
                _ => return Err(Error::new(ErrorKind::InvalidArgument)),
            };
            let request = oath::Request::Calculate {
                name: oath::Name::from_bytes(&name)?,
                kind,
                algorithm,
                challenge,
                format,
            };
            oath::operation(
                profile,
                request,
                oath_access(access_key, access_challenge)?,
                OperationOptions::default(),
            )
            .map(Inner::Oath)
        })())
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn oath_calculate_all(
        &self,
        challenge: Vec<u8>,
        format: u8,
        access_key: Option<Vec<u8>>,
        access_challenge: Option<Vec<u8>>,
    ) -> ProtocolOperation {
        ProtocolOperation::from_operation((|| {
            let profile = self
                .inner
                .as_ref()
                .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
            let challenge: [u8; 8] = challenge
                .try_into()
                .map_err(|_| Error::new(ErrorKind::InvalidArgument))?;
            let format = match format {
                0 => oath::Format::Truncated,
                1 => oath::Format::Full,
                _ => return Err(Error::new(ErrorKind::InvalidArgument)),
            };
            oath::operation(
                profile,
                oath::Request::CalculateAll { challenge, format },
                oath_access(access_key, access_challenge)?,
                OperationOptions::default(),
            )
            .map(Inner::Oath)
        })())
    }

    /// Return the normalized object value. libcanokey owns framing and parsing.
    #[flutter_rust_bridge::frb(sync)]
    pub fn piv_read_object(&self, object_id: Vec<u8>) -> ProtocolOperation {
        ProtocolOperation::from_operation((|| {
            let profile = self
                .inner
                .as_ref()
                .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
            piv::read_object(
                profile,
                piv::ObjectId::from_bytes(&object_id)?,
                piv::Access::Existing,
                OperationOptions::default(),
            )
            .map(Inner::Bytes)
        })())
    }

    /// Writes may be partially applied before failure; never retry or roll back.
    /// Existing delegates authorization to the card in the caller-owned lease.
    #[flutter_rust_bridge::frb(sync)]
    pub fn piv_write_object(&self, object_id: Vec<u8>, data: Vec<u8>) -> ProtocolOperation {
        let data = SecretBytes::new(data);
        ProtocolOperation::from_operation((|| {
            let profile = self
                .inner
                .as_ref()
                .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
            piv::write_object(
                profile,
                piv::ObjectId::from_bytes(&object_id)?,
                data,
                piv::Access::Existing,
                OperationOptions::default(),
            )
            .map(Inner::Credential)
        })())
    }

    /// Resolve an observed key algorithm to Console's fixed display enum IDs.
    /// These are NOT device wire IDs and never authorize a key operation.
    /// Unknown algorithms and closed profiles return None.
    #[flutter_rust_bridge::frb(sync)]
    pub fn piv_algorithm_display_id(&self, wire_id: u8) -> Option<u8> {
        use piv::Algorithm;
        Some(
            match self.inner.as_ref()?.algorithm_from_wire_id(wire_id)? {
                Algorithm::Rsa1024 => 0x06,
                Algorithm::Rsa2048 => 0x07,
                Algorithm::Rsa3072 => 0x05,
                Algorithm::Rsa4096 => 0x16,
                Algorithm::EccP256 => 0x11,
                Algorithm::EccP384 => 0x14,
                Algorithm::EccP521 => 0x15,
                Algorithm::Secp256k1 => 0x53,
                Algorithm::Sm2 => 0x54,
                Algorithm::Ed25519 => 0xe0,
                Algorithm::X25519 => 0xe1,
                Algorithm::MlDsa65 => 0xe2,
                Algorithm::MlKem768 => 0xe3,
            },
        )
    }

    /// Idempotent local cleanup. Does not alter the card or already-created ops.
    #[flutter_rust_bridge::frb(sync)]
    pub fn close(&mut self) {
        self.inner.take();
    }
}

fn openpgp_slot(slot: u8) -> Result<openpgp::Slot, Error> {
    match slot {
        0 => Ok(openpgp::Slot::Signature),
        1 => Ok(openpgp::Slot::Decryption),
        2 => Ok(openpgp::Slot::Authentication),
        _ => Err(Error::new(ErrorKind::InvalidArgument)),
    }
}

fn piv_slot(reference: u8) -> Result<piv::Slot, Error> {
    match reference {
        0x9a => Ok(piv::Slot::Authentication),
        0x9c => Ok(piv::Slot::Signature),
        0x9d => Ok(piv::Slot::KeyManagement),
        0x9e => Ok(piv::Slot::CardAuthentication),
        0x82..=0x95 => piv::RetiredSlot::new(reference - 0x81).map(piv::Slot::Retired),
        _ => Err(Error::new(ErrorKind::InvalidArgument)),
    }
}

// The pinned high-level get_pin_status inserts SELECT. This selected-only
// adapter uses its upstream command and error classifier, preserving live PIN
// verification. It returns only the validated status word, never response data.
/// A single caller-owned operation, retained across Dart await points.
/// Close is idempotent and releases Rust buffers without sending any APDU.
#[flutter_rust_bridge::frb(opaque)]
pub struct ProtocolOperation {
    // FRB opaque handles require Sync, while core operations are only Send.
    // All entry points take &mut self; get_mut never locks or spans Dart I/O.
    inner: Mutex<Option<Inner>>,
    construction_error: Option<Error>,
}

impl ProtocolOperation {
    /// Admin-only discovery before authentication; does not select PIV.
    #[flutter_rust_bridge::frb(sync)]
    pub fn probe_admin() -> Self {
        Self::from_operation(
            canokey::probe_device(canokey::ProbeOptions {
                mode: canokey::ProbeMode::Minimal,
                ..Default::default()
            })
            .map(Inner::Probe),
        )
    }

    /// One raw bootstrap identity step for connection setup. The caller's
    /// exclusive lease spans SELECT and the serial read; a final non-9000
    /// status fails with the raw status word retained. No retry or replay.
    #[flutter_rust_bridge::frb(sync)]
    pub fn bootstrap_identity(step: BootstrapIdentityStep) -> Self {
        let options = OperationOptions::default();
        let operation = match step {
            BootstrapIdentityStep::SelectAdmin => {
                conversation(admin::command::select(), options).map(Inner::BootstrapSelect)
            }
            BootstrapIdentityStep::Serial => {
                conversation(admin::command::serial(), options).map(Inner::BootstrapSerial)
            }
        };
        Self::from_operation(operation)
    }

    /// Retained upstream progress, available even after protocol failure.
    #[flutter_rust_bridge::frb(sync)]
    pub fn admin_progress(&mut self) -> Option<AdminProgress> {
        match self
            .inner
            .get_mut()
            .unwrap_or_else(|e| e.into_inner())
            .as_ref()?
        {
            Inner::Admin(op) => op.progress().map(admin_progress),
            _ => None,
        }
    }

    /// Explicit Admin/PIV discovery. Call before authentication in the same
    /// exclusive lease; the completed profile is transferred to Dart exactly once.
    #[flutter_rust_bridge::frb(sync)]
    pub fn probe_piv() -> Self {
        Self::from_operation(
            canokey::probe_device(canokey::ProbeOptions::default()).map(Inner::Probe),
        )
    }

    /// Construct without I/O. Only Select changes applet selection; reads never
    /// probe, SELECT, authenticate, or retain a device profile implicitly.
    #[flutter_rust_bridge::frb(sync)]
    pub fn piv_read(kind: PivReadOperation) -> Self {
        let options = OperationOptions::default();
        let operation = match kind {
            PivReadOperation::PinStatus => {
                piv::get_pin_status_selected(options).map(Inner::PinStatus)
            }
            PivReadOperation::Select => piv::select_application(options).map(Inner::Bytes),
            PivReadOperation::Version => piv::read_version_selected(options).map(Inner::Bytes),
            PivReadOperation::AlgorithmConfiguration => {
                piv::read_configuration_selected(options).map(Inner::Configuration)
            }
        };
        Self::from_operation(operation)
    }

    /// Profile-free NDEF capability-container read. Selects the NDEF applet.
    /// Data encodes `max_message_length` (big-endian u16, excluding the two
    /// NLEN bytes) followed by the read-only flag byte.
    #[flutter_rust_bridge::frb(sync)]
    pub fn ndef_read_capability() -> Self {
        Self::from_operation(
            ndef::read_capability(OperationOptions::default()).map(Inner::NdefCapability),
        )
    }

    /// Profile-free full NDEF message read; chunked by the upstream machine.
    /// Data is the raw message without the two NLEN bytes.
    #[flutter_rust_bridge::frb(sync)]
    pub fn ndef_read_message() -> Self {
        Self::from_operation(
            ndef::read_message(OperationOptions::default()).map(Inner::NdefMessage),
        )
    }

    /// Crash-safe NDEF message replacement: zero NLEN, message chunks, real
    /// NLEN. A failed mid-write leaves no stale message and is never replayed.
    #[flutter_rust_bridge::frb(sync)]
    pub fn ndef_write_message(message: Vec<u8>) -> Self {
        Self::from_operation(
            ndef::write_message(&message, OperationOptions::default()).map(Inner::Management),
        )
    }

    /// Select the FIDO2 applet only; the caller owns the selected context.
    #[flutter_rust_bridge::frb(sync)]
    pub fn ctap_select_application() -> Self {
        Self::from_operation(
            ctap::select_application(OperationOptions::default()).map(Inner::Management),
        )
    }

    /// One CTAP message to the caller's already selected FIDO2 applet.
    /// Data is the CTAP status byte followed by the payload; a non-success
    /// status is not a protocol error and stays visible to Dart.
    #[flutter_rust_bridge::frb(sync)]
    pub fn ctap_transceive_selected(message: Vec<u8>) -> Self {
        Self::from_operation(
            ctap::transceive_selected(&message, OperationOptions::default()).map(Inner::Ctap),
        )
    }

    /// Select the FIDO2 applet and send one CTAP message within that selection.
    #[flutter_rust_bridge::frb(sync)]
    pub fn ctap_transceive(message: Vec<u8>) -> Self {
        Self::from_operation(
            ctap::transceive(&message, OperationOptions::default()).map(Inner::Ctap),
        )
    }

    fn from_operation(operation: Result<Inner, Error>) -> Self {
        match operation {
            Ok(inner) => Self {
                inner: Mutex::new(Some(inner)),
                construction_error: None,
            },
            Err(error) => Self {
                inner: Mutex::new(None),
                construction_error: Some(error),
            },
        }
    }

    /// Start exactly once; subsequent calls report an operation-state error.
    #[flutter_rust_bridge::frb(sync)]
    pub fn start(&mut self) -> ProtocolStep {
        self.drive(None)
    }

    /// Consume one complete, unprocessed response including SW1/SW2.
    /// The input is copied into zeroizing storage and released before returning.
    #[flutter_rust_bridge::frb(sync)]
    pub fn advance(&mut self, response: Vec<u8>) -> ProtocolStep {
        let response = SecretBytes::new(response);
        self.drive(Some(response.as_bytes()))
    }

    /// Release locally, including on a transport exception. Never retry/rollback.
    #[flutter_rust_bridge::frb(sync)]
    pub fn close(&mut self) {
        self.inner
            .get_mut()
            .unwrap_or_else(|e| e.into_inner())
            .take();
        self.construction_error.take();
    }
}

impl ProtocolOperation {
    fn drive(&mut self, response: Option<&[u8]>) -> ProtocolStep {
        if let Some(error) = self.construction_error.take() {
            return ProtocolStep::failure(error);
        }
        let result = match self
            .inner
            .get_mut()
            .unwrap_or_else(|e| e.into_inner())
            .as_mut()
        {
            Some(Inner::Admin(op)) => drive(op, response, |outcome| ProtocolStep {
                command: None,
                data: None,
                profile: None,
                error: None,
                admin: Some(admin_result(outcome)),
            }),
            Some(Inner::Bytes(op)) => drive(op, response, |data| bytes(data.as_bytes().to_vec())),
            Some(Inner::PinStatus(op)) => drive(op, response, |status| {
                let sw = if status.blocked {
                    0x6983
                } else if let Some(retries) = status.retries_remaining {
                    0x63c0 | u16::from(retries)
                } else {
                    0x9000
                };
                bytes(sw.to_be_bytes().to_vec())
            }),
            Some(Inner::Configuration(op)) => {
                drive(op, response, |data| bytes(data.raw().to_vec()))
            }
            Some(Inner::Certificate(op)) => drive(op, response, |data| bytes(data.der().to_vec())),
            Some(Inner::Credential(op)) => drive(op, response, |_| bytes(Vec::new())),
            Some(Inner::Management(op)) => drive(op, response, |_| bytes(Vec::new())),
            Some(Inner::BootstrapSelect(op)) => drive(op, response, |outcome| {
                match outcome.ensure_success(Phase::Select) {
                    Ok(()) => bytes(Vec::new()),
                    Err(error) => ProtocolStep::failure(error),
                }
            }),
            Some(Inner::BootstrapSerial(op)) => drive(op, response, |outcome| {
                match outcome.ensure_success(Phase::Command) {
                    Ok(()) => bytes(outcome.data.as_bytes().to_vec()),
                    Err(error) => ProtocolStep::failure(error),
                }
            }),
            Some(Inner::Metadata(op)) => drive(op, response, |data| {
                bytes(data.fields().raw.as_bytes().to_vec())
            }),
            Some(Inner::Directory(op)) => drive(op, response, |data| bytes(data.raw().to_vec())),
            Some(Inner::PublicKey(op)) => drive(op, response, |data| match data.to_spki_der() {
                Ok(value) => bytes(value),
                Err(error) => ProtocolStep::failure(error),
            }),
            Some(Inner::Signature(op)) => {
                drive(op, response, |data| bytes(data.as_bytes().to_vec()))
            }
            Some(Inner::Sm2Agreement(op)) => {
                drive(op, response, |data| bytes(data.key.as_bytes().to_vec()))
            }
            Some(Inner::Oath(op)) => drive(op, response, |outcome| match outcome {
                oath::Outcome::Unit => bytes(Vec::new()),
                oath::Outcome::Entries(entries) => {
                    let mut out = Vec::new();
                    for entry in entries {
                        out.push(entry.algorithm_type);
                        out.push(entry.name.as_bytes().len() as u8);
                        out.extend_from_slice(entry.name.as_bytes());
                    }
                    bytes(out)
                }
                oath::Outcome::Selection(selection) => {
                    let mut out = selection.version.to_vec();
                    out.extend_from_slice(&selection.handle);
                    if let Some(challenge) = selection.challenge {
                        out.extend_from_slice(&challenge);
                    }
                    bytes(out)
                }
                oath::Outcome::LegacySelection { serial } => {
                    bytes(serial.map(|s| s.to_vec()).unwrap_or_default())
                }
                oath::Outcome::Calculations(calculations) => {
                    // name_len (0xff = nameless) | name | digits | code tag |
                    // code_len | code bytes. Raw truncated bytes are preserved
                    // so Dart owns display formatting (decimal, Steam, etc.).
                    let mut out = Vec::new();
                    for calculation in calculations {
                        match &calculation.name {
                            Some(name) => {
                                out.push(name.as_bytes().len() as u8);
                                out.extend_from_slice(name.as_bytes());
                            }
                            None => out.push(0xff),
                        }
                        out.push(calculation.digits);
                        match &calculation.code {
                            oath::Code::Truncated(raw) => {
                                out.push(0x76);
                                out.push(raw.as_bytes().len() as u8);
                                out.extend_from_slice(raw.as_bytes());
                            }
                            oath::Code::Full(raw) => {
                                out.push(0x75);
                                out.push(raw.as_bytes().len() as u8);
                                out.extend_from_slice(raw.as_bytes());
                            }
                            oath::Code::Hotp => out.extend_from_slice(&[0x77, 0]),
                            oath::Code::TouchRequired => out.extend_from_slice(&[0x7c, 0]),
                        }
                    }
                    bytes(out)
                }
            }),
            Some(Inner::OpenPgp(op)) => drive(op, response, |outcome| match outcome {
                openpgp::Outcome::Bytes(value) => bytes(value.as_bytes().to_vec()),
                openpgp::Outcome::Unit => bytes(Vec::new()),
                openpgp::Outcome::PinStatus(status) => bytes(vec![
                    u8::from(status.verified),
                    u8::from(status.blocked),
                    status.retries_remaining.unwrap_or(0),
                ]),
                _ => ProtocolStep::failure(Error::new(ErrorKind::InvalidResponse)),
            }),
            Some(Inner::Probe(op)) => drive(op, response, |profile| ProtocolStep {
                command: None,
                data: None,
                error: None,
                admin: None,
                profile: Some(ProtocolProfile {
                    inner: Some(profile),
                }),
            }),
            Some(Inner::NdefCapability(op)) => drive(op, response, |capability| {
                let max = capability.max_message_length.min(usize::from(u16::MAX)) as u16;
                let mut data = max.to_be_bytes().to_vec();
                data.push(u8::from(capability.read_only));
                bytes(data)
            }),
            Some(Inner::NdefMessage(op)) => {
                drive(op, response, |message| bytes(message.as_bytes().to_vec()))
            }
            Some(Inner::Ctap(op)) => drive(op, response, |result| {
                let mut data = Vec::with_capacity(result.payload().len() + 1);
                data.push(result.status().raw());
                data.extend_from_slice(result.payload());
                bytes(data)
            }),
            None => Err(Error::new(ErrorKind::OperationStateError)),
        };
        result.unwrap_or_else(ProtocolStep::failure)
    }
}

/// Both halves of an OATH access proof travel together; a key without a fresh
/// challenge (or vice versa) is rejected before any I/O.
fn oath_access(
    key: Option<Vec<u8>>,
    challenge: Option<Vec<u8>>,
) -> Result<Option<oath::Access>, Error> {
    match (key, challenge) {
        (None, None) => Ok(None),
        (Some(key), Some(challenge)) => Ok(Some(oath::Access {
            key: oath::AccessKey::from_bytes(&key)?,
            challenge: challenge
                .try_into()
                .map_err(|_| Error::new(ErrorKind::InvalidArgument))?,
        })),
        _ => Err(Error::new(ErrorKind::InvalidArgument)),
    }
}

fn drive<T>(
    op: &mut Operation<T>,
    response: Option<&[u8]>,
    encode: impl FnOnce(T) -> ProtocolStep,
) -> Result<ProtocolStep, Error> {
    let step = match response {
        Some(response) => op.advance(response)?,
        None => op.start()?,
    };
    Ok(match step {
        Step::Exchange => ProtocolStep {
            command: Some(op.command()?.as_bytes().to_vec()),
            data: None,
            error: None,
            profile: None,
            admin: None,
        },
        Step::Done => encode(op.take_result()?),
    })
}

fn bytes(data: Vec<u8>) -> ProtocolStep {
    ProtocolStep {
        command: None,
        data: Some(data),
        error: None,
        profile: None,
        admin: None,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn metadata_profile() -> ProtocolProfile {
        let mut observations = canokey::compatibility::DeviceObservations::new(b"3.1.0".to_vec());
        observations.piv_version = Some(canokey::compatibility::PivApplicationVersion([6, 0, 0]));
        ProtocolProfile {
            inner: Some(canokey::DeviceProfile::from_observations(observations).unwrap()),
        }
    }

    #[test]
    fn admin_progress_survives_failure_until_close() {
        let profile = metadata_profile();
        let mut op = profile.admin_configure(
            AdminConfigurationPatch {
                led_on: Some(false),
                ndef_read_only: None,
                ndef_enabled: Some(false),
                webusb_landing: None,
                feature_mask: 0,
                feature_values: 0,
            },
            Some(b"123456".to_vec()),
            false,
        );
        assert_eq!(
            op.start().command.unwrap(),
            [0, 0xa4, 4, 0, 5, 0xf0, 0, 0, 0, 0]
        );
        assert!(!op.admin_progress().unwrap().reprobe_required);
        op.advance(vec![0x90, 0]); // VERIFY
        op.advance(vec![0x90, 0]); // READ CONFIG
        assert_eq!(
            op.advance(vec![1, 0, 0, 1, 1, 63, 0x90, 0])
                .command
                .unwrap(),
            [0, 0x40, 1, 0]
        );
        assert!(op.admin_progress().unwrap().reprobe_required);
        assert_eq!(op.admin_progress().unwrap().confirmed_writes, 0);
        assert_eq!(op.advance(vec![0x90, 0]).command.unwrap(), [0, 0x40, 4, 0]);
        assert_eq!(
            op.advance(vec![0x6f, 0]).error.unwrap().kind,
            "UnexpectedStatusWord"
        );
        assert_eq!(op.admin_progress().unwrap().confirmed_writes, 1);
        assert!(op.admin_progress().unwrap().reprobe_required);
        op.close();
        assert!(op.admin_progress().is_none());
    }

    #[test]
    fn admin_operation_copies_profile_and_does_not_accept_cached_authorization() {
        let mut profile = metadata_profile();
        let mut reset = profile.admin_action(AdminAction::ResetNdef, None, vec![], 0, 0, false);
        assert_eq!(
            reset.start().error.unwrap().kind,
            "SecurityStatusNotSatisfied"
        );
        let mut verify = profile.admin_action(
            AdminAction::VerifyPin,
            Some(b"123456".to_vec()),
            vec![],
            0,
            0,
            false,
        );
        profile.close();
        verify.start();
        assert_eq!(
            verify.advance(vec![0x90, 0]).command.unwrap(),
            b"\x00\x20\x00\x00\x06123456"
        );
        let error = verify.advance(vec![0x63, 0xc2]).error.unwrap();
        assert_eq!(error.reference.as_deref(), Some("AdminPin"));
        assert_eq!(error.retries_remaining, Some(2));
        assert_eq!(verify.admin_progress().unwrap().confirmed_writes, 0);
    }

    #[test]
    fn credentials_own_inputs_and_preserve_failure_reference_without_replay() {
        for (kind, prefix, reference) in [
            (PivCredentialOperation::ChangePin, [0, 0x24, 0, 0x80], "Pin"),
            (PivCredentialOperation::ChangePuk, [0, 0x24, 0, 0x81], "Puk"),
            (
                PivCredentialOperation::UnblockPin,
                [0, 0x2c, 0, 0x80],
                "Puk",
            ),
        ] {
            let mut profile = metadata_profile();
            let mut op = profile.piv_credential(kind, b"12345678".to_vec(), b"654321".to_vec());
            profile.close();
            let command = op.start().command.unwrap();
            assert_eq!(&command[..4], &prefix);
            assert_eq!(&command[5..13], b"12345678");
            assert_eq!(&command[13..], b"654321\xff\xff");
            let error = op.advance(vec![0x63, 0xc2]).error.unwrap();
            assert_eq!(error.kind, "AuthenticationFailed");
            assert_eq!(error.reference.as_deref(), Some(reference));
            assert_eq!(error.retries_remaining, Some(2));
            assert!(op.advance(vec![0x90, 0]).error.is_some());
        }
        for response in [vec![0x6c, 0], vec![1, 0x90, 0]] {
            let mut op = metadata_profile().piv_credential(
                PivCredentialOperation::ChangePin,
                b"123456".to_vec(),
                b"654321".to_vec(),
            );
            op.start();
            let step = op.advance(response);
            assert!(step.command.is_none());
            assert!(step.error.is_some());
        }
    }

    #[test]
    fn credentials_validate_before_io_and_keep_legacy_le() {
        let profile = metadata_profile();
        for input in [vec![], b"123456789".to_vec(), vec![0xff; 6]] {
            let mut op = profile.piv_credential(PivCredentialOperation::VerifyPin, input, vec![]);
            assert_eq!(op.start().error.unwrap().kind, "InvalidPin");
        }
        let mut observations = canokey::compatibility::DeviceObservations::new(b"1.3".to_vec());
        observations.piv_version = Some(canokey::compatibility::PivApplicationVersion([5, 7, 0]));
        let profile = ProtocolProfile {
            inner: Some(canokey::DeviceProfile::from_observations(observations).unwrap()),
        };
        let mut op = profile.piv_credential(
            PivCredentialOperation::VerifyPin,
            b"123456".to_vec(),
            vec![],
        );
        assert_eq!(
            op.start().command.unwrap(),
            b"\x00\x20\x00\x80\x08123456\xff\xff\x00"
        );
        assert_eq!(op.advance(vec![0x90, 0]).data.unwrap(), Vec::<u8>::new());
    }

    #[test]
    fn selected_pin_status_never_selects_and_validates_acknowledgment() {
        for status in [0x9000u16, 0x63c0, 0x63c3, 0x6983] {
            let mut op = ProtocolOperation::piv_read(PivReadOperation::PinStatus);
            assert_eq!(op.start().command.unwrap(), [0, 0x20, 0, 0x80, 0]);
            assert_eq!(
                op.advance(status.to_be_bytes().to_vec()).data.unwrap(),
                status.to_be_bytes()
            );
        }
        for response in [vec![1, 0x90, 0], vec![0x6d, 0], vec![0x90]] {
            let mut op = ProtocolOperation::piv_read(PivReadOperation::PinStatus);
            op.start();
            assert!(op.advance(response).error.is_some());
        }
    }

    #[test]
    fn probe_transfers_profile_and_metadata_copies_its_evidence() {
        let mut probe = ProtocolOperation::probe_piv();
        assert_eq!(
            probe.start().command.unwrap(),
            [0, 0xa4, 4, 0, 5, 0xf0, 0, 0, 0, 0, 0]
        );
        let mut step = probe.advance(vec![0x90, 0]);
        for response in [
            b"3.1.0\x90\0".to_vec(),
            b"CanoKey\x90\0".to_vec(),
            vec![1, 2, 3, 4, 0x90, 0],
            vec![0x90, 0],
            vec![6, 0, 0, 0x90, 0],
            vec![0x6d, 0],
        ] {
            assert!(step.command.is_some());
            step = probe.advance(response);
        }
        let mut profile = step.profile.unwrap();
        probe.close();
        let mut metadata = profile.piv_metadata(0x80);
        profile.close();
        profile.close();
        assert_eq!(
            profile.piv_metadata(0x80).start().error.unwrap().kind,
            "OperationStateError"
        );
        assert_eq!(metadata.start().command.unwrap(), [0, 0xf7, 0, 0x80, 0]);
        assert_eq!(
            metadata
                .advance(vec![1, 1, 0xff, 6, 2, 3, 2, 0x90, 0])
                .data
                .unwrap(),
            [1, 1, 0xff, 6, 2, 3, 2]
        );
    }

    #[test]
    fn metadata_keeps_card_errors_and_rejects_duplicate_fields() {
        let profile = metadata_profile();
        for (response, kind) in [
            (vec![0x6a, 0x88], "NotFound"),
            (vec![0x69, 0x82], "SecurityStatusNotSatisfied"),
            (vec![1, 1, 0xff, 1, 1, 0xff, 0x90, 0], "InvalidResponse"),
        ] {
            let mut metadata = profile.piv_metadata(0x80);
            assert_eq!(metadata.start().command.unwrap(), [0, 0xf7, 0, 0x80, 0]);
            assert_eq!(metadata.advance(response).error.unwrap().kind, kind);
            assert_eq!(metadata.start().error.unwrap().kind, "OperationStateError");
        }
        assert_eq!(
            profile.piv_metadata(0x96).start().error.unwrap().kind,
            "InvalidArgument"
        );
    }

    #[test]
    fn certificate_read_corrects_le_and_unwraps_without_select() {
        let mut op = metadata_profile().piv_certificate(5);
        assert_eq!(
            op.start().command.unwrap(),
            [0, 0xcb, 0x3f, 0xff, 5, 0x5c, 3, 0x5f, 0xc1, 5, 0]
        );
        assert_eq!(op.advance(vec![0x6c, 7]).command.unwrap().last(), Some(&7));
        assert_eq!(
            op.advance(vec![0x53, 5, 0x70, 3, 0x61, 3]).command.unwrap(),
            [0, 0xc0, 0, 0, 3]
        );
        assert_eq!(
            op.advance(vec![0x30, 1, 0, 0x90, 0]).data.unwrap(),
            [0x30, 1, 0]
        );
        op.close();
        assert_eq!(op.start().error.unwrap().kind, "OperationStateError");
    }

    #[test]
    fn certificate_parse_and_card_failures_are_terminal() {
        // Preserve the pinned upstream phase, including its known outer-container
        // classification bug. The fix belongs to canokey-piv, not this bridge.
        for (response, kind, phase) in [
            (vec![0x6a, 0x88], "NotFound", "Command"),
            (vec![0x70, 1, 0, 0x90, 0], "InvalidResponse", "Parsing"),
            (
                vec![0x53, 3, 0x70, 1, 0, 0x53, 0, 0x90, 0],
                "InvalidResponse",
                "Parsing",
            ),
        ] {
            let mut op = metadata_profile().piv_certificate(5);
            op.start();
            let error = op.advance(response).error.unwrap();
            assert_eq!(error.kind, kind);
            assert_eq!(error.phase, phase);
            assert_eq!(
                op.advance(vec![0x90, 0]).error.unwrap().kind,
                "OperationStateError"
            );
        }
    }

    #[test]
    fn selected_version_continuation_and_le_correction() {
        let mut op = ProtocolOperation::piv_read(PivReadOperation::Version);
        assert_eq!(op.start().command.unwrap(), [0, 0xfd, 0, 0, 0]);
        assert_eq!(
            op.advance(vec![0x6c, 3]).command.unwrap(),
            [0, 0xfd, 0, 0, 3]
        );
        assert_eq!(
            op.advance(vec![6, 0x61, 2]).command.unwrap(),
            [0, 0xc0, 0, 0, 2]
        );
        assert_eq!(op.advance(vec![0, 0, 0x90, 0]).data.unwrap(), [6, 0, 0]);
        assert_eq!(op.start().error.unwrap().kind, "OperationStateError");
        op.close();
        op.close();
        assert_eq!(
            op.advance(vec![0x90, 0]).error.unwrap().kind,
            "OperationStateError"
        );
    }

    #[test]
    fn select_and_structured_failure() {
        let mut op = ProtocolOperation::piv_read(PivReadOperation::Select);
        assert_eq!(
            op.start().command.unwrap(),
            [0, 0xa4, 4, 0, 5, 0xa0, 0, 0, 3, 8, 0]
        );
        let error = op.advance(vec![0x6a, 0x82]).error.unwrap();
        assert_eq!(error.kind, "UnsupportedDevice");
        assert_eq!(error.phase, "Select");
        assert_eq!(error.status_word, Some(0x6a82));
    }

    #[test]
    fn malformed_and_oversized_responses_are_terminal() {
        for response in [vec![0x90], vec![0, 0x90, 0], vec![0; 259]] {
            let mut op = ProtocolOperation::piv_read(PivReadOperation::Version);
            op.start();
            assert!(op.advance(response).error.is_some());
            assert_eq!(
                op.advance(vec![6, 0, 0, 0x90, 0]).error.unwrap().kind,
                "OperationStateError"
            );
        }
    }

    #[test]
    fn bootstrap_identity_uses_upstream_builders_and_keeps_status_failures() {
        let mut select = ProtocolOperation::bootstrap_identity(BootstrapIdentityStep::SelectAdmin);
        assert_eq!(
            select.start().command.unwrap(),
            [0, 0xa4, 4, 0, 5, 0xf0, 0, 0, 0, 0]
        );
        let error = select.advance(vec![0x6a, 0x82]).error.unwrap();
        assert_eq!(error.phase, "Select");
        assert_eq!(error.status_word, Some(0x6a82));
        assert_eq!(
            select.advance(vec![0x90, 0]).error.unwrap().kind,
            "OperationStateError"
        );

        let mut serial = ProtocolOperation::bootstrap_identity(BootstrapIdentityStep::Serial);
        assert_eq!(serial.start().command.unwrap(), [0, 0x32, 0, 0, 0]);
        // The upstream builder permits one safe Le correction.
        assert_eq!(
            serial.advance(vec![0x6c, 4]).command.unwrap(),
            [0, 0x32, 0, 0, 4]
        );
        assert_eq!(
            serial.advance(vec![1, 2, 3, 4, 0x90, 0]).data.unwrap(),
            [1, 2, 3, 4]
        );

        let mut serial = ProtocolOperation::bootstrap_identity(BootstrapIdentityStep::Serial);
        serial.start();
        let error = serial.advance(vec![0x6d, 0]).error.unwrap();
        assert_eq!(error.status_word, Some(0x6d00));
        serial.close();
        serial.close();
    }

    #[test]
    fn configuration_uses_upstream_validation() {
        let mut op = ProtocolOperation::piv_read(PivReadOperation::AlgorithmConfiguration);
        assert_eq!(op.start().command.unwrap(), [0, 0xee, 1, 0, 0]);
        assert!(op.advance(vec![1, 0x90, 0]).error.is_some());
        let mut op = ProtocolOperation::piv_read(PivReadOperation::AlgorithmConfiguration);
        op.start();
        let bytes = vec![1, 0xe0, 5, 0x16, 0xe1, 0x53, 0x15, 0x54, 0xe2, 0xe3];
        let mut response = bytes.clone();
        response.extend([0x90, 0]);
        assert_eq!(op.advance(response).data.unwrap(), bytes);
    }

    fn oath_selection(protected_: bool) -> Vec<u8> {
        let mut data = vec![0x79, 3, 6, 0, 0, 0x71, 8];
        data.extend(b"12345678");
        if protected_ {
            data.extend([0x74, 8]);
            data.extend(b"CCCCCCCC");
            data.extend([0x7b, 1, 1]);
        }
        data.extend([0x90, 0]);
        data
    }

    #[test]
    fn oath_operation_validates_supplied_access_before_target() {
        let profile = metadata_profile();
        let mut op = profile.oath_calculate(
            b"test".to_vec(),
            1,
            1,
            None,
            0,
            Some(b"KKKKKKKKKKKKKKKK".to_vec()),
            Some(b"HHHHHHHH".to_vec()),
        );
        assert_eq!(
            op.start().command.unwrap(),
            [0, 0xa4, 4, 0, 7, 0xa0, 0, 0, 5, 0x27, 0x21, 1]
        );
        let mut validate = vec![0, 0xa3, 0, 0, 32, 0x75, 20];
        validate.extend([
            0x0d, 0xe0, 0xba, 0xe2, 0x81, 0xba, 0x21, 0x98, 0x0e, 0x76, 0x92, 0xc9, 0x34, 0x52,
            0x9f, 0x0f, 0x61, 0x11, 0x16, 0x51,
        ]);
        validate.extend([0x74, 8]);
        validate.extend(b"HHHHHHHH");
        assert_eq!(op.advance(oath_selection(true)).command.unwrap(), validate);
        let mut proof = vec![0x75, 20];
        proof.extend([
            0xca, 0xa1, 0x34, 0x6e, 0x39, 0x05, 0x8d, 0xd3, 0x6e, 0xd7, 0x6f, 0xb4, 0x90, 0x53,
            0xe1, 0x4f, 0x66, 0xce, 0x42, 0x8b,
        ]);
        proof.extend([0x90, 0]);
        assert_eq!(
            op.advance(proof).command.unwrap(),
            [0, 0xa2, 0, 1, 6, 0x71, 4, b't', b'e', b's', b't']
        );
        // Nameless individual calculation: raw truncated bytes stay host-formattable.
        assert_eq!(
            op.advance(vec![0x76, 5, 6, 0, 0, 0, 42, 0x90, 0])
                .data
                .unwrap(),
            [0xff, 6, 0x76, 4, 0, 0, 0, 42]
        );
    }

    #[test]
    fn oath_protected_applet_rejects_missing_or_partial_access_before_io() {
        let profile = metadata_profile();
        let mut op = profile.oath_delete(b"test".to_vec(), None, None);
        op.start();
        let error = op.advance(oath_selection(true)).error.unwrap();
        assert_eq!(error.kind, "SecurityStatusNotSatisfied");
        assert_eq!(error.phase, "Authentication");

        let mut op =
            profile.oath_delete(b"test".to_vec(), Some(b"KKKKKKKKKKKKKKKK".to_vec()), None);
        assert_eq!(op.start().error.unwrap().kind, "InvalidArgument");

        // A rejected access key keeps its credential reference.
        let mut op = profile.oath_delete(
            b"test".to_vec(),
            Some(b"KKKKKKKKKKKKKKKK".to_vec()),
            Some(b"HHHHHHHH".to_vec()),
        );
        op.start();
        op.advance(oath_selection(true));
        let error = op.advance(vec![0x6a, 0x80]).error.unwrap();
        assert_eq!(error.kind, "AuthenticationFailed");
        assert_eq!(error.phase, "Authentication");
        assert_eq!(error.status_word, Some(0x6a80));
        assert_eq!(error.reference.as_deref(), Some("OathAccess"));
    }

    #[test]
    fn oath_calculate_all_encodes_names_digits_and_markers() {
        let profile = metadata_profile();
        let mut op = profile.oath_calculate_all(vec![0, 0, 0, 0, 0, 0, 0, 1], 0, None, None);
        op.start();
        let command = op.advance(oath_selection(false)).command.unwrap();
        assert_eq!(&command[..5], [0, 0xa4, 0, 1, 10]);
        let mut page = vec![
            0x71, 1, b'A', 0x76, 5, 6, 0, 0, 0, 1, // truncated code
            0x71, 1, b'B', 0x77, 1, 6, // HOTP marker
            0x71, 1, b'C', 0x7c, 1, 6, // touch marker
        ];
        page.extend([0x90, 0]);
        let probe = op.advance(page).command.unwrap();
        assert_eq!(probe, [0, 0xa5, 0, 0, 0xff]);
        assert_eq!(
            op.advance(vec![0x69, 0x85]).data.unwrap(),
            [
                1, b'A', 6, 0x76, 4, 0, 0, 0, 1, //
                1, b'B', 6, 0x77, 0, //
                1, b'C', 6, 0x7c, 0,
            ]
        );
    }

    #[test]
    fn oath_legacy_dialect_and_modern_capability_gate() {
        let legacy = ProtocolProfile {
            inner: Some(
                canokey::DeviceProfile::from_observations(
                    canokey::compatibility::DeviceObservations::new(b"1.3.0".to_vec()),
                )
                .unwrap(),
            ),
        };
        // Legacy 1.3 has no access codes: supplying one fails before any I/O.
        let mut op = legacy.oath_delete(
            b"test".to_vec(),
            Some(b"KKKKKKKKKKKKKKKK".to_vec()),
            Some(b"HHHHHHHH".to_vec()),
        );
        assert_eq!(op.start().error.unwrap().kind, "UnsupportedFeature");

        let mut op = legacy.oath_delete(b"test".to_vec(), None, None);
        op.start();
        let command = op.advance(vec![0x90, 0]).command.unwrap();
        assert_eq!(&command[..4], [0, 2, 0, 0]);
        assert_eq!(op.advance(vec![0x90, 0]).data.unwrap(), Vec::<u8>::new());
    }

    fn openpgp_profile(firmware: &[u8]) -> ProtocolProfile {
        ProtocolProfile {
            inner: Some(
                canokey::DeviceProfile::from_observations(
                    canokey::compatibility::DeviceObservations::new(firmware.to_vec()),
                )
                .unwrap(),
            ),
        }
    }

    /// Drive SELECT + explicit VERIFY PW3(12345678) + target, asserting wire bytes.
    fn drive_openpgp_write(mut op: ProtocolOperation, target: &[u8]) -> ProtocolOperation {
        assert_eq!(
            op.start().command.unwrap(),
            [0, 0xa4, 4, 0, 6, 0xd2, 0x76, 0, 1, 0x24, 1]
        );
        assert_eq!(
            op.advance(vec![0x90, 0]).command.unwrap(),
            b"\x00\x20\x00\x83\x0812345678"
        );
        assert_eq!(op.advance(vec![0x90, 0]).command.unwrap(), target);
        op
    }

    #[test]
    fn openpgp_admin_writes_select_verify_and_own_wire_bytes() {
        let profile = metadata_profile();
        let mut op = drive_openpgp_write(
            profile.openpgp_write_reset_code(Some(b"12345678".to_vec()), b"12345678".to_vec()),
            b"\x00\xda\x00\xd3\x0812345678",
        );
        assert_eq!(op.advance(vec![0x90, 0]).data.unwrap(), Vec::<u8>::new());

        // None clears the reset code with a dataless PUT DATA.
        let mut op = drive_openpgp_write(
            profile.openpgp_write_reset_code(None, b"12345678".to_vec()),
            &[0, 0xda, 0, 0xd3],
        );
        assert_eq!(op.advance(vec![0x90, 0]).data.unwrap(), Vec::<u8>::new());

        let mut op = drive_openpgp_write(
            profile.openpgp_reset_retries(vec![3, 4, 5], b"12345678".to_vec()),
            &[0, 0xf2, 0, 0, 3, 3, 4, 5],
        );
        assert_eq!(op.advance(vec![0x90, 0]).data.unwrap(), Vec::<u8>::new());

        let mut op = drive_openpgp_write(
            profile.openpgp_write_signature_pin_policy(false, b"12345678".to_vec()),
            &[0, 0xda, 0, 0xc4, 1, 0],
        );
        assert_eq!(op.advance(vec![0x90, 0]).data.unwrap(), Vec::<u8>::new());
        let mut op = drive_openpgp_write(
            profile.openpgp_write_signature_pin_policy(true, b"12345678".to_vec()),
            &[0, 0xda, 0, 0xc4, 1, 1],
        );
        assert_eq!(op.advance(vec![0x90, 0]).data.unwrap(), Vec::<u8>::new());

        let mut op = drive_openpgp_write(
            profile.openpgp_unblock_with_admin(b"654321".to_vec(), b"12345678".to_vec()),
            b"\x00\x2c\x02\x81\x06654321",
        );
        assert_eq!(op.advance(vec![0x90, 0]).data.unwrap(), Vec::<u8>::new());

        let mut op = drive_openpgp_write(
            profile.openpgp_write_touch_policy(1, 1, b"12345678".to_vec()),
            &[0, 0xda, 0, 0xd7, 2, 1, 0x20],
        );
        assert_eq!(op.advance(vec![0x90, 0]).data.unwrap(), Vec::<u8>::new());

        let mut op = drive_openpgp_write(
            profile.openpgp_write_touch_cache_time(15, b"12345678".to_vec()),
            &[0, 0xda, 1, 2, 1, 15],
        );
        assert_eq!(op.advance(vec![0x90, 0]).data.unwrap(), Vec::<u8>::new());
    }

    #[test]
    fn openpgp_unblock_with_code_skips_verify_and_maps_reset_code_failures() {
        let profile = metadata_profile();
        for (sw, kind, retries) in [
            (0x63c2u16, "AuthenticationFailed", Some(2)),
            (0x6983, "PinBlocked", None),
        ] {
            let mut op =
                profile.openpgp_unblock_with_code(b"24682468".to_vec(), b"654321".to_vec());
            assert_eq!(
                op.start().command.unwrap(),
                [0, 0xa4, 4, 0, 6, 0xd2, 0x76, 0, 1, 0x24, 1]
            );
            assert_eq!(
                op.advance(vec![0x90, 0]).command.unwrap(),
                b"\x00\x2c\x00\x81\x0e24682468654321"
            );
            let error = op.advance(sw.to_be_bytes().to_vec()).error.unwrap();
            assert_eq!(error.kind, kind);
            assert_eq!(error.phase, "Authentication");
            assert_eq!(error.reference.as_deref(), Some("ResetCode"));
            assert_eq!(error.retries_remaining, retries);
        }
        let mut op = profile.openpgp_unblock_with_code(b"24682468".to_vec(), b"654321".to_vec());
        op.start();
        op.advance(vec![0x90, 0]);
        assert_eq!(op.advance(vec![0x90, 0]).data.unwrap(), Vec::<u8>::new());
    }

    #[test]
    fn openpgp_write_failures_keep_credential_reference_and_status() {
        let profile = metadata_profile();
        // VERIFY rejection: reference, retries and phase are retained.
        let mut op =
            profile.openpgp_write_reset_code(Some(b"12345678".to_vec()), b"12345678".to_vec());
        op.start();
        op.advance(vec![0x90, 0]);
        let error = op.advance(vec![0x63, 0xc2]).error.unwrap();
        assert_eq!(error.kind, "AuthenticationFailed");
        assert_eq!(error.phase, "Authentication");
        assert_eq!(error.reference.as_deref(), Some("Pw3"));
        assert_eq!(error.retries_remaining, Some(2));

        // OpenPGP VERIFY 6982 means authentication failure without a retry count.
        let mut op = profile.openpgp_reset_retries(vec![3, 3, 3], b"12345678".to_vec());
        op.start();
        op.advance(vec![0x90, 0]);
        let error = op.advance(vec![0x69, 0x82]).error.unwrap();
        assert_eq!(error.kind, "AuthenticationFailed");
        assert_eq!(error.reference.as_deref(), Some("Pw3"));
        assert_eq!(error.retries_remaining, None);

        // A security rejection at the target stage carries no credential reference.
        let mut op = profile.openpgp_write_touch_cache_time(15, b"12345678".to_vec());
        op.start();
        op.advance(vec![0x90, 0]);
        op.advance(vec![0x90, 0]);
        let error = op.advance(vec![0x69, 0x82]).error.unwrap();
        assert_eq!(error.kind, "SecurityStatusNotSatisfied");
        assert_eq!(error.phase, "Command");
        assert_eq!(error.reference, None);
    }

    #[test]
    fn openpgp_bridge_validates_arguments_and_capabilities_before_io() {
        // Reset code must satisfy the 8..64 administrative length.
        for code in [b"123456".to_vec(), vec![b'x'; 65]] {
            let mut op =
                metadata_profile().openpgp_write_reset_code(Some(code), b"12345678".to_vec());
            assert_eq!(op.start().error.unwrap().kind, "InvalidPin");
        }
        // Retry limits are exactly three values in 1..=15.
        let mut op = metadata_profile().openpgp_reset_retries(vec![3, 3], b"12345678".to_vec());
        assert_eq!(op.start().error.unwrap().kind, "InvalidArgument");
        let mut op = metadata_profile().openpgp_reset_retries(vec![0, 3, 3], b"12345678".to_vec());
        assert_eq!(op.start().error.unwrap().kind, "InvalidArgument");
        // Touch policy and slot identifiers are validated in the bridge.
        let mut op = metadata_profile().openpgp_write_touch_policy(0, 3, b"12345678".to_vec());
        assert_eq!(op.start().error.unwrap().kind, "InvalidArgument");
        let mut op = metadata_profile().openpgp_write_touch_policy(3, 1, b"12345678".to_vec());
        assert_eq!(op.start().error.unwrap().kind, "InvalidArgument");
        // Reset codes below the administrative length fail before any I/O.
        let mut op =
            metadata_profile().openpgp_unblock_with_code(b"123456".to_vec(), b"654321".to_vec());
        assert_eq!(op.start().error.unwrap().kind, "InvalidPin");

        // UIF writes require the 1.5.2 capability; retry reset requires 3.1.0.
        let legacy = openpgp_profile(b"1.3.0");
        let mut op = legacy.openpgp_write_touch_policy(0, 1, b"12345678".to_vec());
        assert_eq!(op.start().error.unwrap().kind, "UnsupportedFeature");
        let mut op = legacy.openpgp_write_touch_cache_time(15, b"12345678".to_vec());
        assert_eq!(op.start().error.unwrap().kind, "UnsupportedFeature");
        let pre31 = openpgp_profile(b"1.6.0");
        let mut op = pre31.openpgp_reset_retries(vec![3, 3, 3], b"12345678".to_vec());
        assert_eq!(op.start().error.unwrap().kind, "UnsupportedFeature");
    }

    /// 3.1.0 with the observed default extension IDs (Ed25519 E0, SM2 54,
    /// ML-DSA-65 E2), so streaming modes resolve their wire IDs.
    fn streaming_profile(firmware: &[u8]) -> ProtocolProfile {
        let mut observations = canokey::compatibility::DeviceObservations::new(firmware.to_vec());
        observations.piv_version = Some(canokey::compatibility::PivApplicationVersion([6, 0, 0]));
        observations.algorithm_config = Some(
            canokey::compatibility::AlgorithmConfig::parse(&[
                1, 0xe0, 5, 0x16, 0xe1, 0x53, 0x15, 0x54, 0xe2, 0xe3,
            ])
            .unwrap(),
        );
        ProtocolProfile {
            inner: Some(canokey::DeviceProfile::from_observations(observations).unwrap()),
        }
    }

    #[test]
    fn attest_keeps_wire_bytes_and_maps_card_failures() {
        let mut op = metadata_profile().piv_attest(0x9a);
        assert_eq!(op.start().command.unwrap(), [0, 0xf9, 0x9a, 0, 0]);
        assert_eq!(
            op.advance(vec![0x30, 3, 2, 1, 5, 0x90, 0]).data.unwrap(),
            [0x30, 3, 2, 1, 5]
        );

        // An empty payload is malformed, never an empty certificate.
        let mut op = metadata_profile().piv_attest(0x9a);
        op.start();
        assert_eq!(
            op.advance(vec![0x90, 0]).error.unwrap().kind,
            "InvalidResponse"
        );

        // Card failures retain status word and phase; nothing is replayed.
        let mut op = metadata_profile().piv_attest(0x9a);
        op.start();
        let error = op.advance(vec![0x6a, 0x80]).error.unwrap();
        assert_eq!(error.kind, "UnexpectedStatusWord");
        assert_eq!(error.phase, "Command");
        assert_eq!(error.status_word, Some(0x6a80));
        assert!(op.advance(vec![0x90, 0]).error.is_some());

        // Attestation is gated to evidenced 3.1.0 firmware before any I/O.
        let mut observations = canokey::compatibility::DeviceObservations::new(b"3.0.3".to_vec());
        observations.piv_version = Some(canokey::compatibility::PivApplicationVersion([6, 0, 0]));
        let legacy = ProtocolProfile {
            inner: Some(canokey::DeviceProfile::from_observations(observations).unwrap()),
        };
        let mut op = legacy.piv_attest(0x9a);
        assert_eq!(op.start().error.unwrap().kind, "UnsupportedFeature");
    }

    #[test]
    fn streaming_sign_owns_wire_bytes_and_result_validation() {
        // ML-DSA-65: raw message in 7C{82 00, 81 message} under the observed ID.
        let mut op = streaming_profile(b"3.1.0").piv_sign_streaming(0x9a, 0, b"abc".to_vec(), None);
        assert_eq!(
            op.start().command.unwrap(),
            b"\x00\x87\xe2\x9a\x09\x7c\x07\x82\x00\x81\x03abc"
        );
        let signature = vec![7u8; 3309];
        let mut payload = vec![0x7c, 0x82, 0x0c, 0xf1, 0x82, 0x82, 0x0c, 0xed];
        payload.extend(&signature);
        // Replies beyond one physical exchange continue through GET RESPONSE.
        let mut rest = payload.as_slice();
        let mut step = op.advance([&rest[..256], &[0x61, 0]].concat());
        rest = &rest[256..];
        while let Some(command) = step.command {
            assert_eq!(&command[..4], &[0, 0xc0, 0, 0]);
            let take = rest.len().min(256);
            let mut chunk = rest[..take].to_vec();
            rest = &rest[take..];
            if rest.is_empty() {
                chunk.extend([0x90, 0]);
            } else {
                chunk.extend([0x61, u8::try_from(rest.len()).unwrap_or(0)]);
            }
            step = op.advance(chunk);
        }
        assert_eq!(step.data.unwrap(), signature);

        // A wrong-length ML-DSA reply is malformed, not a signature.
        let mut op = streaming_profile(b"3.1.0").piv_sign_streaming(0x9a, 0, b"abc".to_vec(), None);
        op.start();
        let mut short = vec![0x7c, 4, 0x82, 2, 1, 2];
        short.extend([0x90, 0]);
        assert_eq!(op.advance(short).error.unwrap().kind, "InvalidResponse");

        // Randomized Ed25519 always uses wire mode FF; empty messages sign.
        let mut op = streaming_profile(b"3.1.0").piv_sign_streaming(0x9a, 1, vec![], None);
        assert_eq!(
            op.start().command.unwrap(),
            [0, 0x87, 0xff, 0x9a, 6, 0x7c, 4, 0x82, 0, 0x81, 0]
        );
        let mut response = vec![0x7c, 0x42, 0x82, 0x40];
        response.extend([3u8; 64]);
        response.extend([0x90, 0]);
        assert_eq!(op.advance(response).data.unwrap(), [3u8; 64]);

        // SM2: a chained prefix carrying only the outer tag precedes the body,
        // and the result stays in the card's P1363 encoding.
        let mut op = streaming_profile(b"3.1.0").piv_sign_streaming(0x9a, 2, b"abc".to_vec(), None);
        assert_eq!(
            op.start().command.unwrap(),
            [0x10, 0x87, 0x54, 0x9a, 1, 0x7c]
        );
        assert_eq!(
            op.advance(vec![0x90, 0]).command.unwrap(),
            b"\x00\x87\x54\x9a\x08\x07\x82\x00\x81\x03abc"
        );
        // Nonempty intermediate data violates the prefix acknowledgment.
        let mut op = streaming_profile(b"3.1.0").piv_sign_streaming(0x9a, 2, b"abc".to_vec(), None);
        op.start();
        assert!(op.advance(vec![1, 0x90, 0]).error.is_some());
    }

    #[test]
    fn streaming_sign_validates_mode_and_capabilities_before_io() {
        // Unknown modes and invalid slots fail without a command.
        let mut op = streaming_profile(b"3.1.0").piv_sign_streaming(0x9a, 3, vec![1], None);
        assert_eq!(op.start().error.unwrap().kind, "InvalidArgument");
        let mut op = streaming_profile(b"3.1.0").piv_sign_streaming(0x80, 0, vec![1], None);
        assert_eq!(op.start().error.unwrap().kind, "InvalidArgument");
        // An SM2 user ID outside 1..=32 bytes is rejected before any I/O.
        let mut op = streaming_profile(b"3.1.0").piv_sign_streaming(0x9a, 2, vec![1], Some(vec![]));
        assert_eq!(op.start().error.unwrap().kind, "InvalidArgument");

        // Streaming modes require evidenced 3.1.0 firmware and observed
        // enabled algorithm IDs; older firmware and unobserved IDs fail fast.
        for mode in [0, 1, 2] {
            let mut op = streaming_profile(b"3.0.3").piv_sign_streaming(0x9a, mode, vec![1], None);
            assert_eq!(op.start().error.unwrap().kind, "UnsupportedFeature");
        }
        let mut op = metadata_profile().piv_sign_streaming(0x9a, 0, vec![1], None);
        assert!(op.start().error.is_some());
    }

    #[test]
    fn pass_slots_read_encodes_typed_states_and_keeps_unknown_types() {
        let profile = metadata_profile();
        let mut op = profile.admin_pass_slots(Some(b"123456".to_vec()), false);
        assert_eq!(
            op.start().command.unwrap(),
            [0, 0xa4, 4, 0, 5, 0xf0, 0, 0, 0, 0]
        );
        assert_eq!(
            op.advance(vec![0x90, 0]).command.unwrap(),
            b"\x00\x20\x00\x00\x06123456"
        );
        assert_eq!(
            op.advance(vec![0x90, 0]).command.unwrap(),
            [0, 0x43, 0, 0, 0]
        );
        // Short = static with enter; long = OATH credential "test" without enter.
        let mut raw = vec![0x02, 0x01, 0x01, 4];
        raw.extend(b"test");
        raw.extend([0, 0x90, 0]);
        let result = op.advance(raw).admin.unwrap();
        assert!(matches!(result.kind, AdminValueKind::PassSlots));
        assert_eq!(
            result.data,
            [2, 0x02, 0x01, 7, 0x01, 4, b't', b'e', b's', b't', 0]
        );

        // Unknown type bytes pass through verbatim; off stays a single byte.
        let mut op = profile.admin_pass_slots(Some(b"123456".to_vec()), false);
        op.start();
        op.advance(vec![0x90, 0]);
        op.advance(vec![0x90, 0]);
        let result = op.advance(vec![0x7f, 0x00, 0x90, 0]).admin.unwrap();
        assert_eq!(result.data, [1, 0x7f, 1, 0x00]);

        // Malformed dumps remain parsing failures, never fabricated slots.
        let mut op = profile.admin_pass_slots(None, true);
        assert_eq!(op.start().command.unwrap(), [0, 0x43, 0, 0, 0]);
        let error = op.advance(vec![0x02, 0x90, 0]).error.unwrap();
        assert_eq!(error.kind, "InvalidResponse");
        assert_eq!(error.phase, "Parsing");
    }

    #[test]
    fn admin_existing_never_selects_or_verifies_and_rejects_pin() {
        let profile = metadata_profile();
        // Existing plus a PIN is meaningless and fails before any I/O.
        let mut op = profile.admin_pass_slots(Some(b"123456".to_vec()), true);
        assert_eq!(op.start().error.unwrap().kind, "InvalidArgument");
        // VerifyPin carries no PIN of its own and is rejected under Existing.
        let mut op = profile.admin_operation(Ok(admin::Request::VerifyPin), None, true);
        assert_eq!(op.start().error.unwrap().kind, "InvalidArgument");

        // A protected write under Existing is exactly its target command.
        let mut op = profile.admin_set_pass_slot(0, 1, b"pw".to_vec(), true, None, true);
        assert_eq!(
            op.start().command.unwrap(),
            [0, 0x44, 1, 0, 5, 2, 2, b'p', b'w', 1]
        );
        let result = op.advance(vec![0x90, 0]).admin.unwrap();
        assert!(matches!(result.kind, AdminValueKind::None));
        assert_eq!(result.progress.confirmed_writes, 1);
        assert!(result.progress.reprobe_required);
    }

    #[test]
    fn admin_read_configure_and_action_honor_existing_access() {
        let profile = metadata_profile();
        // Existing skips SELECT on reads and rejects a carried PIN preflight.
        let mut op = profile.admin_read(AdminReadOperation::ChipId, None, true);
        assert_eq!(op.start().command.unwrap(), [0, 0x32, 1, 0, 0]);
        let mut op = profile.admin_read(AdminReadOperation::ChipId, Some(b"123456".to_vec()), true);
        assert_eq!(op.start().error.unwrap().kind, "InvalidArgument");

        // An Existing configure is only the validated read/patch sequence.
        let mut op = profile.admin_configure(
            AdminConfigurationPatch {
                led_on: Some(false),
                ndef_read_only: None,
                ndef_enabled: None,
                webusb_landing: None,
                feature_mask: 0,
                feature_values: 0,
            },
            None,
            true,
        );
        assert_eq!(op.start().command.unwrap(), [0, 0x42, 0, 0, 0]);
        assert_eq!(
            op.advance(vec![1, 0, 0, 1, 1, 63, 0x90, 0])
                .command
                .unwrap(),
            [0, 0x40, 1, 0]
        );
        assert!(op.advance(vec![0x90, 0]).admin.is_some());
        let mut op = profile.admin_configure(
            AdminConfigurationPatch {
                led_on: None,
                ndef_read_only: None,
                ndef_enabled: None,
                webusb_landing: None,
                feature_mask: 0,
                feature_values: 0,
            },
            Some(b"123456".to_vec()),
            true,
        );
        assert_eq!(op.start().error.unwrap().kind, "InvalidArgument");

        // An Existing write action is exactly its target command; VerifyPin
        // under Existing is rejected by the pinned upstream contract.
        let mut op = profile.admin_action(AdminAction::Nfc, None, vec![], 0, 0, true);
        assert_eq!(op.start().command.unwrap(), [0, 0x14, 1, 0]);
        assert!(op.advance(vec![0x90, 0]).admin.is_some());
        let mut op = profile.admin_action(
            AdminAction::VerifyPin,
            Some(b"123456".to_vec()),
            vec![],
            0,
            0,
            true,
        );
        assert_eq!(op.start().error.unwrap().kind, "InvalidArgument");
        let mut op = profile.admin_action(AdminAction::VerifyPin, None, vec![], 0, 0, true);
        assert_eq!(op.start().error.unwrap().kind, "InvalidArgument");
    }

    #[test]
    fn set_pass_slot_validates_slot_kind_and_secret_before_io() {
        let profile = metadata_profile();
        let mut op = profile.admin_set_pass_slot(2, 1, b"pw".to_vec(), false, None, true);
        assert_eq!(op.start().error.unwrap().kind, "InvalidArgument");
        let mut op = profile.admin_set_pass_slot(0, 3, vec![], false, None, true);
        assert_eq!(op.start().error.unwrap().kind, "InvalidArgument");
        // Static passwords are at most 32 printable ASCII bytes.
        let mut op = profile.admin_set_pass_slot(0, 1, vec![b'x'; 33], false, None, true);
        assert_eq!(op.start().error.unwrap().kind, "InvalidArgument");
        let mut op = profile.admin_set_pass_slot(0, 1, vec![0x7f], false, None, true);
        assert_eq!(op.start().error.unwrap().kind, "InvalidArgument");
        // HMAC-SHA1 keys are exactly twenty bytes.
        let mut op = profile.admin_set_pass_slot(1, 2, vec![0; 19], false, None, true);
        assert_eq!(op.start().error.unwrap().kind, "InvalidArgument");
        // Without Existing or a PIN the protected write fails preflight.
        let mut op = profile.admin_set_pass_slot(0, 0, vec![], false, None, false);
        assert_eq!(op.start().error.unwrap().kind, "SecurityStatusNotSatisfied");

        // HMAC-SHA1 long-slot wire bytes with the per-request PIN sequence.
        let mut op =
            profile.admin_set_pass_slot(1, 2, vec![9; 20], false, Some(b"123456".to_vec()), false);
        op.start();
        op.advance(vec![0x90, 0]);
        let mut expected = vec![0, 0x44, 2, 0, 22, 3, 0x14];
        expected.extend([9; 20]);
        assert_eq!(op.advance(vec![0x90, 0]).command.unwrap(), expected);
        let result = op.advance(vec![0x90, 0]).admin.unwrap();
        assert!(matches!(result.kind, AdminValueKind::None));
        assert!(result.progress.reprobe_required);
    }

    #[test]
    fn oath_set_default_uses_profile_dialect_and_validates_before_io() {
        let profile = metadata_profile();
        let mut op = profile.oath_set_default(1, true, "test".to_string(), None, None);
        assert_eq!(
            op.start().command.unwrap(),
            [0, 0xa4, 4, 0, 7, 0xa0, 0, 0, 5, 0x27, 0x21, 1]
        );
        assert_eq!(
            op.advance(oath_selection(false)).command.unwrap(),
            [0, 0x55, 2, 1, 6, 0x71, 4, b't', b'e', b's', b't']
        );
        assert_eq!(op.advance(vec![0x90, 0]).data.unwrap(), Vec::<u8>::new());

        // Unknown slots fail before any I/O.
        let mut op = profile.oath_set_default(2, false, "test".to_string(), None, None);
        assert_eq!(op.start().error.unwrap().kind, "InvalidArgument");

        // Legacy firmware has one slot and no enter flag; only Short/false
        // fits its zero-P1/P2 dialect. Long or append-enter fail fast.
        let legacy = openpgp_profile(b"1.3.0");
        let mut op = legacy.oath_set_default(1, false, "test".to_string(), None, None);
        assert_eq!(op.start().error.unwrap().kind, "InvalidArgument");
        let mut op = legacy.oath_set_default(0, true, "test".to_string(), None, None);
        assert_eq!(op.start().error.unwrap().kind, "InvalidArgument");
        let mut op = legacy.oath_set_default(0, false, "test".to_string(), None, None);
        op.start();
        // The legacy dialect carries an explicit trailing Le.
        assert_eq!(
            op.advance(vec![0x90, 0]).command.unwrap(),
            [0, 0x55, 0, 0, 6, 0x71, 4, b't', b'e', b's', b't', 0]
        );
        assert_eq!(op.advance(vec![0x90, 0]).data.unwrap(), Vec::<u8>::new());
    }

    #[test]
    fn oath_set_default_validates_access_like_other_writes() {
        let profile = metadata_profile();
        let mut op = profile.oath_set_default(
            0,
            false,
            "test".to_string(),
            Some(b"KKKKKKKKKKKKKKKK".to_vec()),
            Some(b"HHHHHHHH".to_vec()),
        );
        op.start();
        let mut validate = vec![0, 0xa3, 0, 0, 32, 0x75, 20];
        validate.extend([
            0x0d, 0xe0, 0xba, 0xe2, 0x81, 0xba, 0x21, 0x98, 0x0e, 0x76, 0x92, 0xc9, 0x34, 0x52,
            0x9f, 0x0f, 0x61, 0x11, 0x16, 0x51,
        ]);
        validate.extend([0x74, 8]);
        validate.extend(b"HHHHHHHH");
        assert_eq!(op.advance(oath_selection(true)).command.unwrap(), validate);
        let mut proof = vec![0x75, 20];
        proof.extend([
            0xca, 0xa1, 0x34, 0x6e, 0x39, 0x05, 0x8d, 0xd3, 0x6e, 0xd7, 0x6f, 0xb4, 0x90, 0x53,
            0xe1, 0x4f, 0x66, 0xce, 0x42, 0x8b,
        ]);
        proof.extend([0x90, 0]);
        assert_eq!(
            op.advance(proof).command.unwrap(),
            [0, 0x55, 1, 0, 6, 0x71, 4, b't', b'e', b's', b't']
        );
        assert_eq!(op.advance(vec![0x90, 0]).data.unwrap(), Vec::<u8>::new());

        // A missing challenge half is rejected before any I/O.
        let mut op = profile.oath_set_default(
            0,
            false,
            "test".to_string(),
            Some(b"KKKKKKKKKKKKKKKK".to_vec()),
            None,
        );
        assert_eq!(op.start().error.unwrap().kind, "InvalidArgument");
    }

    #[test]
    fn pq_seed_import_owns_seed_tlv_and_capability_gate() {
        // ML-DSA-65: INS FE under the observed E2 wire ID with the 09 seed TLV.
        let mut op = streaming_profile(b"3.1.0").piv_import_pq_seed(0x9a, 0, vec![7; 32], 0, 0);
        let mut expected = vec![0, 0xfe, 0xe2, 0x9a, 34, 0x09, 0x20];
        expected.extend([7; 32]);
        assert_eq!(op.start().command.unwrap(), expected);
        assert_eq!(op.advance(vec![0x90, 0]).data.unwrap(), Vec::<u8>::new());

        // ML-KEM-768: 64-byte d||z seed under the 0A TLV and E3 wire ID.
        let mut op = streaming_profile(b"3.1.0").piv_import_pq_seed(0x9d, 1, vec![8; 64], 0, 0);
        let mut expected = vec![0, 0xfe, 0xe3, 0x9d, 66, 0x0a, 0x40];
        expected.extend([8; 64]);
        assert_eq!(op.start().command.unwrap(), expected);
        assert_eq!(op.advance(vec![0x90, 0]).data.unwrap(), Vec::<u8>::new());

        // Seed length, kind and slot are validated before any I/O.
        let mut op = streaming_profile(b"3.1.0").piv_import_pq_seed(0x9a, 0, vec![7; 31], 0, 0);
        assert_eq!(op.start().error.unwrap().kind, "InvalidArgument");
        let mut op = streaming_profile(b"3.1.0").piv_import_pq_seed(0x9a, 1, vec![8; 32], 0, 0);
        assert_eq!(op.start().error.unwrap().kind, "InvalidArgument");
        let mut op = streaming_profile(b"3.1.0").piv_import_pq_seed(0x9a, 2, vec![7; 32], 0, 0);
        assert_eq!(op.start().error.unwrap().kind, "InvalidArgument");
        let mut op = streaming_profile(b"3.1.0").piv_import_pq_seed(0x96, 0, vec![7; 32], 0, 0);
        assert_eq!(op.start().error.unwrap().kind, "InvalidArgument");

        // PQ algorithms require evidenced support; unobserved IDs fail fast.
        let mut op = metadata_profile().piv_import_pq_seed(0x9a, 0, vec![7; 32], 0, 0);
        assert!(op.start().error.is_some());
    }

    #[test]
    fn ndef_capability_and_message_reads_own_wire_bytes() {
        let cc = |write_access: u8| {
            let mut cc = vec![
                0x00,
                0x0f,
                0x20,
                0x00,
                0xff,
                0x00,
                0xff,
                0x04,
                0x06,
                0xe1,
                0x04,
                0x04,
                0x00,
                0x00,
                write_access,
            ];
            cc.extend([0x90, 0]);
            cc
        };
        let mut op = ProtocolOperation::ndef_read_capability();
        assert_eq!(
            op.start().command.unwrap(),
            [0, 0xa4, 4, 0, 7, 0xd2, 0x76, 0, 0, 0x85, 1, 1]
        );
        assert_eq!(
            op.advance(vec![0x90, 0]).command.unwrap(),
            [0, 0xa4, 0, 0x0c, 2, 0xe1, 0x03]
        );
        assert_eq!(
            op.advance(vec![0x90, 0]).command.unwrap(),
            [0, 0xb0, 0, 0, 15]
        );
        // Max file size 0x0400 clamps to the 1022-byte message maximum.
        assert_eq!(op.advance(cc(0)).data.unwrap(), [0x03, 0xfe, 0]);
        let mut op = ProtocolOperation::ndef_read_capability();
        op.start();
        op.advance(vec![0x90, 0]);
        op.advance(vec![0x90, 0]);
        assert_eq!(op.advance(cc(1)).data.unwrap(), [0x03, 0xfe, 1]);

        // 6A82 during selection is an absent/disabled applet; a malformed CC
        // is a parsing failure, never invented limits.
        let mut op = ProtocolOperation::ndef_read_capability();
        op.start();
        let error = op.advance(vec![0x6a, 0x82]).error.unwrap();
        assert_eq!(error.kind, "UnsupportedDevice");
        assert_eq!(error.phase, "Select");
        let mut op = ProtocolOperation::ndef_read_capability();
        op.start();
        op.advance(vec![0x90, 0]);
        op.advance(vec![0x90, 0]);
        let mut malformed_cc = vec![0; 15];
        malformed_cc.extend([0x90, 0]);
        let error = op.advance(malformed_cc).error.unwrap();
        assert_eq!(error.kind, "InvalidResponse");

        // Message read: NLEN then the message from offset two; NLEN zero ends.
        let mut op = ProtocolOperation::ndef_read_message();
        op.start();
        op.advance(vec![0x90, 0]);
        op.advance(vec![0x90, 0]);
        assert_eq!(
            op.advance(cc(0)).command.unwrap(),
            [0, 0xa4, 0, 0x0c, 2, 0, 1]
        );
        assert_eq!(
            op.advance(vec![0x90, 0]).command.unwrap(),
            [0, 0xb0, 0, 0, 2]
        );
        assert_eq!(
            op.advance(vec![0, 3, 0x90, 0]).command.unwrap(),
            [0, 0xb0, 0, 2, 3]
        );
        assert_eq!(op.advance(vec![1, 2, 3, 0x90, 0]).data.unwrap(), [1, 2, 3]);
    }

    #[test]
    fn ndef_write_is_crash_safe_three_phase_and_bounded() {
        let mut op = ProtocolOperation::ndef_write_message(b"hi".to_vec());
        assert_eq!(
            op.start().command.unwrap(),
            [0, 0xa4, 4, 0, 7, 0xd2, 0x76, 0, 0, 0x85, 1, 1]
        );
        assert_eq!(
            op.advance(vec![0x90, 0]).command.unwrap(),
            [0, 0xa4, 0, 0x0c, 2, 0, 1]
        );
        // Zero NLEN first: an interrupted write leaves no stale message.
        assert_eq!(
            op.advance(vec![0x90, 0]).command.unwrap(),
            [0, 0xd6, 0, 0, 2, 0, 0]
        );
        assert_eq!(
            op.advance(vec![0x90, 0]).command.unwrap(),
            [0, 0xd6, 0, 2, 2, b'h', b'i']
        );
        assert_eq!(
            op.advance(vec![0x90, 0]).command.unwrap(),
            [0, 0xd6, 0, 0, 2, 0, 2]
        );
        assert_eq!(op.advance(vec![0x90, 0]).data.unwrap(), Vec::<u8>::new());

        // A read-only file is the card's 6982, never a host-side guess.
        let mut op = ProtocolOperation::ndef_write_message(b"hi".to_vec());
        op.start();
        op.advance(vec![0x90, 0]);
        op.advance(vec![0x90, 0]);
        let error = op.advance(vec![0x69, 0x82]).error.unwrap();
        assert_eq!(error.kind, "SecurityStatusNotSatisfied");

        // Messages beyond the firmware maximum fail before any I/O.
        let mut op = ProtocolOperation::ndef_write_message(vec![0; 1023]);
        assert_eq!(op.start().error.unwrap().kind, "InvalidArgument");
    }

    #[test]
    fn ctap_transceive_selects_continues_and_preserves_status() {
        let mut op = ProtocolOperation::ctap_transceive(vec![4]);
        assert_eq!(
            op.start().command.unwrap(),
            [0, 0xa4, 4, 0, 8, 0xa0, 0, 0, 6, 0x47, 0x2f, 0, 1]
        );
        assert_eq!(
            op.advance(vec![0x90, 0]).command.unwrap(),
            [0x80, 0x10, 0, 0, 1, 4]
        );
        // ISO7816 continuation uses GET RESPONSE with the CTAP class byte.
        assert_eq!(
            op.advance(vec![0x61, 2]).command.unwrap(),
            [0x80, 0xc0, 0, 0, 2]
        );
        // A non-success CTAP status byte is data, not a protocol error.
        assert_eq!(op.advance(vec![0x2e, 1, 0x90, 0]).data.unwrap(), [0x2e, 1]);
        assert_eq!(op.start().error.unwrap().kind, "OperationStateError");

        // transceive_selected sends no SELECT of its own; an empty success
        // reply without a CTAP status byte is malformed.
        let mut op = ProtocolOperation::ctap_transceive_selected(vec![4]);
        assert_eq!(op.start().command.unwrap(), [0x80, 0x10, 0, 0, 1, 4]);
        let error = op.advance(vec![0x90, 0]).error.unwrap();
        assert_eq!(error.kind, "InvalidResponse");

        // select_application emits only SELECT; 6A82 is an absent FIDO2 applet.
        let mut op = ProtocolOperation::ctap_select_application();
        assert_eq!(
            op.start().command.unwrap(),
            [0, 0xa4, 4, 0, 8, 0xa0, 0, 0, 6, 0x47, 0x2f, 0, 1]
        );
        assert_eq!(op.advance(vec![0x90, 0]).data.unwrap(), Vec::<u8>::new());
        let mut op = ProtocolOperation::ctap_select_application();
        op.start();
        let error = op.advance(vec![0x6a, 0x82]).error.unwrap();
        assert_eq!(error.kind, "UnsupportedDevice");
        assert_eq!(error.phase, "Select");

        // An empty CTAP message fails before any I/O.
        let mut op = ProtocolOperation::ctap_transceive(vec![]);
        assert_eq!(op.start().error.unwrap().kind, "InvalidArgument");
    }
}

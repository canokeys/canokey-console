use super::*;

impl ProtocolProfile {
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
                    let profile = self.profile()?;
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
    pub(super) fn admin_operation(
        &self,
        request: Result<admin::Request, Error>,
        pin: Option<Vec<u8>>,
        existing: bool,
    ) -> ProtocolOperation {
        let pin = pin.map(SecretBytes::new);
        self.operation(|profile| {
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
        })
    }
}

pub(super) fn admin_progress(outcome: &admin::Outcome) -> AdminProgress {
    AdminProgress {
        confirmed_writes: outcome.confirmed_writes as u32,
        reprobe_required: outcome.reprobe_required,
    }
}

pub(super) fn admin_result(outcome: admin::Outcome) -> AdminResult {
    let progress = admin_progress(&outcome);
    let mut pass_slots = None;
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
        Value::PassSlots(v) => {
            pass_slots = Some([v.short, v.long].into_iter().map(pass_slot).collect());
            (AdminValueKind::PassSlots, vec![])
        }
    };
    AdminResult {
        kind,
        data,
        progress,
        pass_slots,
    }
}

pub(super) fn pass_slot(slot: admin::PassSlotState) -> PassSlotData {
    use admin::PassSlotState;
    let (kind, name, append_enter) = match slot {
        PassSlotState::Off => (0, vec![], false),
        PassSlotState::Static { append_enter } => (2, vec![], append_enter),
        PassSlotState::HmacSha1 => (3, vec![], false),
        PassSlotState::Oath { name, append_enter } => (1, name, append_enter),
        PassSlotState::Unknown(kind) => (kind, vec![], false),
    };
    PassSlotData {
        kind,
        name,
        append_enter,
    }
}

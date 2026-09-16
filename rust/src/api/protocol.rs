//! Owned libcanokey operations. Dart owns the selected connection and every I/O.
mod admin_ops;
mod ctap_ops;
mod oath_ops;
mod openpgp_ops;
mod piv_ops;

use admin_ops::*;
use ctap_ops::*;
use oath_ops::*;

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
pub struct PassSlotData {
    pub kind: u8,
    pub name: Vec<u8>,
    pub append_enter: bool,
}

pub struct AdminStorageUsage {
    pub used_ki_b: u8,
    pub total_ki_b: u8,
}

pub struct AdminAppletUsage {
    pub applet_id: u8,
    pub flags: u8,
    pub logical_bytes: u32,
}

pub struct NdefCapabilityData {
    pub max_message_length: u16,
    pub read_only: bool,
}

pub struct AdminResult {
    pub kind: AdminValueKind,
    pub data: Vec<u8>,
    pub progress: AdminProgress,
    pub pass_slots: Option<Vec<PassSlotData>>,
    pub flash_usage: Option<AdminStorageUsage>,
    pub applet_usage: Option<Vec<AdminAppletUsage>>,
}

/// Structured, payload-free protocol failure. Transport errors remain in Dart.
/// For CTAP-level failures `status_word` carries the raw CTAP status byte
/// widened to u16 (for example 0x0031 for PIN_INVALID), NOT an ISO 7816
/// status word; see canokey-ctap's status table. Upstream keeps that byte in
/// `Error::application_status` (`status_word` is ISO-only); the bridge maps it
/// here so the Dart contract is unchanged.
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
            status_word: match error.application_status {
                Some(status) => Some(u16::from(status)),
                None => error.status_word.map(|sw| sw.raw()),
            },
            reference: error.reference.map(|reference| format!("{reference:?}")),
            retries_remaining: error.retries_remaining,
        }
    }
}

/// Exactly one field is present: exchange a command, consume a result, or fail.
/// Command and result copies belong to Dart; getters never perform I/O.
#[derive(Default)]
pub struct ProtocolStep {
    pub command: Option<Vec<u8>>,
    pub data: Option<Vec<u8>>,
    pub error: Option<ProtocolError>,
    pub profile: Option<ProtocolProfile>,
    pub admin: Option<AdminResult>,
    pub pin_session: Option<CtapPinSession>,
    pub pin_token: Option<CtapPinToken>,
    pub oath_selection: Option<OathSelectionData>,
    pub oath_calculations: Option<Vec<OathCalculation>>,
    pub ctap_info: Option<CtapInfo>,
    pub ndef_capability: Option<NdefCapabilityData>,
    pub ctap_rps: Option<Vec<CtapRp>>,
    pub ctap_credentials: Option<Vec<CtapCredential>>,
}

impl ProtocolStep {
    fn failure(error: Error) -> Self {
        Self {
            error: Some(error.into()),
            ..Default::default()
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
    Oath(Operation<oath::Outcome>),
    OpenPgp(Operation<openpgp::Outcome>),
    Credential(Operation<piv::MutationResult>),
    Management(Operation<()>),
    Admin(Operation<admin::Outcome>),
    BootstrapSelect(Operation<ResponseData>),
    BootstrapSerial(Operation<ResponseData>),
    NdefCapability(Operation<ndef::NdefCapability>),
    NdefMessage(Operation<ndef::NdefMessage>),
    CtapGetInfo(Operation<ctap::AuthenticatorInfo>),
    CtapPinSession(Operation<ctap::PinSession>),
    CtapPinToken(Operation<ctap::PinToken>, ctap::PinUvAuthProtocol),
    CtapRps(Operation<Vec<ctap::credmgmt::RpEntry>>),
    CtapCredentials(Operation<Vec<ctap::credmgmt::CredentialEntry>>),
}

/// Immutable observations of one device. Dart binds this owner to a card lease.
/// It is not an authentication token; constructors copy their required evidence.
#[flutter_rust_bridge::frb(opaque)]
pub struct ProtocolProfile {
    inner: Option<canokey::DeviceProfile>,
}

impl ProtocolProfile {
    fn operation(
        &self,
        build: impl FnOnce(&canokey::DeviceProfile) -> Result<Inner, Error>,
    ) -> ProtocolOperation {
        ProtocolOperation::from_operation(self.profile().and_then(build))
    }

    fn profile(&self) -> Result<&canokey::DeviceProfile, Error> {
        self.inner
            .as_ref()
            .ok_or_else(|| Error::new(ErrorKind::OperationStateError))
    }

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

    /// The serial observed during explicit discovery. Missing observations stay absent.
    #[flutter_rust_bridge::frb(sync)]
    pub fn serial(&self) -> Option<Vec<u8>> {
        self.inner.as_ref()?.info().serial().map(<[u8]>::to_vec)
    }

    /// Idempotent local cleanup. Does not alter the card or already-created ops.
    #[flutter_rust_bridge::frb(sync)]
    pub fn close(&mut self) {
        self.inner.take();
    }
}

/// OATH selection evidence, including legacy serial observations.
pub struct OathSelectionData {
    pub version: Option<Vec<u8>>,
    pub salt: Option<Vec<u8>>,
    pub challenge: Option<Vec<u8>>,
    pub serial: Option<Vec<u8>>,
}

pub enum OathCode {
    Truncated,
    Full,
    Hotp,
    TouchRequired,
}

pub struct OathCalculation {
    pub name: Option<Vec<u8>>,
    pub digits: u8,
    pub code: OathCode,
    pub raw_code: Option<u32>,
    pub full_code: Option<Vec<u8>>,
}

pub struct CtapInfo {
    pub cred_mgmt: Option<bool>,
    pub client_pin: Option<bool>,
    pub force_pin_change: Option<bool>,
    pub min_pin_length: Option<u64>,
    pub pin_uv_auth_protocols: Vec<u8>,
}

pub struct CtapRp {
    pub id: String,
    pub name: Option<String>,
    pub id_hash: Vec<u8>,
}

pub struct CtapCredential {
    pub credential_id: Vec<u8>,
    pub user_id: Option<Vec<u8>>,
    pub user_name: Option<String>,
    pub user_display_name: Option<String>,
    pub cred_protect: Option<u8>,
    pub cose_algorithm: Option<i64>,
    pub public_key: Option<Vec<u8>>,
}

/// A CTAP2 ClientPIN key-agreement session (P-256 ECDH). The shared secret
/// lives only in this zeroizing Rust owner and never crosses the bridge.
/// Dart holds the handle between operations; `close` is idempotent local
/// cleanup and sends nothing.
#[flutter_rust_bridge::frb(opaque)]
pub struct CtapPinSession {
    inner: Option<ctap::PinSession>,
    protocol: ctap::PinUvAuthProtocol,
}

/// A decrypted pinUvAuthToken held only in zeroizing Rust memory; the raw
/// token bytes never cross the bridge. Per CTAP 2.1 tokens are
/// ceremony-scoped: obtain a fresh one per use instead of caching the handle.
#[flutter_rust_bridge::frb(opaque)]
pub struct CtapPinToken {
    inner: Option<ctap::PinToken>,
    protocol: ctap::PinUvAuthProtocol,
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
    /// Admin-only discovery before authentication; does not select PIV. A
    /// four-byte serial already observed by the connection bootstrap is
    /// recorded as the probe observation and the serial read is skipped.
    #[flutter_rust_bridge::frb(sync)]
    pub fn probe_admin(observed_serial: Option<Vec<u8>>) -> Self {
        Self::from_operation(
            observed_serial
                .map(|s| {
                    <[u8; 4]>::try_from(s.as_slice())
                        .map_err(|_| Error::new(ErrorKind::InvalidArgument))
                })
                .transpose()
                .and_then(|observed_serial| {
                    canokey::probe_device(canokey::ProbeOptions {
                        mode: canokey::ProbeMode::Minimal,
                        observed_serial,
                        ..Default::default()
                    })
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
    /// A bootstrap-observed serial skips the duplicate serial read.
    #[flutter_rust_bridge::frb(sync)]
    pub fn probe_piv(observed_serial: Option<Vec<u8>>) -> Self {
        Self::from_operation(
            observed_serial
                .map(|s| {
                    <[u8; 4]>::try_from(s.as_slice())
                        .map_err(|_| Error::new(ErrorKind::InvalidArgument))
                })
                .transpose()
                .and_then(|observed_serial| {
                    canokey::probe_device(canokey::ProbeOptions {
                        observed_serial,
                        ..Default::default()
                    })
                })
                .map(Inner::Probe),
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
        };
        Self::from_operation(operation)
    }

    /// Profile-free NDEF capability-container read. Selects the NDEF applet.
    /// Returns the maximum message length (excluding NLEN) and write protection.
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

    /// authenticatorGetInfo (0x04), profile-free with its own SELECT. The
    /// final `data` carries the parsed fields Dart needs (credMgmt/clientPin
    /// tri-states, forcePinChange, minPinLength, advertised pinUvAuthProtocol
    /// versions) as typed fields.
    #[flutter_rust_bridge::frb(sync)]
    pub fn ctap_get_info() -> Self {
        Self::from_operation(ctap::get_info(OperationOptions::default()).map(Inner::CtapGetInfo))
    }

    /// Start ClientPIN key agreement (subcommand 0x02) for protocol version
    /// 1 or 2, generating the ephemeral P-256 scalar from the CSPRNG. The
    /// final step carries an opaque [`CtapPinSession`] handle.
    #[flutter_rust_bridge::frb(sync)]
    pub fn ctap_begin_pin_session(protocol: u8) -> Self {
        let operation = (|| {
            let protocol = ctap::PinUvAuthProtocol::from_u8(protocol)
                .ok_or_else(|| Error::new(ErrorKind::InvalidArgument))?;
            // A random scalar that is zero or out of range is rejected by the
            // upstream factory before any I/O; simply draw again.
            let mut last_error = None;
            for _ in 0..4 {
                let mut scalar = [0u8; 32];
                rand::fill(&mut scalar);
                match ctap::get_key_agreement(protocol, &scalar, OperationOptions::default()) {
                    Ok(operation) => return Ok(operation),
                    Err(error) if error.kind == ErrorKind::InvalidArgument => {
                        last_error = Some(error)
                    }
                    Err(error) => return Err(error),
                }
            }
            Err(last_error.unwrap_or_else(|| Error::new(ErrorKind::InvalidArgument)))
        })();
        Self::from_operation(operation.map(Inner::CtapPinSession))
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
                admin: Some(admin_result(outcome)),
                ..Default::default()
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
            Some(Inner::Oath(op)) => drive(op, response, oath_result),
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
                profile: Some(ProtocolProfile {
                    inner: Some(profile),
                }),
                ..Default::default()
            }),
            Some(Inner::NdefCapability(op)) => drive(op, response, |capability| ProtocolStep {
                ndef_capability: Some(NdefCapabilityData {
                    max_message_length: capability.max_message_length.min(usize::from(u16::MAX))
                        as u16,
                    read_only: capability.read_only,
                }),
                ..Default::default()
            }),
            Some(Inner::NdefMessage(op)) => {
                drive(op, response, |message| bytes(message.as_bytes().to_vec()))
            }
            Some(Inner::CtapGetInfo(op)) => drive(op, response, ctap_info),
            Some(Inner::CtapPinSession(op)) => drive(op, response, |session| ProtocolStep {
                pin_session: Some(CtapPinSession::new(session)),
                ..Default::default()
            }),
            Some(Inner::CtapPinToken(op, protocol)) => {
                let protocol = *protocol;
                drive(op, response, |token| ProtocolStep {
                    pin_token: Some(CtapPinToken::new(token, protocol)),
                    ..Default::default()
                })
            }
            Some(Inner::CtapRps(op)) => drive(op, response, |entries| ProtocolStep {
                ctap_rps: Some(
                    entries
                        .into_iter()
                        .map(|entry| CtapRp {
                            id: entry.rp.id,
                            name: entry.rp.name,
                            id_hash: entry.rp_id_hash.to_vec(),
                        })
                        .collect(),
                ),
                ..Default::default()
            }),
            Some(Inner::CtapCredentials(op)) => drive(op, response, ctap_credentials),
            None => Err(Error::new(ErrorKind::OperationStateError)),
        };
        result.unwrap_or_else(ProtocolStep::failure)
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
            ..Default::default()
        },
        Step::Done => encode(op.take_result()?),
    })
}

fn bytes(data: Vec<u8>) -> ProtocolStep {
    ProtocolStep {
        data: Some(data),
        ..Default::default()
    }
}

#[cfg(test)]
mod tests;

//! Owned libcanokey operations. Dart owns the selected connection and every I/O.
use std::sync::Mutex;

use canokey::{piv, Error, ErrorKind, Operation, OperationOptions, SecretBytes, Step};

/// Initial PIV operations; reads require an already selected PIV application.
#[derive(Clone, Copy)]
pub enum PivReadOperation {
    Select,
    Version,
    AlgorithmConfiguration,
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
}

impl ProtocolStep {
    fn failure(error: Error) -> Self {
        Self {
            command: None,
            data: None,
            error: Some(error.into()),
        }
    }
}

enum Inner {
    Bytes(Operation<SecretBytes>),
    Configuration(Operation<canokey::compatibility::AlgorithmConfig>),
}

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
    /// Construct without I/O. Only Select changes applet selection; reads never
    /// probe, SELECT, authenticate, or retain a device profile implicitly.
    #[flutter_rust_bridge::frb(sync)]
    pub fn piv_read(kind: PivReadOperation) -> Self {
        let options = OperationOptions::default();
        let operation = match kind {
            PivReadOperation::Select => piv::select_application(options).map(Inner::Bytes),
            PivReadOperation::Version => piv::read_version_selected(options).map(Inner::Bytes),
            PivReadOperation::AlgorithmConfiguration => {
                piv::read_configuration_selected(options).map(Inner::Configuration)
            }
        };
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
            Some(Inner::Bytes(op)) => drive(op, response, |data| data.as_bytes().to_vec()),
            Some(Inner::Configuration(op)) => drive(op, response, |data| data.raw().to_vec()),
            None => Err(Error::new(ErrorKind::OperationStateError)),
        };
        result.unwrap_or_else(ProtocolStep::failure)
    }
}

fn drive<T>(
    op: &mut Operation<T>,
    response: Option<&[u8]>,
    encode: impl FnOnce(T) -> Vec<u8>,
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
        },
        Step::Done => ProtocolStep {
            command: None,
            data: Some(encode(op.take_result()?)),
            error: None,
        },
    })
}

#[cfg(test)]
mod tests {
    use super::*;

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
}

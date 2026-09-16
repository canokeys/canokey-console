use super::*;

impl CtapPinSession {
    pub(super) fn new(session: ctap::PinSession) -> Self {
        Self {
            protocol: session.protocol(),
            inner: Some(session),
        }
    }

    /// The pin/UV auth protocol version (1 or 2) this session speaks.
    /// Dart picks it from getInfo's advertised pinUvAuthProtocols.
    #[flutter_rust_bridge::frb(sync)]
    pub fn protocol_version(&self) -> u8 {
        self.protocol.to_u8()
    }

    /// Set the initial PIN (subcommand 0x03). V2 IVs are generated here from
    /// the CSPRNG; PIN bytes enter upstream zeroizing owners immediately.
    #[flutter_rust_bridge::frb(sync)]
    pub fn set_pin(&self, new_pin: Vec<u8>) -> ProtocolOperation {
        self.set_pin_with_iv(SecretBytes::new(new_pin), pin_iv(self.protocol))
    }

    pub(super) fn set_pin_with_iv(
        &self,
        new_pin: SecretBytes,
        iv: Option<[u8; 16]>,
    ) -> ProtocolOperation {
        ProtocolOperation::from_operation((|| {
            let session = self
                .inner
                .as_ref()
                .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
            ctap::set_pin(
                session,
                new_pin.as_bytes(),
                iv.as_ref(),
                OperationOptions::default(),
            )
            .map(Inner::Management)
        })())
    }

    /// Change the PIN (subcommand 0x04); IV handling matches [`Self::set_pin`].
    #[flutter_rust_bridge::frb(sync)]
    pub fn change_pin(&self, old_pin: Vec<u8>, new_pin: Vec<u8>) -> ProtocolOperation {
        self.change_pin_with_iv(
            SecretBytes::new(old_pin),
            SecretBytes::new(new_pin),
            pin_iv(self.protocol),
        )
    }

    pub(super) fn change_pin_with_iv(
        &self,
        old_pin: SecretBytes,
        new_pin: SecretBytes,
        iv: Option<[u8; 16]>,
    ) -> ProtocolOperation {
        ProtocolOperation::from_operation((|| {
            let session = self
                .inner
                .as_ref()
                .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
            ctap::change_pin(
                session,
                old_pin.as_bytes(),
                new_pin.as_bytes(),
                iv.as_ref(),
                OperationOptions::default(),
            )
            .map(Inner::Management)
        })())
    }

    /// Obtain a pinUvAuthToken with explicit permissions (subcommand 0x09):
    /// `permissions` is the raw bitfield (credentialManagement = 0x04) and
    /// `rp_id`, when present, binds the token to that relying party. The
    /// decrypted token is returned as an opaque handle in the final step.
    #[flutter_rust_bridge::frb(sync)]
    pub fn get_pin_token_with_permissions(
        &self,
        pin: Vec<u8>,
        permissions: u8,
        rp_id: Option<String>,
    ) -> ProtocolOperation {
        self.pin_token_with_iv(
            SecretBytes::new(pin),
            permissions,
            rp_id,
            pin_iv(self.protocol),
        )
    }

    pub(super) fn pin_token_with_iv(
        &self,
        pin: SecretBytes,
        permissions: u8,
        rp_id: Option<String>,
        iv: Option<[u8; 16]>,
    ) -> ProtocolOperation {
        let protocol = self.protocol;
        ProtocolOperation::from_operation((|| {
            let session = self
                .inner
                .as_ref()
                .ok_or_else(|| Error::new(ErrorKind::OperationStateError))?;
            ctap::get_pin_token_with_permissions(
                session,
                pin.as_bytes(),
                ctap::Permissions::from_bits(permissions),
                rp_id.as_deref(),
                iv.as_ref(),
                OperationOptions::default(),
            )
            .map(|operation| Inner::CtapPinToken(operation, protocol))
        })())
    }

    /// Idempotent local cleanup. Does not alter the card or pending operations.
    #[flutter_rust_bridge::frb(sync)]
    pub fn close(&mut self) {
        self.inner.take();
    }
}

impl CtapPinToken {
    pub(super) fn new(token: ctap::PinToken, protocol: ctap::PinUvAuthProtocol) -> Self {
        Self {
            inner: Some(token),
            protocol,
        }
    }

    /// The pin/UV auth protocol version (1 or 2) of the session that minted
    /// this token; credmgmt operations authenticate with it.
    #[flutter_rust_bridge::frb(sync)]
    pub fn protocol_version(&self) -> u8 {
        self.protocol.to_u8()
    }

    pub(super) fn token(&self) -> Result<&ctap::PinToken, Error> {
        self.inner
            .as_ref()
            .ok_or_else(|| Error::new(ErrorKind::OperationStateError))
    }

    /// Enumerate relying parties with resident credentials (Begin + GetNext
    /// run inside the one operation). A 0x2E NO_CREDENTIALS status yields an
    /// empty result, not an error. Returns typed relying parties.
    #[flutter_rust_bridge::frb(sync)]
    pub fn enumerate_rps(&self) -> ProtocolOperation {
        ProtocolOperation::from_operation(self.token().and_then(|token| {
            ctap::credmgmt::enumerate_rps(token, self.protocol, OperationOptions::default())
                .map(Inner::CtapRps)
        }))
    }

    /// Enumerate one RP's resident credentials. `metadata_only` enables the
    /// CanoKey vendor extension (subCommandParams key 0x80): the raw COSE
    /// algorithm replaces the public key in typed credential results.
    /// A Begin 0x2E yields an empty result.
    #[flutter_rust_bridge::frb(sync)]
    pub fn enumerate_credentials(
        &self,
        rp_id_hash: Vec<u8>,
        metadata_only: bool,
    ) -> ProtocolOperation {
        ProtocolOperation::from_operation((|| {
            let hash: [u8; 32] = rp_id_hash
                .try_into()
                .map_err(|_| Error::new(ErrorKind::InvalidArgument))?;
            ctap::credmgmt::enumerate_credentials(
                self.token()?,
                self.protocol,
                hash,
                metadata_only,
                OperationOptions::default(),
            )
            .map(Inner::CtapCredentials)
        })())
    }

    /// Permanently delete one resident credential by its raw credential ID
    /// (sent as a `public-key` descriptor). Never retried or rolled back;
    /// an unknown ID surfaces as NotFound (CTAP 0x2E/0x22).
    #[flutter_rust_bridge::frb(sync)]
    pub fn delete_credential(&self, credential_id: Vec<u8>) -> ProtocolOperation {
        ProtocolOperation::from_operation((|| {
            let descriptor = ctap::PublicKeyCredentialDescriptor::new("public-key", credential_id);
            ctap::credmgmt::delete_credential(
                self.token()?,
                self.protocol,
                &descriptor,
                OperationOptions::default(),
            )
            .map(Inner::Management)
        })())
    }

    /// Idempotent local cleanup. Does not alter the card or pending operations.
    #[flutter_rust_bridge::frb(sync)]
    pub fn close(&mut self) {
        self.inner.take();
    }
}

pub(super) fn ctap_info(info: ctap::AuthenticatorInfo) -> ProtocolStep {
    let option = |name: &str| {
        info.options()
            .and_then(|options| options.iter().find(|(key, _)| key == name).map(|(_, v)| *v))
    };
    ProtocolStep {
        ctap_info: Some(CtapInfo {
            cred_mgmt: option("credMgmt"),
            client_pin: option("clientPin"),
            force_pin_change: info.force_pin_change(),
            min_pin_length: info.min_pin_length(),
            pin_uv_auth_protocols: info.pin_uv_auth_protocols().unwrap_or(&[]).to_vec(),
        }),
        ..Default::default()
    }
}

pub(super) fn ctap_credentials(entries: Vec<ctap::credmgmt::CredentialEntry>) -> ProtocolStep {
    let result = entries
        .into_iter()
        .map(|entry| {
            let (user_id, user_name, user_display_name) = match entry.user {
                Some(user) => (Some(user.id), user.name, user.display_name),
                None => (None, None, None),
            };
            Ok(CtapCredential {
                credential_id: entry.credential_id.id,
                user_id,
                user_name,
                user_display_name,
                cred_protect: entry.cred_protect.map(|policy| policy as u8),
                cose_algorithm: entry.cose_algorithm.or_else(|| {
                    entry
                        .public_key
                        .as_ref()
                        .and_then(|key| key.algorithm().map(|a| a.id()))
                }),
                public_key: entry
                    .public_key
                    .map(|key| ctap::cbor::encode(&key.to_value()))
                    .transpose()?,
            })
        })
        .collect::<Result<Vec<_>, Error>>();
    match result {
        Ok(entries) => ProtocolStep {
            ctap_credentials: Some(entries),
            ..Default::default()
        },
        Err(error) => ProtocolStep::failure(error),
    }
}

/// Fresh V2 IV (16 CSPRNG bytes); protocol V1 uses the spec-mandated zero
/// IV, which the upstream API expresses as `None`.
pub(super) fn pin_iv(protocol: ctap::PinUvAuthProtocol) -> Option<[u8; 16]> {
    if protocol == ctap::PinUvAuthProtocol::V2 {
        let mut iv = [0u8; 16];
        rand::fill(&mut iv);
        Some(iv)
    } else {
        None
    }
}

use super::*;

impl ProtocolProfile {
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
        self.operation(|profile| {
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
            };
            piv::credential(profile, action, false, OperationOptions::default())
                .map(Inner::Credential)
        })
    }

    /// Preserve Console's explicit external authentication mode. libcanokey owns
    /// the full challenge exchange and cryptography; no host login is inferred.
    #[flutter_rust_bridge::frb(sync)]
    pub fn piv_authenticate_management(&self, algorithm: u8, key: Vec<u8>) -> ProtocolOperation {
        let key = SecretBytes::new(key);
        self.operation(|profile| {
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
        })
    }

    /// Read the PIV algorithm extension configuration (INS EE). Without a
    /// management key this reuses the caller's selected transaction
    /// (`Access::Existing`); with one, upstream SELECTs, authenticates
    /// (external GENERAL AUTHENTICATE) and reads within the same operation.
    /// On 3.0.x firmware (`PivProtectedAlgorithmConfigRead`) an
    /// unauthenticated read is rejected with SecurityStatusNotSatisfied; on
    /// firmware without the read the capability check fails at construction,
    /// before any authentication I/O.
    #[flutter_rust_bridge::frb(sync)]
    pub fn piv_read_algorithm_config(
        &self,
        management_key: Option<Vec<u8>>,
        management_key_algorithm: u8,
    ) -> ProtocolOperation {
        let management_key = management_key.map(SecretBytes::new);
        self.operation(|profile| {
            let access = match management_key {
                None => piv::Access::Existing,
                Some(key) => {
                    let algorithm = match management_key_algorithm {
                        0x03 => piv::ManagementKeyAlgorithm::Tdes,
                        0x0a => piv::ManagementKeyAlgorithm::Aes192,
                        _ => return Err(Error::new(ErrorKind::UnsupportedAlgorithm)),
                    };
                    let key = piv::ManagementKey::from_bytes(algorithm, key.as_bytes())?;
                    piv::Access::Management(piv::ManagementAuthentication::external(key))
                }
            };
            piv::read_algorithm_config(profile, access, OperationOptions::default())
                .map(Inner::Configuration)
        })
    }
    /// Read metadata in the caller's already selected PIV session. No probing,
    /// SELECT or authentication is inserted, including after VERIFY.
    #[flutter_rust_bridge::frb(sync)]
    pub fn piv_metadata(&self, reference: u8) -> ProtocolOperation {
        self.operation(|profile| {
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
        })
    }

    /// Read the PIV metadata directory in the caller's selected transaction.
    /// The upstream parser validates framing and preserves the raw directory.
    #[flutter_rust_bridge::frb(sync)]
    pub fn piv_metadata_directory(&self) -> ProtocolOperation {
        self.operation(|profile| {
            piv::read_metadata_directory(
                profile,
                piv::Access::Existing,
                OperationOptions::default(),
            )
            .map(Inner::Directory)
        })
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn piv_generate_key(
        &self,
        slot: u8,
        algorithm: u8,
        pin_policy: u8,
        touch_policy: u8,
    ) -> ProtocolOperation {
        self.operation(|profile| {
            let parameters = piv::KeyParameters {
                slot: piv_slot(slot)?,
                algorithm: profile
                    .algorithm_from_wire_id(algorithm)
                    .ok_or_else(|| Error::new(ErrorKind::UnsupportedAlgorithm))?,
                pin_policy: parse_pin_policy(pin_policy)?,
                touch_policy: parse_touch_policy(touch_policy)?,
            };
            piv::generate_key(
                profile,
                parameters,
                piv::Access::Existing,
                OperationOptions::default(),
            )
            .map(Inner::PublicKey)
        })
    }

    /// Reuse the caller's selected transaction; the profile is evidence only.
    #[flutter_rust_bridge::frb(sync)]
    pub fn piv_certificate(&self, object_id: u8) -> ProtocolOperation {
        self.operation(|profile| {
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
        })
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn piv_delete_key(&self, slot: u8) -> ProtocolOperation {
        self.operation(|profile| {
            piv::delete_key(
                profile,
                piv_slot(slot)?,
                piv::Access::Existing,
                OperationOptions::default(),
            )
            .map(Inner::Credential)
        })
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn piv_move_key(&self, source: u8, target: u8) -> ProtocolOperation {
        self.operation(|profile| {
            piv::move_key(
                profile,
                piv_slot(source)?,
                piv_slot(target)?,
                piv::Access::Existing,
                OperationOptions::default(),
            )
            .map(Inner::Credential)
        })
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
        self.operation(|profile| {
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
        })
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn piv_set_algorithm_config(&self, raw: Vec<u8>) -> ProtocolOperation {
        self.operation(|profile| {
            let config = canokey::compatibility::AlgorithmConfig::parse(&raw)?;
            piv::set_algorithm_config(
                profile,
                config,
                piv::Access::Existing,
                OperationOptions::default(),
            )
            .map(Inner::Credential)
        })
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn piv_reset_pin_puk_retries(&self, pin_retries: u8, puk_retries: u8) -> ProtocolOperation {
        self.operation(|profile| {
            piv::reset_pin_puk_retries(
                profile,
                pin_retries,
                puk_retries,
                piv::Access::Existing,
                OperationOptions::default(),
            )
            .map(Inner::Credential)
        })
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
        self.operation(|profile| {
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
        })
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn piv_derive(&self, slot: u8, algorithm: u8, peer: Vec<u8>) -> ProtocolOperation {
        self.operation(|profile| {
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
        })
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn piv_decapsulate(&self, slot: u8, ciphertext: Vec<u8>) -> ProtocolOperation {
        let ciphertext = SecretBytes::new(ciphertext);
        self.operation(|profile| {
            piv::decapsulate(
                profile,
                piv_slot(slot)?,
                ciphertext,
                piv::Access::Existing,
                OperationOptions::default(),
            )
            .map(Inner::Bytes)
        })
    }

    /// INS F9 attestation certificate for a generated slot. The selected-context
    /// factory asserts no credential and consumes no authentication state.
    #[flutter_rust_bridge::frb(sync)]
    pub fn piv_attest(&self, slot: u8) -> ProtocolOperation {
        self.operation(|profile| {
            piv::attest(profile, piv_slot(slot)?, false, OperationOptions::default())
                .map(Inner::Bytes)
        })
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
        self.operation(|profile| {
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
        })
    }

    /// Import validated file material without round-tripping private components through Dart.
    #[flutter_rust_bridge::frb(sync)]
    pub fn piv_import_private_key(
        &self,
        slot: u8,
        algorithm: u8,
        key: &super::super::piv_crypto::PivPrivateKeyData,
        pin_policy: u8,
        touch_policy: u8,
    ) -> ProtocolOperation {
        self.operation(|profile| {
            if self.piv_algorithm_display_id(algorithm) != Some(key.algorithm()) {
                return Err(Error::new(ErrorKind::UnsupportedAlgorithm));
            }
            let algorithm = profile
                .algorithm_from_wire_id(algorithm)
                .ok_or_else(|| Error::new(ErrorKind::UnsupportedAlgorithm))?;
            let parameters = piv::KeyParameters {
                slot: piv_slot(slot)?,
                algorithm,
                pin_policy: parse_pin_policy(pin_policy)?,
                touch_policy: parse_touch_policy(touch_policy)?,
            };
            piv::import_key(
                profile,
                parameters,
                key.material(algorithm)?,
                piv::Access::Existing,
                OperationOptions::default(),
            )
            .map(Inner::Credential)
        })
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
        self.operation(|profile| {
            let material = match kind {
                0 => piv::PrivateKeyMaterial::mldsa65_seed(seed.as_bytes())?,
                1 => piv::PrivateKeyMaterial::mlkem768_seed(seed.as_bytes())?,
                _ => return Err(Error::new(ErrorKind::InvalidArgument)),
            };
            let parameters = piv::KeyParameters {
                slot: piv_slot(slot)?,
                algorithm: material.algorithm(),
                pin_policy: parse_pin_policy(pin_policy)?,
                touch_policy: parse_touch_policy(touch_policy)?,
            };
            piv::import_key(
                profile,
                parameters,
                material,
                piv::Access::Existing,
                OperationOptions::default(),
            )
            .map(Inner::Credential)
        })
    }

    /// Return the normalized object value. libcanokey owns framing and parsing.
    #[flutter_rust_bridge::frb(sync)]
    pub fn piv_read_object(&self, object_id: Vec<u8>) -> ProtocolOperation {
        self.operation(|profile| {
            piv::read_object(
                profile,
                piv::ObjectId::from_bytes(&object_id)?,
                piv::Access::Existing,
                OperationOptions::default(),
            )
            .map(Inner::Bytes)
        })
    }

    /// Writes may be partially applied before failure; never retry or roll back.
    /// Existing delegates authorization to the card in the caller-owned lease.
    #[flutter_rust_bridge::frb(sync)]
    pub fn piv_write_object(&self, object_id: Vec<u8>, data: Vec<u8>) -> ProtocolOperation {
        let data = SecretBytes::new(data);
        self.operation(|profile| {
            piv::write_object(
                profile,
                piv::ObjectId::from_bytes(&object_id)?,
                data,
                piv::Access::Existing,
                OperationOptions::default(),
            )
            .map(Inner::Credential)
        })
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
}

pub(super) fn parse_pin_policy(value: u8) -> Result<piv::PinPolicy, Error> {
    Ok(match value {
        0 => piv::PinPolicy::Default,
        1 => piv::PinPolicy::Never,
        2 => piv::PinPolicy::Once,
        3 => piv::PinPolicy::Always,
        _ => return Err(Error::new(ErrorKind::InvalidArgument)),
    })
}

pub(super) fn parse_touch_policy(value: u8) -> Result<piv::TouchPolicy, Error> {
    Ok(match value {
        0 => piv::TouchPolicy::Default,
        1 => piv::TouchPolicy::Never,
        2 => piv::TouchPolicy::Always,
        3 => piv::TouchPolicy::Cached,
        _ => return Err(Error::new(ErrorKind::InvalidArgument)),
    })
}

pub(super) fn piv_slot(reference: u8) -> Result<piv::Slot, Error> {
    match reference {
        0x9a => Ok(piv::Slot::Authentication),
        0x9c => Ok(piv::Slot::Signature),
        0x9d => Ok(piv::Slot::KeyManagement),
        0x9e => Ok(piv::Slot::CardAuthentication),
        0x82..=0x95 => piv::RetiredSlot::new(reference - 0x81).map(piv::Slot::Retired),
        _ => Err(Error::new(ErrorKind::InvalidArgument)),
    }
}

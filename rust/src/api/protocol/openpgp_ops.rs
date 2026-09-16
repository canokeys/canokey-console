use super::*;

impl ProtocolProfile {
    fn openpgp_admin(
        &self,
        password: Vec<u8>,
        request: impl FnOnce() -> Result<openpgp::Request, Error>,
    ) -> ProtocolOperation {
        let password = SecretBytes::new(password);
        self.operation(|profile| {
            let request = request()?;
            let password = openpgp::Password::from_bytes(password.as_bytes())?;
            openpgp::operation(
                profile,
                request,
                Some(openpgp::Access {
                    reference: openpgp::PasswordReference::Pw3,
                    password,
                }),
                OperationOptions::default(),
            )
            .map(Inner::OpenPgp)
        })
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn openpgp_logout(&self, reference: u8) -> ProtocolOperation {
        self.operation(|profile| {
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
        })
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn openpgp_read_data(&self, tag: u16) -> ProtocolOperation {
        self.operation(|profile| {
            openpgp::operation(
                profile,
                openpgp::Request::ReadData(tag),
                None,
                OperationOptions::default(),
            )
            .map(Inner::OpenPgp)
        })
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn openpgp_verify(&self, reference: u8, password: Vec<u8>) -> ProtocolOperation {
        let password = SecretBytes::new(password);
        self.operation(|profile| {
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
        })
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn openpgp_read_certificate(&self, slot: u8) -> ProtocolOperation {
        self.operation(|profile| {
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
        })
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
        self.operation(|profile| {
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
        })
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
        self.operation(|profile| {
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
        })
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn openpgp_pin_status(&self, reference: u8) -> ProtocolOperation {
        self.operation(|profile| {
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
        })
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn openpgp_write_name(&self, name: Vec<u8>, password: Vec<u8>) -> ProtocolOperation {
        self.openpgp_admin(password, || {
            Ok(openpgp::Request::WriteData(openpgp::DataWrite::Name(name)))
        })
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn openpgp_write_login(&self, login: Vec<u8>, password: Vec<u8>) -> ProtocolOperation {
        let login = SecretBytes::new(login);
        self.openpgp_admin(password, || {
            Ok(openpgp::Request::WriteData(openpgp::DataWrite::Login(
                login,
            )))
        })
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn openpgp_write_language(
        &self,
        language: Vec<u8>,
        password: Vec<u8>,
    ) -> ProtocolOperation {
        self.openpgp_admin(password, || {
            Ok(openpgp::Request::WriteData(openpgp::DataWrite::Language(
                language,
            )))
        })
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn openpgp_write_sex(&self, sex: u8, password: Vec<u8>) -> ProtocolOperation {
        self.openpgp_admin(password, || {
            Ok(openpgp::Request::WriteData(openpgp::DataWrite::Sex(sex)))
        })
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn openpgp_write_url(&self, url: Vec<u8>, password: Vec<u8>) -> ProtocolOperation {
        self.openpgp_admin(password, || {
            Ok(openpgp::Request::WriteData(openpgp::DataWrite::Url(url)))
        })
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn openpgp_generate_key(&self, slot: u8, password: Vec<u8>) -> ProtocolOperation {
        self.openpgp_admin(password, || {
            let slot = match slot {
                0 => openpgp::Slot::Signature,
                1 => openpgp::Slot::Decryption,
                2 => openpgp::Slot::Authentication,
                _ => return Err(Error::new(ErrorKind::InvalidArgument)),
            };
            Ok(openpgp::Request::GenerateKey(slot))
        })
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn openpgp_terminate(&self, password: Vec<u8>) -> ProtocolOperation {
        self.openpgp_admin(password, || Ok(openpgp::Request::Terminate))
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn openpgp_activate(&self, password: Vec<u8>) -> ProtocolOperation {
        self.openpgp_admin(password, || Ok(openpgp::Request::Activate))
    }

    /// Set (Some) or clear (None) the reset code after explicit PW3 verification.
    #[flutter_rust_bridge::frb(sync)]
    pub fn openpgp_write_reset_code(
        &self,
        reset_code: Option<Vec<u8>>,
        password: Vec<u8>,
    ) -> ProtocolOperation {
        let reset_code = reset_code.map(SecretBytes::new);
        self.openpgp_admin(password, || {
            let reset_code = reset_code
                .map(|code| openpgp::Password::from_bytes(code.as_bytes()))
                .transpose()?;
            Ok(openpgp::Request::WriteData(openpgp::DataWrite::ResetCode(
                reset_code,
            )))
        })
    }

    /// Set PW1/reset-code/PW3 retry limits after explicit PW3 verification.
    /// The card resets PW1/PW3 to firmware defaults and clears authorization;
    /// the retry-reset capability gates construction before any I/O.
    #[flutter_rust_bridge::frb(sync)]
    pub fn openpgp_reset_retries(&self, retries: Vec<u8>, password: Vec<u8>) -> ProtocolOperation {
        self.openpgp_admin(password, || {
            let retries: [u8; 3] = retries
                .try_into()
                .map_err(|_| Error::new(ErrorKind::InvalidArgument))?;
            Ok(openpgp::Request::ResetRetries(retries))
        })
    }

    /// Whether one explicit PW1-sign verification may authorize multiple
    /// signatures (PW status bytes policy). Written after PW3 verification.
    #[flutter_rust_bridge::frb(sync)]
    pub fn openpgp_write_signature_pin_policy(
        &self,
        reuse: bool,
        password: Vec<u8>,
    ) -> ProtocolOperation {
        self.openpgp_admin(password, || {
            Ok(openpgp::Request::WriteData(
                openpgp::DataWrite::ReuseSignaturePin(reuse),
            ))
        })
    }

    /// Reset PW1 after explicit PW3 verification; does not change PW3.
    #[flutter_rust_bridge::frb(sync)]
    pub fn openpgp_unblock_with_admin(
        &self,
        new_pin: Vec<u8>,
        password: Vec<u8>,
    ) -> ProtocolOperation {
        let new_pin = SecretBytes::new(new_pin);
        self.openpgp_admin(password, || {
            let new_pin = openpgp::Password::from_bytes(new_pin.as_bytes())?;
            Ok(openpgp::Request::UnblockWithAdmin(new_pin))
        })
    }

    /// Reset PW1 using reset-code||new-PW1; no password verification is inserted.
    #[flutter_rust_bridge::frb(sync)]
    pub fn openpgp_unblock_with_code(&self, code: Vec<u8>, new_pin: Vec<u8>) -> ProtocolOperation {
        let code = SecretBytes::new(code);
        let new_pin = SecretBytes::new(new_pin);
        self.operation(|profile| {
            let code = openpgp::Password::from_bytes(code.as_bytes())?;
            let new_pin = openpgp::Password::from_bytes(new_pin.as_bytes())?;
            openpgp::operation(
                profile,
                openpgp::Request::UnblockWithCode { code, new: new_pin },
                None,
                OperationOptions::default(),
            )
            .map(Inner::OpenPgp)
        })
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
        self.openpgp_admin(password, || {
            let slot = openpgp_slot(slot)?;
            let policy = match policy {
                0 => openpgp::TouchPolicy::Off,
                1 => openpgp::TouchPolicy::On,
                2 => openpgp::TouchPolicy::Permanent,
                _ => return Err(Error::new(ErrorKind::InvalidArgument)),
            };
            Ok(openpgp::Request::WriteData(
                openpgp::DataWrite::TouchPolicy(slot, policy),
            ))
        })
    }

    /// Touch cache duration in seconds after PW3 verification; UIF-gated.
    #[flutter_rust_bridge::frb(sync)]
    pub fn openpgp_write_touch_cache_time(
        &self,
        seconds: u8,
        password: Vec<u8>,
    ) -> ProtocolOperation {
        self.openpgp_admin(password, || {
            Ok(openpgp::Request::WriteData(
                openpgp::DataWrite::TouchCacheTime(seconds),
            ))
        })
    }
}

pub(super) fn openpgp_slot(slot: u8) -> Result<openpgp::Slot, Error> {
    match slot {
        0 => Ok(openpgp::Slot::Signature),
        1 => Ok(openpgp::Slot::Decryption),
        2 => Ok(openpgp::Slot::Authentication),
        _ => Err(Error::new(ErrorKind::InvalidArgument)),
    }
}

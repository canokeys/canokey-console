use super::*;

impl ProtocolProfile {
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
        self.operation(|profile| {
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
        })
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn oath_delete(
        &self,
        name: Vec<u8>,
        access_key: Option<Vec<u8>>,
        access_challenge: Option<Vec<u8>>,
    ) -> ProtocolOperation {
        self.operation(|profile| {
            let request = oath::Request::Delete(oath::Name::from_bytes(&name)?);
            oath::operation(
                profile,
                request,
                oath_access(access_key, access_challenge)?,
                OperationOptions::default(),
            )
            .map(Inner::Oath)
        })
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn oath_rename(
        &self,
        old: Vec<u8>,
        new: Vec<u8>,
        access_key: Option<Vec<u8>>,
        access_challenge: Option<Vec<u8>>,
    ) -> ProtocolOperation {
        self.operation(|profile| {
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
        })
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn oath_list(
        &self,
        access_key: Option<Vec<u8>>,
        access_challenge: Option<Vec<u8>>,
    ) -> ProtocolOperation {
        self.operation(|profile| {
            oath::operation(
                profile,
                oath::Request::List,
                oath_access(access_key, access_challenge)?,
                OperationOptions::default(),
            )
            .map(Inner::Oath)
        })
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn oath_select(&self) -> ProtocolOperation {
        self.operation(|profile| {
            oath::operation(
                profile,
                oath::Request::Select,
                None,
                OperationOptions::default(),
            )
            .map(Inner::Oath)
        })
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn oath_validate(&self, key: Vec<u8>, challenge: Vec<u8>) -> ProtocolOperation {
        self.operation(|profile| {
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
        })
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn oath_clear_code(
        &self,
        key: Option<Vec<u8>>,
        challenge: Option<Vec<u8>>,
    ) -> ProtocolOperation {
        self.operation(|profile| {
            oath::operation(
                profile,
                oath::Request::ClearCode,
                oath_access(key, challenge)?,
                OperationOptions::default(),
            )
            .map(Inner::Oath)
        })
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
        self.operation(|profile| {
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
        })
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
        self.operation(|profile| {
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
        })
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
        self.operation(|profile| {
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
        })
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn oath_calculate_all(
        &self,
        challenge: Vec<u8>,
        format: u8,
        access_key: Option<Vec<u8>>,
        access_challenge: Option<Vec<u8>>,
    ) -> ProtocolOperation {
        self.operation(|profile| {
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
        })
    }
}

pub(super) fn oath_result(outcome: oath::Outcome) -> ProtocolStep {
    match outcome {
        oath::Outcome::Unit => bytes(Vec::new()),
        oath::Outcome::Entries(entries) => ProtocolStep {
            oath_entries: Some(
                entries
                    .into_iter()
                    .map(|entry| OathEntry {
                        algorithm_type: entry.algorithm_type,
                        name: entry.name.as_bytes().to_vec(),
                    })
                    .collect(),
            ),
            ..Default::default()
        },
        oath::Outcome::Selection(selection) => ProtocolStep {
            oath_selection: Some(OathSelectionData {
                version: Some(selection.version.to_vec()),
                salt: Some(selection.handle.to_vec()),
                challenge: selection.challenge.map(|value| value.to_vec()),
                serial: None,
            }),
            ..Default::default()
        },
        oath::Outcome::LegacySelection { serial } => ProtocolStep {
            oath_selection: Some(OathSelectionData {
                version: None,
                salt: None,
                challenge: None,
                serial: serial.map(|value| value.to_vec()),
            }),
            ..Default::default()
        },
        oath::Outcome::Calculations(entries) => ProtocolStep {
            oath_calculations: Some(
                entries
                    .into_iter()
                    .map(|entry| {
                        let (code, raw_code, full_code) = match entry.code {
                            oath::Code::Truncated(raw) => (
                                OathCode::Truncated,
                                Some(u32::from_be_bytes(
                                    raw.as_bytes()
                                        .try_into()
                                        .expect("validated truncated OATH code"),
                                )),
                                None,
                            ),
                            oath::Code::Full(raw) => {
                                (OathCode::Full, None, Some(raw.as_bytes().to_vec()))
                            }
                            oath::Code::Hotp => (OathCode::Hotp, None, None),
                            oath::Code::TouchRequired => (OathCode::TouchRequired, None, None),
                        };
                        OathCalculation {
                            name: entry.name.map(|name| name.as_bytes().to_vec()),
                            digits: entry.digits,
                            code,
                            raw_code,
                            full_code,
                        }
                    })
                    .collect(),
            ),
            ..Default::default()
        },
        // These requests are not exposed by Console.
        oath::Outcome::Serial(_) | oath::Outcome::ChallengeResponse(_) => {
            ProtocolStep::failure(Error::new(ErrorKind::InvalidResponse))
        }
    }
}

/// Both halves of an OATH access proof travel together; a key without a fresh
/// challenge (or vice versa) is rejected before any I/O.
pub(super) fn oath_access(
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

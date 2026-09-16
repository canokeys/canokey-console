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
    let mut probe = ProtocolOperation::probe_piv(None);
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
fn probe_skips_the_serial_read_when_bootstrap_observed() {
    let mut probe = ProtocolOperation::probe_admin(Some(vec![1, 2, 3, 4]));
    assert_eq!(
        probe.start().command.unwrap(),
        [0, 0xa4, 4, 0, 5, 0xf0, 0, 0, 0, 0, 0]
    );
    let mut step = probe.advance(vec![0x90, 0]);
    for response in [b"3.1.0\x90\0".to_vec(), b"CanoKey\x90\0".to_vec()] {
        assert!(step.command.is_some());
        step = probe.advance(response);
    }
    // No serial read APDU was issued; the observation is recorded.
    let profile = step.profile.unwrap();
    assert_eq!(profile.serial(), Some(vec![1, 2, 3, 4]));

    // A malformed observed serial fails at construction, before any I/O.
    let mut invalid = ProtocolOperation::probe_admin(Some(vec![1, 2, 3]));
    assert_eq!(invalid.start().error.unwrap().kind, "InvalidArgument");
    let mut invalid = ProtocolOperation::probe_piv(Some(vec![0; 5]));
    assert_eq!(invalid.start().error.unwrap().kind, "InvalidArgument");
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
fn algorithm_config_read_reuses_selection_and_validates() {
    // Without a management key the caller's selected transaction is reused.
    let profile = metadata_profile();
    let mut op = profile.piv_read_algorithm_config(None, 0x03);
    assert_eq!(op.start().command.unwrap(), [0, 0xee, 1, 0, 0]);
    assert!(op.advance(vec![1, 0x90, 0]).error.is_some());
    let mut op = profile.piv_read_algorithm_config(None, 0x03);
    op.start();
    let bytes = vec![1, 0xe0, 5, 0x16, 0xe1, 0x53, 0x15, 0x54, 0xe2, 0xe3];
    let mut response = bytes.clone();
    response.extend([0x90, 0]);
    assert_eq!(op.advance(response).data.unwrap(), bytes);
}

fn piv_profile(firmware: &[u8]) -> ProtocolProfile {
    let mut observations = canokey::compatibility::DeviceObservations::new(firmware.to_vec());
    observations.piv_version = Some(canokey::compatibility::PivApplicationVersion([6, 0, 0]));
    ProtocolProfile {
        inner: Some(canokey::DeviceProfile::from_observations(observations).unwrap()),
    }
}

#[test]
fn algorithm_config_read_capability_gate_precedes_authentication() {
    // Firmware without the INS EE read fails at construction with zero I/O,
    // with or without a management key: no SELECT and no GA is emitted.
    let profile = piv_profile(b"2.0.0");
    let mut op = profile.piv_read_algorithm_config(None, 0x03);
    assert_eq!(op.start().error.unwrap().kind, "UnsupportedFeature");
    let mut op = profile.piv_read_algorithm_config(Some(vec![0; 24]), 0x03);
    assert_eq!(op.start().error.unwrap().kind, "UnsupportedFeature");
}

#[test]
fn algorithm_config_read_authenticates_management_on_gated_firmware() {
    // 3.0.x gates the read behind management-key authentication; a supplied
    // key makes upstream SELECT, authenticate and read in one operation.
    let profile = piv_profile(b"3.0.3");
    let key = vec![
        0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef,
        0x01, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef, 0x01, 0x23,
    ];
    let mut op = profile.piv_read_algorithm_config(Some(key), 0x03);
    assert_eq!(
        op.start().command.unwrap(),
        [0, 0xa4, 4, 0, 5, 0xa0, 0, 0, 3, 8, 0]
    );
    assert_eq!(
        op.advance(vec![0x90, 0]).command.unwrap(),
        [0, 0x87, 3, 0x9b, 4, 0x7c, 2, 0x81, 0, 0]
    );
    let challenge = [
        0x7c, 0x0a, 0x81, 0x08, 0xfe, 0xdc, 0xba, 0x98, 0x76, 0x54, 0x32, 0x10, 0x90, 0,
    ];
    assert_eq!(
        op.advance(challenge.to_vec()).command.unwrap(),
        [
            0, 0x87, 3, 0x9b, 0x0c, 0x7c, 0x0a, 0x82, 0x08, 0x07, 0x37, 0xf6, 0xc5, 0x37, 0x50,
            0xd4, 0xa4, 0
        ]
    );
    assert_eq!(
        op.advance(vec![0x90, 0]).command.unwrap(),
        [0, 0xee, 1, 0, 0]
    );
    let bytes = vec![1, 0xe0, 5, 0x16, 0xe1, 0x53, 0x15, 0x54, 0xe2, 0xe3];
    let mut response = bytes.clone();
    response.extend([0x90, 0]);
    assert_eq!(op.advance(response).data.unwrap(), bytes);

    // An unauthenticated Existing read is constructible; the card-side gate
    // answers 6982, which stays a security failure.
    let mut op = profile.piv_read_algorithm_config(None, 0x03);
    assert_eq!(op.start().command.unwrap(), [0, 0xee, 1, 0, 0]);
    let error = op.advance(vec![0x69, 0x82]).error.unwrap();
    assert_eq!(error.kind, "SecurityStatusNotSatisfied");
    assert_eq!(error.phase, "Command");

    // Unknown key algorithms and malformed keys fail before any I/O.
    let mut op = profile.piv_read_algorithm_config(Some(vec![0; 24]), 0xff);
    assert_eq!(op.start().error.unwrap().kind, "UnsupportedAlgorithm");
    let mut op = profile.piv_read_algorithm_config(Some(vec![0; 8]), 0x03);
    assert!(op.start().error.is_some());
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
        0x0d, 0xe0, 0xba, 0xe2, 0x81, 0xba, 0x21, 0x98, 0x0e, 0x76, 0x92, 0xc9, 0x34, 0x52, 0x9f,
        0x0f, 0x61, 0x11, 0x16, 0x51,
    ]);
    validate.extend([0x74, 8]);
    validate.extend(b"HHHHHHHH");
    assert_eq!(op.advance(oath_selection(true)).command.unwrap(), validate);
    let mut proof = vec![0x75, 20];
    proof.extend([
        0xca, 0xa1, 0x34, 0x6e, 0x39, 0x05, 0x8d, 0xd3, 0x6e, 0xd7, 0x6f, 0xb4, 0x90, 0x53, 0xe1,
        0x4f, 0x66, 0xce, 0x42, 0x8b,
    ]);
    proof.extend([0x90, 0]);
    assert_eq!(
        op.advance(proof).command.unwrap(),
        [0, 0xa2, 0, 1, 6, 0x71, 4, b't', b'e', b's', b't']
    );
    let entries = op
        .advance(vec![0x76, 5, 6, 0, 0, 0, 42, 0x90, 0])
        .oath_calculations
        .unwrap();
    assert_eq!(entries.len(), 1);
    assert_eq!(entries[0].name, None);
    assert_eq!(entries[0].digits, 6);
    assert!(matches!(entries[0].code, OathCode::Truncated));
    assert_eq!(entries[0].raw_code, Some(42));
}

#[test]
fn oath_protected_applet_rejects_missing_or_partial_access_before_io() {
    let profile = metadata_profile();
    let mut op = profile.oath_delete(b"test".to_vec(), None, None);
    op.start();
    let error = op.advance(oath_selection(true)).error.unwrap();
    assert_eq!(error.kind, "SecurityStatusNotSatisfied");
    assert_eq!(error.phase, "Authentication");

    let mut op = profile.oath_delete(b"test".to_vec(), Some(b"KKKKKKKKKKKKKKKK".to_vec()), None);
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
    let entries = op.advance(vec![0x69, 0x85]).oath_calculations.unwrap();
    assert_eq!(entries.len(), 3);
    for (entry, name) in entries.iter().zip([b"A", b"B", b"C"]) {
        assert_eq!(entry.name.as_deref(), Some(name.as_slice()));
        assert_eq!(entry.digits, 6);
    }
    assert!(matches!(entries[0].code, OathCode::Truncated));
    assert_eq!(entries[0].raw_code, Some(1));
    assert!(matches!(entries[1].code, OathCode::Hotp));
    assert!(matches!(entries[2].code, OathCode::TouchRequired));
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
        let mut op = profile.openpgp_unblock_with_code(b"24682468".to_vec(), b"654321".to_vec());
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
    let mut op = profile.openpgp_write_reset_code(Some(b"12345678".to_vec()), b"12345678".to_vec());
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
        let mut op = metadata_profile().openpgp_write_reset_code(Some(code), b"12345678".to_vec());
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
    let slots = result.pass_slots.unwrap();
    assert_eq!(slots.len(), 2);
    assert_eq!(slots[0].kind, 2);
    assert!(slots[0].append_enter);
    assert_eq!(slots[1].kind, 1);
    assert_eq!(slots[1].name, b"test");
    assert!(!slots[1].append_enter);

    // Unknown type bytes pass through verbatim; off stays a single byte.
    let mut op = profile.admin_pass_slots(Some(b"123456".to_vec()), false);
    op.start();
    op.advance(vec![0x90, 0]);
    op.advance(vec![0x90, 0]);
    let result = op.advance(vec![0x7f, 0x00, 0x90, 0]).admin.unwrap();
    let slots = result.pass_slots.unwrap();
    assert_eq!(slots[0].kind, 0x7f);
    assert_eq!(slots[1].kind, 0);

    // Malformed dumps remain parsing failures, never fabricated slots.
    let mut op = profile.admin_pass_slots(None, true);
    assert_eq!(op.start().command.unwrap(), [0, 0x43, 0, 0, 0]);
    let error = op.advance(vec![0x02, 0x90, 0]).error.unwrap();
    assert_eq!(error.kind, "InvalidResponse");
    assert_eq!(error.phase, "Parsing");
}

#[test]
fn pass_slots_bare_read_fails_at_construction_without_io() {
    // INS 43 sits behind the firmware Admin-PIN gate on every audited
    // firmware, so upstream rejects a bare read before any exchange.
    let profile = metadata_profile();
    let mut op = profile.admin_pass_slots(None, false);
    let error = op.start().error.unwrap();
    assert_eq!(error.kind, "SecurityStatusNotSatisfied");
    assert!(op.start().command.is_none());
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
        0x0d, 0xe0, 0xba, 0xe2, 0x81, 0xba, 0x21, 0x98, 0x0e, 0x76, 0x92, 0xc9, 0x34, 0x52, 0x9f,
        0x0f, 0x61, 0x11, 0x16, 0x51,
    ]);
    validate.extend([0x74, 8]);
    validate.extend(b"HHHHHHHH");
    assert_eq!(op.advance(oath_selection(true)).command.unwrap(), validate);
    let mut proof = vec![0x75, 20];
    proof.extend([
        0xca, 0xa1, 0x34, 0x6e, 0x39, 0x05, 0x8d, 0xd3, 0x6e, 0xd7, 0x6f, 0xb4, 0x90, 0x53, 0xe1,
        0x4f, 0x66, 0xce, 0x42, 0x8b,
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
    let capability = op.advance(cc(0)).ndef_capability.unwrap();
    assert_eq!(capability.max_message_length, 0x03fe);
    assert!(!capability.read_only);
    let mut op = ProtocolOperation::ndef_read_capability();
    op.start();
    op.advance(vec![0x90, 0]);
    op.advance(vec![0x90, 0]);
    let capability = op.advance(cc(1)).ndef_capability.unwrap();
    assert_eq!(capability.max_message_length, 0x03fe);
    assert!(capability.read_only);

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

    // Message read: the file ID comes from the CC (0xE104), then NLEN
    // and the message from offset two; NLEN zero ends.
    let mut op = ProtocolOperation::ndef_read_message();
    op.start();
    op.advance(vec![0x90, 0]);
    op.advance(vec![0x90, 0]);
    assert_eq!(
        op.advance(cc(0)).command.unwrap(),
        [0, 0xa4, 0, 0x0c, 2, 0xe1, 0x04]
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
    let mut op = ProtocolOperation::ndef_write_message(b"hi".to_vec());
    assert_eq!(
        op.start().command.unwrap(),
        [0, 0xa4, 4, 0, 7, 0xd2, 0x76, 0, 0, 0x85, 1, 1]
    );
    // The CC is read before any UPDATE: it advertises the file ID (0xE104)
    // and the write access.
    assert_eq!(
        op.advance(vec![0x90, 0]).command.unwrap(),
        [0, 0xa4, 0, 0x0c, 2, 0xe1, 0x03]
    );
    assert_eq!(
        op.advance(vec![0x90, 0]).command.unwrap(),
        [0, 0xb0, 0, 0, 15]
    );
    assert_eq!(
        op.advance(cc(0)).command.unwrap(),
        [0, 0xa4, 0, 0x0c, 2, 0xe1, 0x04]
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

    // A read-only CC fails the write at preflight, before any UPDATE.
    let mut op = ProtocolOperation::ndef_write_message(b"hi".to_vec());
    op.start();
    op.advance(vec![0x90, 0]);
    op.advance(vec![0x90, 0]);
    let error = op.advance(cc(1)).error.unwrap();
    assert_eq!(error.kind, "SecurityStatusNotSatisfied");

    // Messages beyond the firmware maximum fail before any I/O.
    let mut op = ProtocolOperation::ndef_write_message(vec![0; 1023]);
    assert_eq!(op.start().error.unwrap().kind, "InvalidArgument");
}

// ---- CTAP2 client-layer bindings (getInfo/ClientPIN/credmgmt) --------
//
// Golden fixtures are the upstream canokey-ctap known answers
// (crates/canokey-ctap/tests/client_pin.rs, credmgmt.rs): ephemeral
// scalar 0x01..=0x20, peer scalar 0xA0..=0xBF, PINs "1234"/"654321",
// V2 IV 0F..00, token plaintext 0x10..=0x2F.

const CTAP_SELECT: [u8; 13] = [0, 0xa4, 4, 0, 8, 0xa0, 0, 0, 6, 0x47, 0x2f, 0, 1];
const CTAP_EPHEMERAL_SCALAR: [u8; 32] = [
    0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, 0x10,
    0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f, 0x20,
];
const CTAP_IV_V2: [u8; 16] = [
    0x0f, 0x0e, 0x0d, 0x0c, 0x0b, 0x0a, 0x09, 0x08, 0x07, 0x06, 0x05, 0x04, 0x03, 0x02, 0x01, 0x00,
];
const CTAP_PEER_KEY_AGREEMENT: &str = "a101a5010203381820012158200d0918a04198474605615b6df90fdcb34791fb3ecb822f4b26eb6e4fc4511b9d22582019b90c1b83c0c35cfbbb31ead32bb52ae33622f57e3cc1638097ce97f430baba";
const CTAP_SET_PIN_V1: &str = "06a50101020303a501020338182001215820515c3d6eb9e396b904d3feca7f54fdcd0cc1e997bf375dca515ad0a6c3b4035f2258204536be3a50f318fbf9a5475902a221502bef0d57e08c53b2cc0a56f17d9f93540450d4421839fa7606bcd586eddc6494d9620558406ce3b2501aea6143416b8de3b22671a0a351bc7cd39c13236e20a0c9e999c7da30a83a78c0ebe15c1948375d871d23c2fc6b34915a52f806f4be73f9c604f056";
const CTAP_CHANGE_PIN_V2: &str = "06a60102020403a501020338182001215820515c3d6eb9e396b904d3feca7f54fdcd0cc1e997bf375dca515ad0a6c3b4035f2258204536be3a50f318fbf9a5475902a221502bef0d57e08c53b2cc0a56f17d9f93540458206c2bb83d6ccfae4ce1221fa074d85cd5fae42f9ab7f65dd8c09ac8616429245b0558500f0e0d0c0b0a09080706050403020100a8395df2289b10495a9c1c13919cfdda5971cd6436294c7bafd204cd4eb1c737bbb21695023d71532c8cd847780477e0bf741b09ac0d72fdbc21ac401fe3ff1b0658200f0e0d0c0b0a0908070605040302010017d937071b239273a39da474e04c6376";
const CTAP_GET_TOKEN_PERMS_V2: &str = "06a60102020903a501020338182001215820515c3d6eb9e396b904d3feca7f54fdcd0cc1e997bf375dca515ad0a6c3b4035f2258204536be3a50f318fbf9a5475902a221502bef0d57e08c53b2cc0a56f17d9f93540658200f0e0d0c0b0a0908070605040302010017d937071b239273a39da474e04c637609030a6b6578616d706c652e636f6d";
const CTAP_TOKEN_CT_V1: &str = "b98cc635132fa3ea8c191b7a4aa3e093ce926c35488221b4684fce766f3b14b0";
const CTAP_TOKEN_CT_V2: &str = "0f0e0d0c0b0a09080706050403020100a1f914f091032bf439a162dbf45e137290ccdf4a4476a5f39b912b7dbbbb6f64";
const CTAP_MSG_RPS_BEGIN: &str = "0aa3010203010450d5dc1a03a1a284cf096b59a579eaf833";
const CTAP_MSG_RPS_NEXT: &str = "0aa201030301";
const CTAP_RESP_RP_BEGIN: &str = "a303a26269646b6578616d706c652e636f6d646e616d65674578616d706c65045820a0a1a2a3a4a5a6a7a8a9aaabacadaeafb0b1b2b3b4b5b6b7b8b9babbbcbdbebf0502";
const CTAP_RESP_RP_NEXT: &str = "a203a1626964696f746865722e6f7267045820c0c1c2c3c4c5c6c7c8c9cacbcccdcecfd0d1d2d3d4d5d6d7d8d9dadbdcdddedf";
const CTAP_MSG_CREDS_META: &str = "0aa4010402a2015820a0a1a2a3a4a5a6a7a8a9aaabacadaeafb0b1b2b3b4b5b6b7b8b9babbbcbdbebf1880f5030104503ffd7ae91f8e3630cd70f9f245edec40";
const CTAP_MSG_CREDS_NEXT: &str = "0aa201050301";
const CTAP_RESP_CRED_META: &str = "a406a26269644405060708646e616d6565616c69636507a2626964440102030464747970656a7075626c69632d6b6579090118803830";
const CTAP_RESP_CRED_BEGIN: &str = "a606a36269644405060708646e616d6565616c6963656b646973706c61794e616d6565416c69636507a2626964440102030464747970656a7075626c69632d6b657908a50102032620012158201111111111111111111111111111111111111111111111111111111111111111225820222222222222222222222222222222222222222222222222222222222222222209020a020b58203333333333333333333333333333333333333333333333333333333333333333";
const CTAP_RESP_CRED_NEXT: &str = "a207a2626964440908070664747970656a7075626c69632d6b657908a501020326200121582044444444444444444444444444444444444444444444444444444444444444442258205555555555555555555555555555555555555555555555555555555555555555";
const CTAP_MSG_DELETE: &str = "0aa4010602a102a2626964440102030464747970656a7075626c69632d6b657903010450038bc0ba9fef742b26ce891514a2142c";
const CTAP_RP_ID_HASH: [u8; 32] = [
    0xa0, 0xa1, 0xa2, 0xa3, 0xa4, 0xa5, 0xa6, 0xa7, 0xa8, 0xa9, 0xaa, 0xab, 0xac, 0xad, 0xae, 0xaf,
    0xb0, 0xb1, 0xb2, 0xb3, 0xb4, 0xb5, 0xb6, 0xb7, 0xb8, 0xb9, 0xba, 0xbb, 0xbc, 0xbd, 0xbe, 0xbf,
];
const CTAP_RP2_ID_HASH: [u8; 32] = [
    0xc0, 0xc1, 0xc2, 0xc3, 0xc4, 0xc5, 0xc6, 0xc7, 0xc8, 0xc9, 0xca, 0xcb, 0xcc, 0xcd, 0xce, 0xcf,
    0xd0, 0xd1, 0xd2, 0xd3, 0xd4, 0xd5, 0xd6, 0xd7, 0xd8, 0xd9, 0xda, 0xdb, 0xdc, 0xdd, 0xde, 0xdf,
];

fn ctap_hex(s: &str) -> Vec<u8> {
    let clean: String = s.chars().filter(|c| !c.is_whitespace()).collect();
    (0..clean.len())
        .step_by(2)
        .map(|i| u8::from_str_radix(&clean[i..i + 2], 16).unwrap())
        .collect()
}

/// The APDU wrapping the envelope emits for a CTAP message.
fn ctap_wrapped(message: &[u8]) -> Vec<u8> {
    let mut expected = vec![0x80, 0x10, 0x00, 0x00];
    if message.len() <= 255 {
        expected.push(message.len() as u8);
    } else {
        expected.push(0);
        expected.extend_from_slice(&(message.len() as u16).to_be_bytes());
    }
    expected.extend_from_slice(message);
    expected
}

/// A successful CTAP response (status 0x00) carrying `payload`.
fn ctap_ok(payload: &[u8]) -> Vec<u8> {
    let mut reply = vec![0x00];
    reply.extend_from_slice(payload);
    reply.extend_from_slice(&[0x90, 0x00]);
    reply
}

/// Drive a facade operation through SELECT and return the next step.
fn ctap_after_select(op: &mut ProtocolOperation) -> ProtocolStep {
    assert_eq!(op.start().command.unwrap(), CTAP_SELECT);
    op.advance(vec![0x90, 0])
}

/// A deterministic fixture session built at the upstream API level.
fn ctap_fixture_session(protocol: ctap::PinUvAuthProtocol) -> CtapPinSession {
    let mut op = ctap::get_key_agreement(
        protocol,
        &CTAP_EPHEMERAL_SCALAR,
        OperationOptions::default(),
    )
    .unwrap();
    assert_eq!(op.start().unwrap(), Step::Exchange);
    assert_eq!(op.advance(&[0x90, 0]).unwrap(), Step::Exchange);
    assert_eq!(
        op.advance(&ctap_ok(&ctap_hex(CTAP_PEER_KEY_AGREEMENT)))
            .unwrap(),
        Step::Done
    );
    CtapPinSession::new(op.take_result().unwrap())
}

/// The fixed V1 token (plaintext 0x10..=0x2F) via the fixture transcript.
fn ctap_fixture_token_v1() -> CtapPinToken {
    let session = ctap_fixture_session(ctap::PinUvAuthProtocol::V1);
    let mut op = ctap::get_pin_token(
        session.inner.as_ref().unwrap(),
        b"1234",
        None,
        OperationOptions::default(),
    )
    .unwrap();
    assert_eq!(op.start().unwrap(), Step::Exchange);
    assert_eq!(op.advance(&[0x90, 0]).unwrap(), Step::Exchange);
    let mut payload = vec![0xa1, 0x02, 0x58, 0x20];
    payload.extend_from_slice(&ctap_hex(CTAP_TOKEN_CT_V1));
    assert_eq!(op.advance(&ctap_ok(&payload)).unwrap(), Step::Done);
    CtapPinToken::new(op.take_result().unwrap(), ctap::PinUvAuthProtocol::V1)
}

/// getInfo fixture: versions [FIDO_2_0, FIDO_2_1], credMgmt true,
/// clientPin false, forcePinChange true, minPinLength 4, protocols [1, 2].
fn ctap_get_info_payload() -> Vec<u8> {
    ctap_hex(
        "a6 \
             01 82 684649444f5f325f30 684649444f5f325f31 \
             03 50 244eb29ee0904e4981fe1f20f8d3b8f4 \
             04 a3 62726bf5 68637265644d676d74f5 69636c69656e7450696ef4 \
             06 82 01 02 \
             0c f5 \
             0d 04",
    )
}

#[test]
fn ctap_status_bytes_map_through_application_status() {
    // Upstream keeps CTAP applet status bytes in application_status and
    // reserves status_word for ISO 7816; the bridge keeps the Dart
    // contract by widening application_status into status_word.
    let mut error = Error::new(ErrorKind::InvalidPin).at(Phase::Command);
    error.application_status = Some(0x31);
    assert_eq!(ProtocolError::from(error).status_word, Some(0x31));
    // The ISO status-word path is unchanged.
    let error = Error::status(
        canokey_protocol::StatusWord::new(0x6a82),
        Phase::Command,
        None,
    );
    assert_eq!(ProtocolError::from(error).status_word, Some(0x6a82));
    // Neither status present stays absent.
    let error = Error::new(ErrorKind::InvalidResponse);
    assert_eq!(ProtocolError::from(error).status_word, None);
}

#[test]
fn ctap_get_info_parses_fields_and_keeps_ctap_status() {
    let mut op = ProtocolOperation::ctap_get_info();
    let step = ctap_after_select(&mut op);
    assert_eq!(step.command.unwrap(), ctap_wrapped(&[0x04]));
    let info = op
        .advance(ctap_ok(&ctap_get_info_payload()))
        .ctap_info
        .unwrap();
    assert_eq!(info.cred_mgmt, Some(true));
    assert_eq!(info.client_pin, Some(false));
    assert_eq!(info.force_pin_change, Some(true));
    assert_eq!(info.min_pin_length, Some(4));
    assert_eq!(info.pin_uv_auth_protocols, [1, 2]);
    assert_eq!(op.start().error.unwrap().kind, "OperationStateError");

    // A tri-state stays absent when the option is unadvertised: minimal
    // map with only versions and aaguid.
    let mut op = ProtocolOperation::ctap_get_info();
    ctap_after_select(&mut op);
    let minimal = ctap_hex("a2 01 81 684649444f5f325f30 03 50 244eb29ee0904e4981fe1f20f8d3b8f4");
    let info = op.advance(ctap_ok(&minimal)).ctap_info.unwrap();
    assert_eq!(info.cred_mgmt, None);
    assert_eq!(info.client_pin, None);
    assert_eq!(info.force_pin_change, None);
    assert_eq!(info.min_pin_length, None);
    assert!(info.pin_uv_auth_protocols.is_empty());

    // A CTAP-level failure keeps the raw CTAP status byte (upstream carries
    // it in application_status; the bridge maps it to status_word).
    let mut op = ProtocolOperation::ctap_get_info();
    ctap_after_select(&mut op);
    let error = op.advance(vec![0x30, 0x90, 0x00]).error.unwrap();
    assert_eq!(error.kind, "ConditionsNotSatisfied");
    assert_eq!(error.phase, "Command");
    assert_eq!(error.status_word, Some(0x30));

    // A response missing the required versions key is malformed.
    let mut op = ProtocolOperation::ctap_get_info();
    ctap_after_select(&mut op);
    let bad = ctap_hex("a1 03 50 244eb29ee0904e4981fe1f20f8d3b8f4");
    let error = op.advance(ctap_ok(&bad)).error.unwrap();
    assert_eq!(error.kind, "InvalidResponse");
    assert_eq!(error.phase, "Parsing");
}

#[test]
fn ctap_begin_pin_session_drives_handshake_and_validates_protocol() {
    let mut op = ProtocolOperation::ctap_begin_pin_session(1);
    let step = ctap_after_select(&mut op);
    // The ephemeral scalar is random, but the message shape is fixed.
    assert_eq!(
        step.command.unwrap(),
        ctap_wrapped(&ctap_hex("06 a2 01 01 02 02"))
    );
    let step = op.advance(ctap_ok(&ctap_hex(CTAP_PEER_KEY_AGREEMENT)));
    let session = step.pin_session.unwrap();
    assert_eq!(session.protocol_version(), 1);

    let mut op = ProtocolOperation::ctap_begin_pin_session(2);
    ctap_after_select(&mut op);
    let session = op
        .advance(ctap_ok(&ctap_hex(CTAP_PEER_KEY_AGREEMENT)))
        .pin_session
        .unwrap();
    assert_eq!(session.protocol_version(), 2);

    // Unknown advertised protocol versions fail before any I/O.
    let mut op = ProtocolOperation::ctap_begin_pin_session(3);
    assert_eq!(op.start().error.unwrap().kind, "InvalidArgument");
}

#[test]
fn ctap_set_and_change_pin_match_golden_wire_bytes() {
    // V1 golden (upstream known answer, zero IV by specification).
    let session = ctap_fixture_session(ctap::PinUvAuthProtocol::V1);
    let mut op = session.set_pin(b"1234".to_vec());
    let step = ctap_after_select(&mut op);
    assert_eq!(
        step.command.unwrap(),
        ctap_wrapped(&ctap_hex(CTAP_SET_PIN_V1))
    );
    assert_eq!(
        op.advance(vec![0x00, 0x90, 0]).data.unwrap(),
        Vec::<u8>::new()
    );

    // V2 golden with the fixture IV.
    let session = ctap_fixture_session(ctap::PinUvAuthProtocol::V2);
    let mut op = session.change_pin_with_iv(
        SecretBytes::new(b"1234".to_vec()),
        SecretBytes::new(b"654321".to_vec()),
        Some(CTAP_IV_V2),
    );
    let step = ctap_after_select(&mut op);
    assert_eq!(
        step.command.unwrap(),
        ctap_wrapped(&ctap_hex(CTAP_CHANGE_PIN_V2))
    );
    assert_eq!(
        op.advance(vec![0x00, 0x90, 0]).data.unwrap(),
        Vec::<u8>::new()
    );

    // PIN_INVALID keeps the raw CTAP status byte via application_status.
    let session = ctap_fixture_session(ctap::PinUvAuthProtocol::V1);
    let mut op = session.change_pin(b"1234".to_vec(), b"654321".to_vec());
    ctap_after_select(&mut op);
    let error = op.advance(vec![0x31, 0x90, 0x00]).error.unwrap();
    assert_eq!(error.kind, "InvalidPin");
    assert_eq!(error.status_word, Some(0x31));

    // PIN validation happens before any I/O; a closed session is inert.
    let session = ctap_fixture_session(ctap::PinUvAuthProtocol::V1);
    let mut op = session.set_pin(b"ab".to_vec());
    assert_eq!(op.start().error.unwrap().kind, "InvalidPin");
    let mut session = ctap_fixture_session(ctap::PinUvAuthProtocol::V1);
    session.close();
    let mut op = session.set_pin(b"1234".to_vec());
    assert_eq!(op.start().error.unwrap().kind, "OperationStateError");
}

#[test]
fn ctap_v2_operations_generate_fresh_ivs_internally() {
    let session = ctap_fixture_session(ctap::PinUvAuthProtocol::V2);
    let mut first = session.set_pin(b"1234".to_vec());
    let mut second = session.set_pin(b"1234".to_vec());
    let first_command = ctap_after_select(&mut first).command.unwrap();
    let second_command = ctap_after_select(&mut second).command.unwrap();
    assert_ne!(first_command, second_command, "V2 IVs must be fresh");
    assert_eq!(first_command.len(), second_command.len());
    assert_eq!(
        first.advance(vec![0x00, 0x90, 0]).data.unwrap(),
        Vec::<u8>::new()
    );
}

#[test]
fn ctap_pin_token_golden_and_ctap_error_mapping() {
    let session = ctap_fixture_session(ctap::PinUvAuthProtocol::V2);
    let mut op = session.pin_token_with_iv(
        SecretBytes::new(b"1234".to_vec()),
        0x03,
        Some("example.com".to_string()),
        Some(CTAP_IV_V2),
    );
    let step = ctap_after_select(&mut op);
    assert_eq!(
        step.command.unwrap(),
        ctap_wrapped(&ctap_hex(CTAP_GET_TOKEN_PERMS_V2))
    );
    let mut payload = vec![0xa1, 0x02, 0x58, 0x30];
    payload.extend_from_slice(&ctap_hex(CTAP_TOKEN_CT_V2));
    let token = op.advance(ctap_ok(&payload)).pin_token.unwrap();
    assert_eq!(token.protocol_version(), 2);

    // Zero permissions and PIN validation fail before any I/O.
    let mut op = session.get_pin_token_with_permissions(b"1234".to_vec(), 0, None);
    assert_eq!(op.start().error.unwrap().kind, "InvalidArgument");
    let mut op = session.get_pin_token_with_permissions(vec![0xff, 0xfe, 0x41, 0x42], 4, None);
    assert_eq!(op.start().error.unwrap().kind, "InvalidPin");

    // PIN_BLOCKED keeps the raw CTAP status byte via application_status.
    let session = ctap_fixture_session(ctap::PinUvAuthProtocol::V1);
    let mut op = session.get_pin_token_with_permissions(b"1234".to_vec(), 4, None);
    ctap_after_select(&mut op);
    let error = op.advance(vec![0x32, 0x90, 0x00]).error.unwrap();
    assert_eq!(error.kind, "PinBlocked");
    assert_eq!(error.status_word, Some(0x32));
}

#[test]
fn ctap_enumerate_rps_encodes_entries_and_empty_is_not_an_error() {
    let token = ctap_fixture_token_v1();
    let mut op = token.enumerate_rps();
    let step = ctap_after_select(&mut op);
    assert_eq!(
        step.command.unwrap(),
        ctap_wrapped(&ctap_hex(CTAP_MSG_RPS_BEGIN))
    );
    let step = op.advance(ctap_ok(&ctap_hex(CTAP_RESP_RP_BEGIN)));
    assert_eq!(
        step.command.unwrap(),
        ctap_wrapped(&ctap_hex(CTAP_MSG_RPS_NEXT))
    );
    let rps = op
        .advance(ctap_ok(&ctap_hex(CTAP_RESP_RP_NEXT)))
        .ctap_rps
        .unwrap();
    assert_eq!(rps.len(), 2);
    assert_eq!(rps[0].id, "example.com");
    assert_eq!(rps[0].name.as_deref(), Some("Example"));
    assert_eq!(rps[0].id_hash, CTAP_RP_ID_HASH);
    assert_eq!(rps[1].id, "other.org");
    assert_eq!(rps[1].name, None);
    assert_eq!(rps[1].id_hash, CTAP_RP2_ID_HASH);

    // CTAP2_ERR_NO_CREDENTIALS on Begin is an empty list, not an error.
    let mut op = token.enumerate_rps();
    ctap_after_select(&mut op);
    assert!(op
        .advance(vec![0x2e, 0x90, 0x00])
        .ctap_rps
        .unwrap()
        .is_empty());
}

#[test]
fn ctap_enumerate_credentials_metadata_only_and_standard_encoding() {
    let token = ctap_fixture_token_v1();
    let mut op = token.enumerate_credentials(CTAP_RP_ID_HASH.to_vec(), true);
    let step = ctap_after_select(&mut op);
    assert_eq!(
        step.command.unwrap(),
        ctap_wrapped(&ctap_hex(CTAP_MSG_CREDS_META))
    );
    let entries = op
        .advance(ctap_ok(&ctap_hex(CTAP_RESP_CRED_META)))
        .ctap_credentials
        .unwrap();
    assert_eq!(entries.len(), 1);
    let entry = &entries[0];
    assert_eq!(entry.credential_id, [1, 2, 3, 4]);
    assert_eq!(entry.user_id.as_deref(), Some([5, 6, 7, 8].as_slice()));
    assert_eq!(entry.user_name.as_deref(), Some("alice"));
    assert_eq!(entry.user_display_name, None);
    assert_eq!(entry.cred_protect, None);
    assert_eq!(entry.cose_algorithm, Some(-49));
    assert_eq!(entry.public_key, None);

    let mut op = token.enumerate_credentials(CTAP_RP_ID_HASH.to_vec(), false);
    ctap_after_select(&mut op);
    let step = op.advance(ctap_ok(&ctap_hex(CTAP_RESP_CRED_BEGIN)));
    assert_eq!(
        step.command.unwrap(),
        ctap_wrapped(&ctap_hex(CTAP_MSG_CREDS_NEXT))
    );
    let entries = op
        .advance(ctap_ok(&ctap_hex(CTAP_RESP_CRED_NEXT)))
        .ctap_credentials
        .unwrap();
    assert_eq!(entries.len(), 2);
    assert_eq!(entries[0].credential_id, [1, 2, 3, 4]);
    assert_eq!(entries[0].user_name.as_deref(), Some("alice"));
    assert_eq!(entries[0].user_id.as_deref(), Some([5, 6, 7, 8].as_slice()));
    assert_eq!(entries[0].user_display_name.as_deref(), Some("Alice"));
    assert_eq!(entries[0].cred_protect, Some(2));
    assert_eq!(entries[0].cose_algorithm, Some(-7));
    assert_eq!(entries[0].public_key.as_ref().unwrap(), &ctap_hex("a501020326200121582011111111111111111111111111111111111111111111111111111111111111112258202222222222222222222222222222222222222222222222222222222222222222"));
    assert_eq!(entries[1].credential_id, [9, 8, 7, 6]);
    assert_eq!(entries[1].user_id, None);
    assert_eq!(entries[1].cred_protect, None);
    assert_eq!(entries[1].cose_algorithm, Some(-7));
    assert_eq!(entries[1].public_key.as_ref().unwrap(), &ctap_hex("a501020326200121582044444444444444444444444444444444444444444444444444444444444444442258205555555555555555555555555555555555555555555555555555555555555555"));

    // A 31-byte RP ID hash fails before any I/O.
    let mut op = token.enumerate_credentials(vec![0; 31], false);
    assert_eq!(op.start().error.unwrap().kind, "InvalidArgument");
}

#[test]
fn ctap_delete_credential_golden_and_handle_lifecycle() {
    let token = ctap_fixture_token_v1();
    let mut op = token.delete_credential(vec![1, 2, 3, 4]);
    let step = ctap_after_select(&mut op);
    assert_eq!(
        step.command.unwrap(),
        ctap_wrapped(&ctap_hex(CTAP_MSG_DELETE))
    );
    assert_eq!(
        op.advance(vec![0x00, 0x90, 0]).data.unwrap(),
        Vec::<u8>::new()
    );

    // An unknown credential is NotFound with the raw CTAP status byte
    // carried through application_status.
    let mut op = token.delete_credential(vec![1, 2, 3, 4]);
    ctap_after_select(&mut op);
    let error = op.advance(vec![0x2e, 0x90, 0x00]).error.unwrap();
    assert_eq!(error.kind, "NotFound");
    assert_eq!(error.status_word, Some(0x2e));

    // An empty credential ID fails before any I/O; a closed token handle
    // rejects further operations.
    let mut op = token.delete_credential(vec![]);
    assert_eq!(op.start().error.unwrap().kind, "InvalidArgument");
    let mut token = ctap_fixture_token_v1();
    token.close();
    token.close();
    let mut op = token.enumerate_rps();
    assert_eq!(op.start().error.unwrap().kind, "OperationStateError");
}

#[test]
fn private_key_import_owns_material_and_rejects_closed_or_mismatched_keys() {
    use p256::pkcs8::EncodePrivateKey;
    let secret = p256::SecretKey::from_slice(&[3; 32]).unwrap();
    let der = secret.to_pkcs8_der().unwrap();
    let mut key = super::super::piv_crypto::parse_piv_import_file(der.as_bytes().to_vec())
        .unwrap()
        .private_key
        .unwrap();
    let profile = metadata_profile();
    let mut mismatch = profile.piv_import_private_key(0x9a, 0x07, &key, 0, 0);
    assert_eq!(mismatch.start().error.unwrap().kind, "UnsupportedAlgorithm");
    let mut first = profile.piv_import_private_key(0x9a, 0x11, &key, 2, 1);
    let mut retry = profile.piv_import_private_key(0x9a, 0x11, &key, 2, 1);
    key.close();
    key.close();
    let mut closed = profile.piv_import_private_key(0x9a, 0x11, &key, 2, 1);
    assert_eq!(closed.start().error.unwrap().kind, "OperationStateError");
    let command = first.start().command.unwrap();
    assert_eq!(retry.start().command.unwrap(), command);
    let mut expected = vec![0, 0xfe, 0x11, 0x9a, 40, 6, 32];
    expected.extend_from_slice(&[3; 32]);
    expected.extend_from_slice(&[0xaa, 1, 2, 0xab, 1, 1]);
    assert_eq!(command, expected);
    assert!(first.advance(vec![0x90, 0]).data.is_some());
    assert!(retry.advance(vec![0x69, 0x82]).error.is_some());
    assert!(retry.start().command.is_none());
}

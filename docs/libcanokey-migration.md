# libcanokey integration

All card protocol operations in Console go through
[libcanokey](https://github.com/canokeys/libcanokey) via the Flutter Rust
Bridge facade in `rust/src/api/protocol.rs`. The pinned revision lives in
`rust/Cargo.toml`. Dart never constructs APDUs; host-side policy (CSR
building, UI flows, credential prompting) stays in Console.

## Architecture

- `rust/src/api/protocol.rs` — the FRB facade. `ProtocolProfile` holds probed
  device evidence; `ProtocolOperation` is an opaque state machine that Dart
  drives APDU-by-APDU (`start()`/`advance(response)` → `ProtocolStep`).
  Handles (`CtapPinSession`, `CtapPinToken`, profiles) are opaque and
  close/dispose locally only. The public types stay in this module so Dart
  imports remain stable; applet implementations live in `protocol/*_ops.rs`
  and transcript tests in `protocol/tests.rs`. Profile checks, PIV policy
  conversion and OpenPGP administrator requests share construction helpers.
- CTAP information/RPs/credentials, OATH selections/calculations, Admin usage, NDEF capabilities and
  Pass slot states cross FRB as typed fields. There is no intermediate Console
  byte format for these results. `executeProtocolResult` and
  `executePreparedResult` share the existing lease, cancellation and cleanup
  path with byte-returning operations.
- PIV import keys are opaque Rust handles holding zeroizing components. Dart
  receives only algorithm/public-key metadata; import operations copy the material
  into libcanokey owners directly. Closing the dialog wipes and disposes the handle.
  Unused Console exports are omitted from the generated bridge.
- Certificate inspection uses `x509-info` for DER/PEM, names, algorithms,
  key sizes and extensions. Console maps owned results to its display DTO and
  retains macOS role policy, certificate/CSR construction and signature
  verification. Unknown key sizes display no bit count; encoded key length
  is not treated as a key size.
- `lib/helper/utils/card_client.dart` — shared client infrastructure:
  `CardClientBase` (transport/lease guards, `withSession`, cancellation),
  `ProfileCardClient` (`prepareProfile`, `executePrepared`,
  `lastStatusWord`), `ProfileBinding` (lease + generation evidence), and
  `AdminSessionCardClient` (Admin progress and session evidence) in
  `admin_card.dart`. Per-applet clients (`piv_card.dart`, `oath_card.dart`,
  `openpgp_card.dart`, `ndef_card.dart`, `pass_card.dart`,
  `webauthn_card.dart`) hold only domain logic.
- `lib/helper/utils/smartcard.dart` — the `SmartCard.process` queue; every
  use case (connect, SELECT, authenticate, commands, cleanup) runs inside it.
  Connection bootstrap identity commands use upstream `admin::command`
  builders via `ProtocolOperation.bootstrapIdentity`, and the serial they
  read is recorded on the lease so later probes skip the duplicate serial
  read (`observedSerial`).

## Contracts that must not be broken

- A physical lease (`CardLease`) owns selection/profile/authentication
  generations. A closed, failed or replaced lease cannot exchange or publish
  results. One executor reserves its lease for a whole operation; raw
  exchanges, other operations and rebinds cannot interleave continuation
  APDUs.
- Profiles are immutable evidence, never authentication tokens. Controllers
  `prepare()` explicitly before dependent reads; an explicit SELECT or a
  profile-affecting write invalidates the evidence. Failed re-probing never
  leaves an older profile usable.
- Mutations are never retried, resumed or rolled back by the host. A
  cancelled or uncertain write is exposed as unconfirmed, not reported
  successful.
- Credentials are explicit per request and enter zeroizing containers; Dart
  wipes its mutable copies. Admin session evidence (`Access::Existing`
  reuse) is recorded only by a successful facade `VerifyPin`, is stamped
  with the lease generations, and is invalidated by cross-applet selection,
  profile invalidation, uncertain writes, failed Existing requests or lease
  replacement. UI PIN caches never produce authorization.
- Capability policy: firmware outside the audited matrix is
  `CapabilityUnknown` and unsupported operations fail at construction,
  before any I/O. Console never bypasses capability checks with invented
  profiles or speculative wire formats.
- Errors keep kind, phase and status word as separate fields. On CTAP paths
  `statusWord` carries the raw CTAP status byte (widened), not an ISO SW.
  Transport errors propagate unchanged.

## Applet notes

- **Admin** — full coverage (config, PIN, NFC, SM2, keymap, applet/factory
  reset, Pass slots). Requests default to SELECT + per-request PIN and
  converge to `Access::Existing` while session evidence is valid. A PIN-less
  request also reuses the probe's selection (`Access::Existing`, no SELECT)
  while it is still current, except for the card-gated Pass slot read; the
  card remains the enforcement point either way.
- **PIV** — full coverage, including PQ seed import, attestation and
  streaming sign, all with `Access::Existing`. The algorithm-extension read
  uses the upstream profile-based operation: on 3.0.x firmware it requires
  management-key authentication (`Access::Management` authenticates and
  reads in one operation); an unauthenticated read fails with
  `SecurityStatusNotSatisfied` and the UI falls back to firmware defaults
  only for that known gate. Certificate/object framing, gzip bounds and
  continuation are owned upstream.
- **OATH** — full coverage; password-protected applets pass
  `accessKey`/`accessChallenge` per operation. Set-default legacy dialects
  are split by the upstream capability (`OathSetDefaultSlots`).
- **OpenPGP** — Console operations (data reads, PIN/reset-code/unblock, touch
  policy/cache and retries). Optional data
  objects map only `NotFound` to null.
- **NDEF** — profile-free read capability/message and crash-safe write.
  The CC advertises the file ID; read-only and oversized writes fail at the
  CC preflight (`SecurityStatusNotSatisfied` / `LimitExceeded`).
- **Pass** — Admin `PassSlots`/`SetPassSlot`. Both are protected; reads take
  the lease's verified PIN unless session evidence applies. OATH-linked
  slots are read-only here (configured via OATH); unknown slot types surface
  as unknown.
- **WebAuthn/CTAP2** — upstream `ctap2`/`pin`/`credmgmt` client layer
  (getInfo, ClientPin v1/v2, credential management) with canonical CBOR in
  Rust. Tokens are ceremony-scoped and never cached; the ephemeral scalar
  and IV are generated by the facade's CSPRNG. Non-zero CTAP status bytes
  are data for the UI, not transport errors.

## Remaining wire-level redundancies (need upstream support)

- `probe_device` always SELECTs Admin even when the connection bootstrap just
  did; a probe option to skip selection on an already-selected channel would
  remove one SELECT per refresh.
- `admin::operation_with_access` rejects `VerifyPin` under `Access::Existing`
  at construction, so the authentication step re-SELECTs after the probe
  left Admin selected. Allowing VERIFY on the existing selection (or a
  dedicated selected-verify request) would remove another.
- The bootstrap-observed serial is recorded as probe evidence without a
  card-side check by design; Console compensates with a real serial read
  immediately before PIN verification.

## Verification

```sh
flutter_rust_bridge_codegen generate   # after facade signature changes
cargo test --manifest-path rust/Cargo.toml --locked
cargo build --manifest-path rust/Cargo.toml --release --locked
cargo check --manifest-path rust/Cargo.toml --target wasm32-unknown-unknown --locked
flutter test --no-pub
flutter test --no-pub --tags native   # injected-transport transcripts
```

The FRB WASM package (`flutter_rust_bridge_codegen build-web --release
--wasm-pack-rustup-toolchain <nightly>`) and `flutter build web --no-pub`
must be rebuilt after facade changes; the wasm-bindgen crate family in
`rust/Cargo.toml` tracks the `wasm-bindgen-cli` version used by wasm-pack.
The USB/IP firmware matrix runs in CI (`.github/workflows/usbip.yml`) via
`test/usbip/console_smoke.dart`; physical-card and browser-transport
coverage is not exercised locally.

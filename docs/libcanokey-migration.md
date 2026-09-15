# libcanokey migration

The first increment uses the Rust facade through Flutter Rust Bridge, following
[canokey-pkcs11#5](https://github.com/canokeys/canokey-pkcs11/pull/5). Cargo pins
libcanokey to the same `10808e1760bf5efa86b5ff2e0b4acbeaba441edc` revision.
The C ABI is unnecessary in Console's existing Rust library.

## Implemented

- PIV selection uses `select_application`, including an explicit Le for legacy
  readers. This is still an explicit caller action and may clear authentication.
- PIV version and algorithm configuration reads use the upstream selected-app
  operations. Neither inserts SELECT, probes the device, or authenticates.
- An opaque FRB operation owns its protocol state across Dart await points.
  The Dart executor exchanges complete APDUs, including response status words.
  libcanokey owns continuation, safe Le correction, budgets and validation.
- Completion, protocol failures, malformed transport hex and transport exceptions
  all close/dispose the operation. No mutation is retried or rolled back.
  Byte buffers copied to Dart are wiped after each exchange; immutable transport
  strings and existing diagnostic logs are not erasable by this executor.
- Errors retain category, phase, status word, credential reference and retry count
  as separate fields. Transport errors are propagated without conversion.
- Only an unsupported algorithm-configuration instruction permits the existing
  firmware defaults. Security failures, malformed responses and communication
  errors no longer silently choose default algorithms.

Existing UI models still map validated configuration bytes to display/algorithm
fields. Other Admin/PIV/OATH/OpenPGP/NDEF/Pass operations remain in Dart.

## Session boundary and next increments

The caller must hold its selected card session for the entire executor future.
The executor does not acquire a connection or establish a transaction. Current
callers continue to use Console's existing SmartCard workflows; this increment
does not add a global connection lock or profile cache.

Before migrating authenticated operations, establish a connection-bound exclusive
lease with generation checks, and derive a profile from observations of that same
device. Keep the lease across SELECT, authentication, dependent operations and
publication of results. Never SELECT/probe between authentication and its target.
Use upstream `*_in_context` factories for the already selected session; do not
assert authentication from cached UI state. Drain failed/timed-out I/O before
reusing the connection. Operation close is local cleanup, not card rollback.

Suggested next steps are profile/session ownership, certificate and metadata
reads, PIN/PUK and management authentication, PIV writes/private operations, then
Admin/OATH/OpenPGP. Host CSR construction and UI policy remain in Console.

## Verification

```sh
flutter_rust_bridge_codegen generate
cargo test --manifest-path rust/Cargo.toml api::protocol --locked
cargo build --manifest-path rust/Cargo.toml --release --locked
flutter test --no-pub test/helper/utils/piv_card_test.dart
flutter test --no-pub --exclude-tags native
```

The native PIV transcript tests run alongside FIDO2 tests in the USB/IP workflow.
The firmware smoke entry point initializes FRB before the migrated PIV operations.
Native transcripts do not establish physical-device or legacy-firmware coverage.

Local validation on 2026-09-15 (Rust 1.98.1 / Flutter 3.47.1): all 35 Rust tests,
292 non-native Dart/UI tests and 19 native PIV/FIDO2 tests passed. The generated
bridge built natively, `cargo check --target wasm32-unknown-unknown` and
`flutter build web --no-pub` passed. Changed Dart files passed analysis and the
workflow passed actionlint. Strict Clippy encountered the existing
`chunks_exact_to_as_chunks` lint in `rust/src/api/decode.rs:10`; all-target Clippy
passed with only that lint allowed. Repository-wide rustfmt also reports existing
formatting in `piv_crypto.rs`; the new protocol module passes rustfmt. No physical
card, browser transport session or USB/IP firmware matrix was run locally.

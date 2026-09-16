# libcanokey migration

The first increment uses the Rust facade through Flutter Rust Bridge, following
[canokey-pkcs11#5](https://github.com/canokeys/canokey-pkcs11/pull/5). Cargo pins
libcanokey to the same `95e1930ea86eb248d0295bce9880cee5c65fd85e` revision.
The C ABI is unnecessary in Console's existing Rust library.

## Implemented

- PIV selection uses `select_application`, including an explicit Le for legacy
  readers. This is still an explicit caller action and may clear authentication.
- PIV version and algorithm configuration reads use the upstream selected-app
  operations. Neither inserts SELECT, probes the device, or authenticates.
- PIV certificate reads use `read_certificate` with `Access::Existing` and an
  explicitly prepared, lease-owned profile. The former local certificate machine
  has been removed. libcanokey owns GET DATA, container validation and bounded gzip
  decompression; no SELECT/probe/authentication is inserted. Only 6A82/6A88 return
  a missing object; malformed certificates remain visible as invalid UI slots.
- PIV management-protection object reads/writes use `read_object`/`write_object`
  with `Access::Existing`. The controller no longer builds GET/PUT DATA or unwraps
  outer 53 containers. Missing objects alone become null; malformed/security
  failures propagate. Upstream owns firmware checks, framing and segmentation.
  Writes are never resumed or rolled back after partial or uncertain outcomes.
- An opaque FRB operation owns its protocol state across Dart await points.
  The Dart executor exchanges complete APDUs, including response status words.
  libcanokey owns continuation, safe Le correction, budgets and validation.
- Completion, protocol failures, malformed transport hex and transport exceptions
  all close/dispose the operation. No mutation is retried or rolled back.
  Byte buffers copied to Dart are wiped after each exchange; immutable transport
  strings are not erasable by this executor. Console's physical transport retains
  the existing full `C-APDU`/`R-APDU` diagnostic logs, including for lease-based
  operations. These diagnostic copies are not erased by operation cleanup.
- Explicit `prepare()` probes Admin/PIV before metadata workflows authenticate.
  The resulting opaque profile belongs to that physical lease and is closed on
  rebinding or lease release. Once re-probing starts, failure cannot leave an older
  profile usable; competing preparation is rejected before touching an active
  operation's profile.
- PIV key/PIN/PUK/management metadata now uses `get_metadata` with `Access::Existing` and
  upstream capability/slot checks, continuation and field validation. Reads never
  SELECT, probe or authenticate. Only upstream `NotFound` (including supported
  legacy 6900 empty-key responses) becomes null; security, unsupported-command,
  invalid-length and malformed-field errors remain visible. UI mapping rejects
  incomplete/unknown required display fields instead of inventing retries or
  policies. Key algorithm display resolves through this device's profile, ignoring
  stale UI extension IDs; display enum IDs never authorize a device operation.
- PIN verification/change, PUK change, PIN unblocking and explicit logout now use
  `credential(select=false)`. Inputs enter upstream zeroizing owners; Dart wipes its
  mutable input copies. Credential validation and legacy explicit Le follow the
  pinned library. PIN/PUK failures preserve their reference and remaining retries;
  only authentication rejection/blocked credentials map to the UI's false result.
  Successful credential operations have `Unchanged` profile effect and do not
  create a reusable authorization token.
- Management-key external authentication now uses
  `authenticate_management_key(select=false)`: libcanokey owns both challenge APDUs,
  parsing and 3DES/AES cryptography, with current-profile capability checks.
  The old Dart challenge builders/parser were removed. This preserves external
  mode; it does not claim mutual device authentication.
- Selected PIN status uses upstream `command::pin_status`, the operation engine
  and error classifier. A small adapter retains the validated status word because
  the pinned high-level `get_pin_status` inserts SELECT, which would disturb an
  already authenticated transaction. Unexpected statuses and nonempty replies are
  errors; 9000 never invents a retry count. Serial reads now return the optional
  Admin serial observed by the explicit probe, without another applet switch.
- Explicit PUK blocking retains Console's bounded, intentional destructive loop,
  with each CHANGE PUK executed upstream. Only expected credential outcomes allow
  the next attempt; uncertain I/O, malformed responses and unexpected statuses
  stop immediately. No mutation is replayed after a 6C response.
- Each executor reserves its lease across the entire operation, preventing raw
  exchanges, another operation or rebind between continuation APDUs.
- Errors retain category, phase, status word, credential reference and retry count
  as separate fields. Transport errors are propagated without conversion.
- Only an unsupported algorithm-configuration instruction permits the existing
  firmware defaults, plus one firmware-scoped exception: 3.0.x gates that read
  behind management-key authentication (every SELECT resets the status), so an
  unauthenticated capabilities read takes the defaults fallback exactly on
  3.0.x, and `readAlgorithmExtensions` accepts an optional management key to
  authenticate within the same selection. Other security failures, malformed
  responses and communication errors never silently choose default algorithms.

- OpenPGP card-info reads, PW1/PW3 credential operations and all
  administrative writes (reset code set/clear, retry limits, signature PIN
  policy, touch policy/cache time, admin and reset-code unblocks) use upstream
  `openpgp::operation` through the bridge. The client prepares with the minimal
  Admin probe; the profile is immutable firmware evidence, and every upstream
  operation SELECTs OpenPGP and explicitly verifies its own password. Only
  `NotFound` makes optional cardholder/URL/touch-cache objects absent; the
  pre-UIF firmware gate also stays absent without performing I/O. Credential
  rejections, blocked passwords and target-stage security rejections map to
  the UI's false result with the retained status word; other protocol and
  transport failures propagate. `ResetRetries` resets PW1/PW3 to firmware
  defaults on the card; Console caches no OpenPGP credentials, so no local
  credential invalidation is required.
- OATH selection, access-code validation, put/delete/calculate/calculate-all
  and code set/clear use upstream `oath::operation` through the bridge. The
  FRB wrappers carry an optional access key plus fresh host challenge; each
  operation SELECTs and validates within itself, so no authentication state is
  cached or reused between operations. The controller's per-use-case
  authentication only proves the code for prompting/cache policy. Legacy
  (1.3.x) versus modern dialects come from the probed firmware profile, not
  from parsing SELECT response TLVs; a legacy selection yields no synthetic
  version or salt. Calculation results keep names, digit counts, raw truncated
  bytes and HOTP/touch markers so display formatting (decimal, Steam) stays in
  Dart. Wrong codes map `AuthenticationFailed`/`DeviceAuthenticationFailed`
  (6A80 or a failed card proof) to the existing incorrect-code prompt;
  duplicate-name 6985 and storage-full statuses keep their UI mapping; other
  protocol and transport failures propagate without retry or replay.
- OATH set-default merges the former `setDefault`/`setDefaultLegacy` into one
  `oathSetDefault` call; the legacy dialect is dispatched by the upstream
  `Capability::OathSetDefaultSlots`. On legacy firmware, long slots and
  appendEnter are rejected as `InvalidArgument` at construction with zero I/O
  and the UI shows notSupported; a 6984 response maps NotFound to the
  operationFailed prompt. `OathCardClient.transceive` and the dead
  setDefaultLegacy path were removed; OATH no longer builds APDUs by hand.
- NDEF reads/writes use the profile-free `ndefReadCapability`/`ndefReadMessage`/
  `ndefWriteMessage` bindings; upstream owns SELECT, the 240-byte chunking and
  the crash-safe three-phase write. A 6A82 on SELECT yields a null read / false
  write capability, and 6982 maps to `NdefReadOnlyException`. All manual
  chunking, NLEN and capability-container parsing was removed from
  `ndef_card.dart`.
- CTAP/WebAuthn is fully upstream: the CTAP2 client-layer bindings cover every
  WebAuthn management use case — `ctapGetInfo` (options tri-states,
  forcePinChange, minPinLength and advertised pinUvAuthProtocol versions
  parsed in Rust), ClientPIN `ctapBeginPinSession`/`setPin`/`changePin`/
  `getPinTokenWithPermissions`, and credentialManagement `enumerateRps`/
  `enumerateCredentials` (including the CanoKey metadataOnly 0x80 extension)/
  `deleteCredential`. PinSession and PinToken are opaque FRB handles holding
  zeroizing Rust state; ephemeral scalars and V2 IVs are generated in the
  facade from the CSPRNG (`rand`), never supplied by Dart. For CTAP-level
  failures `ProtocolError.statusWord` carries the raw CTAP status byte widened
  to u16, not an ISO 7816 status word. Enumeration results use self-delimiting
  byte encodings; Dart never parses CBOR. The Dart `WebAuthnCardClient`
  (`lib/helper/utils/webauthn_card.dart`) decodes those encodings, prefers
  pinUvAuthProtocol V2 when advertised, and owns session/token handle
  lifecycles; every operation SELECTs the FIDO2 applet itself, so consecutive
  operations in one use case never assume a residual selection. Tokens are
  ceremony-scoped: each use case (enumeration, deletion) mints a fresh one
  instead of caching the handle, and PIN set/change is followed by a fresh
  getInfo. The Dart fido2 package, the `fido2_crypto` crate (and its C ABI in
  `lib.rs`), the `web/fido2` WASM artifacts and the raw CTAP transmitter layer
  were removed; no Dart CBOR/ClientPin framing remains.
- Pass reads/writes use `adminPassSlots` (read, not PIN-protected) and
  `adminSetPassSlot` (protected) with the same thin client shape as
  admin_card; both reuse the lease's verified Admin session when one is
  recorded and otherwise SELECT + verify an explicit per-request PIN. Unknown
  slot types display as unknown, and a write reporting `reprobeRequired`
  invalidates the profile. The manual 0043/0044 commands were removed.
- New facade bindings in `rust/src/api/protocol.rs`: `adminPassSlots`/
  `adminSetPassSlot` (including the `AdminValueKind.passSlots` encoding),
  `Access::Existing` support (the `existing` parameter) on the whole Admin
  request path (`adminRead`/`adminConfigure`/`adminAction` and the PASS slot
  operations), `pivImportPqSeed`, `oathSetDefault`, `ndefReadCapability`/
  `ndefReadMessage`/`ndefWriteMessage` and `ctapSelectApplication`/
  `ctapTransceiveSelected`/`ctapTransceive`. The CTAP2 client-layer increment
  adds `ctapGetInfo`, `ctapBeginPinSession`, the `CtapPinSession` methods
  `protocolVersion`/`setPin`/`changePin`/`getPinTokenWithPermissions`/`close`
  and the `CtapPinToken` methods `protocolVersion`/`enumerateRps`/
  `enumerateCredentials`/`deleteCredential`/`close`.

Existing UI models still map validated configuration bytes to display/algorithm
fields. Admin coverage and the specific upstream gaps are described below.

## Admin integration

Admin uses an explicit minimal probe, which observes firmware/model/serial and does
not select PIV. Its profile belongs to the physical lease and is never fabricated
from UI firmware labels. Identity reads reuse those observations; other reads use
`admin::operation`, including version-dependent configuration parsing, chip ID,
core commit, NFC state, physical/logical storage and SM2 configuration. Only an
explicit `UnsupportedFeature` makes optional core-commit/applet-usage reads absent;
security, malformed replies and unknown capabilities remain failures.

The pinned Admin facade SELECTs and verifies a PIN only when explicitly
supplied; with `Access::Existing` it sends neither and reuses the caller's
selected, already authorized transaction. Console records the evidence for
that reuse only on a successful explicit facade `VerifyPin` (itself
`existing: false`): the lease keeps an authentication stamp bound to its
selection and profile generations. Any applet selection (`willSelectApplet`),
profile invalidation, exposed or uncertain Admin mutation, failed Existing
request, or lease rebind/replacement expires the stamp, and later protected
requests fall back to `existing: false` plus an explicit per-request PIN.
The card remains the enforcement point: a wrongly assumed session surfaces as
a security rejection, which itself drops the stamp. The UI PIN cache stays
prompting/cache policy and never creates evidence. The controller's
authentication step still validates the PIN for prompting/cache policy and
leaves Admin selected for remaining legacy consumers. The settings refresh
skips its redundant re-probe while the prepared binding is still valid
(`prepareIfStale`), so one page load performs a single probe and a single
SELECT+VERIFY, with chip ID, core commit, configuration, NFC, storage and
keyboard reads reusing the session. The Pass page's explicit probe after
authentication re-selects Admin and therefore ends the evidence, so its
protected slot write keeps the per-request PIN sequence. Mutable PIN inputs
are wiped; the short-lived service copy belongs to the verified physical
lease and is cleared on rebind, release or controller disposal. A repolled
device's observed serial is checked before submitting a cached PIN.
Duplicate local/persisted PIN candidates are not automatically retried.
PIN change drops cached old credentials before the attempt; a failed or lost
acknowledgment does not restore them. Credential-cache invalidation
generations also expire page-local Admin/OATH/WebAuthn copies after reset or
PIN removal. Factory reset invalidates both saved and unsaved credentials
for that serial before the attempt; unrelated devices and preferences remain
intact.

Configuration patches, PIN change, NFC/NDEF settings, historical keyboard flags and
OpenPGP touch, SM2 writes, applet resets and factory reset now use upstream requests.
Feature changes carry only the selected mask; libcanokey reads the current device
configuration, preserves unselected fields and refuses to overwrite unknown feature
bits. Factory reset submits no PIN guesses; blocked-PIN and presence requirements
remain card-enforced. The existing request to reset is not an automatic retry.

The executor copies Admin progress before closing its handle, including after a
transport exception or cancellation. `lastProgress` retains acknowledged-write count
and `reprobeRequired`. Once a profile-affecting write is exposed, success, card
failure, malformed acknowledgment, cancellation and lost transport response all
invalidate profile evidence. Controllers explicitly prepare before a subsequent
operation; the executor never re-probes, retries, resumes or rolls back a mutation.
Multiple settings operations are not an atomic transaction. No-op patches need no
profile invalidation. A cancelled write whose acknowledgment was not processed is
exposed but unconfirmed, rather than falsely reported successful.

Each lease now tracks selection and profile-evidence generations as well as its
physical connection generation. Admin SELECT invalidates previously prepared PIV
selection; Admin configuration writes invalidate profiles held by other clients on
the same lease. Injected transports can share an explicit caller-owned `CardLease`
for the same cross-applet contract. Unknown raw commands are not classified by
parsing APDUs in Dart; remaining legacy callers still own their selection boundary.

Modern SM2 IDs use upstream signed big-endian validation and read/patch behavior.
For audited 3.0.x CanoKey devices, Console explicitly interprets the legacy packed
native i32 fields as little-endian and retains that encoding when editing them.
libcanokey validates the legacy nine-byte object without claiming portable byte
order. The result variant comes from the probed firmware, not guessed reply length.

### Upstream gaps and remaining boundaries

- **Admin selected-context operations:** converged. Protected Admin requests
  reuse `Access::Existing` while the lease holds valid recorded session
  evidence (see Admin integration above) and otherwise keep `existing: false`
  with an explicit per-request PIN. `Request::VerifyPin` never uses Existing
  (upstream rejects it), so the explicit authentication step is unchanged.
- **WebAuthn CBOR/ClientPin:** converged. The controller migrated off the
  fido2 package onto the facade's CTAP2 client layer (`ctapGetInfo`,
  `ctapBeginPinSession`, `setPin`/`changePin`/`getPinTokenWithPermissions`,
  `enumerateRps`/`enumerateCredentials`/`deleteCredential`); no Dart-side
  CBOR or ClientPin framing remains, and the `fido2_crypto` crate and its C
  ABI were removed from `lib.rs`.
- **Keyboard keymap read/write/reset (45/46/47):** migrated; these commands
  are routed through upstream Admin operations (see the existing-access
  increment below). No Dart-side raw keymap exchanges remain.
- Connection-bootstrap identity APDUs in SmartCard now use the upstream
  `admin::command::select`/`admin::command::serial` builders through the
  facade's bootstrap binding, on the same exclusive queue as before. The
  PIV macOS-setup serial read is the only remaining raw exchange in Dart.
- Firmware outside the pinned library's audited capability matrix remains
  `CapabilityUnknown`/unsupported. Console does not bypass capability checks with
  invented profiles or speculative wire formats.

## Connection and operation lifecycle

This increment follows upstream [Console integration](https://github.com/canokeys/libcanokey/blob/95e1930ea86eb248d0295bce9880cee5c65fd85e/docs/console-integration.md)
and [API contracts](https://github.com/canokeys/libcanokey/blob/95e1930ea86eb248d0295bce9880cee5c65fd85e/docs/api-design.md):

1. `SmartCard.process` queues the entire use case, including connection setup,
   SELECT, authentication, dependent commands, result publication and cleanup.
   CCID connection/probe APDUs use the same queue; reader enumeration can observe
   disconnection immediately and invalidate the active generation.
2. A lease captures the physical CCID handle or the polled NFC/WebUSB channel.
   New polls explicitly bind a new generation. A closed, failed or replaced lease
   cannot exchange or publish an executor result. A default SmartCard protocol
   executor requires a `process` scope and captures one lease for its whole loop;
   it never silently reacquires a connection between APDUs.
3. Dart owns the opaque Rust operation across each await. Generation/cancellation
   checks occur before start/exchange, after I/O and before returning owned bytes.
   Only the executor advances/closes/disposes its handle. PIV controller disposal
   requests cancellation of migrated operations, without freeing their handles.
4. Cancellation waits for outstanding I/O to settle before releasing the use-case
   lock. A transport exception poisons the lease and triggers awaited backend
   disconnect/finish, without command replay. Failed cleanup quarantines the
   channel until application restart. No Dart `Future.timeout` unlocks early.
5. PIN and forced-PIN-change prompt callbacks retain their owner zone across UI
   events. Double submits cannot overlap exchanges. Explicit re-poll replaces the
   old lease; closed dialog callbacks cannot revive a completed session.

Operation close only releases local memory. It does not log out, reconnect, undo
writes or roll back card state. Injected transports in transcript tests still own
and isolate their fake connection; they can pass an explicit lease to the executor.
Standalone legacy raw exchanges respect the queue but do not establish a multi-APDU
transaction: production use cases must keep using `SmartCard.process`. This is
application-local exclusivity; it does not add an OS-level PC/SC transaction API
to the CCID plugin.

`DeviceProfile` now lives only within a prepared physical lease; no profile or
access state is cached across use cases. PIV controller use cases explicitly prepare before dependent reads and any
authentication. An explicit SELECT invalidates the previous preparation. Raw
controller commands and selected reads also respect active operation reservations,
including with injected transports.
Injected transports use `PivCardClient.withSession` for this same ownership contract;
the USB/IP metadata smoke path has been updated accordingly.

The profile is immutable evidence, not an authentication token. Metadata factories
use `Access::Existing` without asserting PIN or management authorization. Operations
copy their required profile evidence and survive source-profile close; Dart still
checks the original lease before every exchange and publication. Cancelled or stale
probe results are closed/disposed instead of being published. Lease cleanup releases
all registered resources even when one destructor fails, and always releases the
use-case queue.

Credential and management authentication factories explicitly omit SELECT without
asserting prior authorization. There is no host authentication cache. Uncertain
credential/authentication outcomes invalidate preparation; callers must not continue
dependent work or automatically re-probe in that transaction. Controllers await
their use cases so protocol failures propagate and cancelled polling completes
without leaving pending result futures.

Key operations, certificate writes and management-key replacement in the controller
now use the upstream `Access::Existing` factories within the same reserved
transaction: signing (`piv_sign` with host-side digest/padding), X25519 derive,
ML-KEM-768 decapsulation, EC/RSA/Ed25519 key import, management-key replacement
and algorithm-configuration writes. A successful algorithm-configuration write
discards the prepared profile (upstream marks it `ReprobeRequired`). Certificate
imports go through `write_object`; libcanokey owns the 53 framing and PUT DATA
segmentation. The macOS setup serial reuses the probed Admin observation instead
of a raw Admin SELECT. Never infer access from UI PIN caches, or SELECT/probe between
authentication and its target. Host CSR construction and UI policy remain in Console.

Streaming signing and attestation complete the facade: `piv_sign_streaming`
(mode 0 = ML-DSA-65 with the empty context, 1 = randomized Ed25519 wire mode FF,
2 = SM2 full message with an optional user ID) and `piv_attest` (INS F9) both use
`Access::Existing` inside the reserved transaction. ML-DSA-65 messages and Ed25519
messages that are empty or exceed the classic 512-byte budget sign through the
streaming modes; classic digest signing (including the host-computed SM2 ZA
digest) stays with `piv_sign`. Streaming modes require evidenced 3.1.0 firmware
with observed enabled algorithm IDs, so pre-3.1 devices lose the 513–544-byte and
empty-message classic Ed25519 paths Console previously attempted. The controller
no longer builds GENERAL AUTHENTICATE or attestation APDUs. Post-quantum seed
import now uses the `pivImportPqSeed` binding with `Access::Existing` and a
prepared profile: the P1 algorithm ID comes from the probed profile, so an
unprobed PQ ID fails `CapabilityUnknown` before I/O, and the Default policy no
longer sends explicit AA/AB TLVs. `piv_post_quantum.dart`, `_sendChainedData`,
`_algorithmIdHex` and `PivCardClient.transceive` were removed; PIV contains no
hand-built APDUs.

## Verification

```sh
flutter_rust_bridge_codegen generate
cargo test --manifest-path rust/Cargo.toml api::protocol --locked
cargo build --manifest-path rust/Cargo.toml --release --locked
flutter test --no-pub test/helper/utils/piv_card_test.dart test/helper/utils/webauthn_card_test.dart
flutter test --no-pub --exclude-tags native
```

The native PIV transcript tests run alongside the WebAuthn CTAP2 tests in the
USB/IP workflow.
The firmware smoke entry point initializes FRB before the migrated PIV operations.
Native transcripts do not establish physical-device or legacy-firmware coverage.

First-increment validation on 2026-09-15 (Rust 1.98.1 / Flutter 3.47.1): all 35 Rust tests,
292 non-native Dart/UI tests and 19 native PIV/FIDO2 tests passed. The generated
bridge built natively, `cargo check --target wasm32-unknown-unknown` and
`flutter build web --no-pub` passed. Changed Dart files passed analysis and the
workflow passed actionlint. Strict Clippy encountered the existing
`chunks_exact_to_as_chunks` lint in `rust/src/api/decode.rs:10`; all-target Clippy
passed with only that lint allowed. Repository-wide rustfmt also reports existing
formatting in `piv_crypto.rs`; the new protocol module passes rustfmt. No physical
card, browser transport session or USB/IP firmware matrix was run locally.

Certificate/session increment validation on 2026-09-15: 37 Rust tests, 303
non-native Dart/UI tests and 21 native PIV/FIDO2 tests passed. Coverage includes
exclusive use cases, expired callback leases, late responses after disconnect,
cancellation during I/O, poisoned transports, invalid/duplicate certificate TLVs,
gzip CRC/trailing-data failures and decompression limits. Changed Dart files passed
analysis, native release build and wasm32 check passed, and the FRB WASM package
and Flutter web application both built. The web helper initially hit the known
host-linker-flags failure; rebuilding with a temporary wasm-bindgen-cli 0.2.100
installation resolved it without replacing the global tool. No physical-card,
browser transport or USB/IP firmware matrix was exercised for this increment.

Profile/metadata increment validation on 2026-09-15: all 39 Rust tests and 306
non-native Dart/UI tests passed. The final focused run passed 56 tests, including
28 native PIV/FIDO2 tests and session, executor, metadata model and controller
coverage. It verifies profile ownership and disposal, operation-wide exclusion,
failed re-probes, metadata after authentication without SELECT, legacy firmware
responses, malformed metadata and algorithm resolution against the current device
profile rather than cached UI configuration. Changed handwritten Dart files passed
analysis; the protocol module passed rustfmt and the diff passed whitespace checks.
The native release, wasm32 check, regenerated FRB WASM package and final Flutter web
application build passed. No physical-card, browser transport or USB/IP firmware
matrix was exercised for this increment.

Credential/authentication increment validation on 2026-09-15: all 42 Rust tests,
300 non-native Dart/UI tests and 53 focused session/executor/native tests passed
(34 native PIV/FIDO2 tests). Six obsolete Dart authentication-builder tests were
removed with the unused implementation; native transcripts now exercise the
upstream authentication path, including TDES/AES known-answer vectors, legacy Le,
concurrent-command exclusion, malformed challenges, credential references/retries,
terminal mutation failures and profile invalidation. After updating controller
completion handling, its 81 controller/view tests also passed. Changed handwritten
Dart files passed analysis, the protocol module passed rustfmt, and the diff passed
whitespace checks. Native release, the regenerated FRB WASM package and Flutter web
application built successfully. No physical-card, browser transport or USB/IP
firmware matrix was exercised for this increment.

Admin increment validation on 2026-09-15: all 44 Rust tests, 290 non-native Dart/UI
tests and 76 focused native/session/executor tests passed (57 native tests across
Admin, applet switches, PIV and FIDO2). The final selected-app publication checks
passed another 48 Admin/PIV tests. Coverage includes explicit per-request PINs,
legacy configuration and SM2 layouts, masked/no-op patches, retained partial-write
progress, cancellation/lost responses, no mutation replay, cross-applet selection
and profile invalidation, and cross-page credential-cache invalidation. Changed
handwritten Dart files passed analysis, the protocol module passed rustfmt and the
diff passed whitespace checks. Native release, regenerated FRB WASM and Flutter web
builds passed. The native workflow includes the new Admin/applet-switch tests; its
YAML parses successfully. No physical-card, browser transport or USB/IP firmware
matrix was exercised locally.

## Existing-access increment and ownership boundary

All libcanokey Cargo crates now pin `95e1930e` (including protocol and admin). The removed upstream selected-context
allocation has been replaced by `Access::Existing` or explicit `select=false`.
No profile is an authentication token: Console retains the physical lease,
selection/profile generation checks, operation ownership and cancellation cleanup.

Console's executor records whether an exchange was attempted separately from the
upstream protocol error. This local fact governs whether failed prepared operations
may retain their lease evidence; protocol phase is not an I/O receipt. Expected
credential rejections and absent object reads retain their documented handling.

Confirmed upstream issue: object/certificate reads at this revision can report
`InvalidResponse/Construction` for malformed outer containers returned by the
card. The missing `Parsing` annotation belongs to canokey-piv. A separate local
The pinned revision includes the PIV object parsing phase fix; Console performs
no protocol error remapping. Profile-free selected PIN status remains an upstream API gap in this revision; Admin existing-selection requests are available at the current pin and now carry Console's lease-evidenced Admin session reuse (see Admin integration). Keyboard layout/keymap reads and writes are now routed through upstream Admin operations.

Validation for this increment: 44 Console Rust tests, 290 non-native Dart/UI tests,
82 focused native/session/executor tests and a final 46-test PIV/executor run passed.
Native release, regenerated FRB WASM and final Flutter Web builds passed; changed
handwritten Dart files passed analysis. The upstream regression failed before the
fix, then all 67 canokey-piv tests (including doctests) and strict workspace/all-target
clippy passed. Neither repository was tested with physical hardware or the USB/IP
firmware matrix in this increment. The libcanokey fix is committed locally only.

OpenPGP increment validation on 2026-09-16: the 12 focused OpenPGP card tests
(native transcripts over injected transports) and the 12 OpenPGP page tests
passed, and changed Dart files passed analysis. The wider non-native suite
passed 260 tests with 5 pre-existing OATH compile-failure suites untouched by
this increment (`oath_card.dart` belonged to the parallel OATH migration). The
host needed an `xcrun` shim exporting `DEVELOPER_DIR` for the Command Line
Tools SDK because the Xcode license prompt breaks the objective_c native-asset
hook.

OpenPGP administrative-writes increment validation on 2026-09-16: the bridge
gained `openpgp_write_reset_code` (Option clears), `openpgp_reset_retries`,
`openpgp_write_signature_pin_policy`, `openpgp_unblock_with_admin`,
`openpgp_unblock_with_code`, `openpgp_write_touch_policy` and
`openpgp_write_touch_cache_time`; all seven Console operations moved off raw
APDUs, and the client's manual SELECT/PUT DATA/RESET RETRY COUNTER builders
were removed. All 53 Rust tests passed, including new wire-byte, argument
validation, capability-gate (UIF from 1.5.2, retry reset from 3.1.0) and
credential-reference/reset-code error-mapping coverage. After FRB
regeneration, the 14 native OpenPGP card tests plus focused PIV/Admin native
suites and the 12 OpenPGP page tests passed (81 tests), changed handwritten
Dart files passed analysis, and `cargo build --release --locked` passed.
Reset-code clearing is a dataless PUT DATA D3 (no Lc) on the wire, matching
upstream framing. The USB/IP smoke harness keeps its session/prepare flow
but was not run locally; no physical card, browser transport or USB/IP
firmware matrix was exercised.

OATH increment validation on 2026-09-16: all 53 Rust tests passed, including
new protocol-module coverage for per-operation access validation, protected
applet rejection before the target command, the name/marker-preserving
calculation encoding and the legacy 1.3 dialect gate. The 9 native OATH card
tests (injected-transport transcripts with canokey-oath known-answer HMACs),
the OATH model/view tests and the full non-native suite (276 tests) passed, as
did the focused native PIV/Admin/session/executor suites (74 tests) after the
FRB regeneration. Changed Dart files passed analysis; `cargo build --release
--locked` passed. FRB WASM regeneration and the Flutter web build were not run
locally, and no physical card, browser transport or USB/IP firmware matrix was
exercised.

PQ-import/OATH-set-default/NDEF/CTAP/Pass increment validation on 2026-09-16:
the pin moved to `95e1930e`, which brings the new canokey-ctap and canokey-ndef
crates plus upstream PIV PQ seed import, OATH SetDefault, Admin
PassSlots/SetPassSlot and `admin::Access::Existing`/`operation_with_access`.
`cargo test --locked` passed in full (65 tests, including 9 new facade-binding
tests). New native-transcript Dart tests: 4 PIV PQ, 6 OATH set-default, 10
NDEF, 11 CTAP and 8 Pass. The full `flutter test` suite passed (376 tests).
The FRB WASM package was regenerated and `flutter build web --no-pub` passed
(host-side wasm-bindgen-cli 0.2.100 pre-installed to dodge the known
host-linker-flags leak from the wasm RUSTFLAGS). The USB/IP firmware
matrix and physical-card runs were not exercised for this increment.

Admin existing-access increment validation on 2026-09-16: the `existing`
parameter now reaches `adminRead`/`adminConfigure`/`adminAction`, and Console
records lease-bound Admin session evidence only on an explicit facade
`VerifyPin`, stamped with the lease's selection/profile generations.
Protected requests reuse `Access::Existing` while that evidence is valid and
fall back to `existing: false` plus an explicit per-request PIN after any
applet selection, profile invalidation, exposed/uncertain mutation, failed
Existing request or lease replacement. `cargo test --locked` passed in full
(66 tests, including existing-access wire coverage for the three general
Admin entries). 124 native-tagged Dart tests passed, including new
transcripts asserting that Existing requests send no SELECT/VERIFY, that a
confirmed mutation, a cross-applet selection (PIV probe) and a failed
Existing request each end the evidence, and that the Pass client's own probe
on a shared lease ends another client's recorded session. The non-native
suite passed (257 tests, including the lease-evidence generation unit tests
and the settings configuration tests against the `prepareIfStale` refresh).
Changed Dart files passed analysis and the protocol module passes rustfmt.
After this increment the FRB WASM package was regenerated again and
`flutter build web --no-pub` passed, strict clippy is warning-free and the
full `flutter test` run passed (381 tests). No physical card, browser
transport or USB/IP firmware matrix was exercised for this increment.

CTAP2 client-layer increment validation on 2026-09-16: `cargo test --locked`
passed in full (74 tests, including 8 new facade tests covering the getInfo
field encoding and tri-states, golden ClientPIN wire bytes for V1/V2 against
the upstream known answers, fresh-IV generation, pinUvAuthToken handles,
RP/credential enumeration encodings including the metadataOnly extension,
deleteCredential, and raw-CTAP-status error mapping). FRB 2.13.0 regeneration,
`cargo build --release --locked` and `cargo check --target
wasm32-unknown-unknown --locked` passed (`rand` moved to `[dependencies]`;
wasm entropy still comes from getrandom's wasm_js feature). Dart business
code is untouched; the controller migration is a follow-up increment.

## Card-client boilerplate consolidation (2026-09-16)

A pure-Dart, behavior-preserving refactoring after the applet migrations: the
six card clients now share `CardClientBase` (transport/lease guard,
`withSession`, cancellation) and `ProfileCardClient` (prepared-profile
ownership, generic `prepareProfile` and `executePrepared` with per-applet
flags for applet pre-selection, profile-identity checks and profile-discard
policy) in `lib/helper/utils/card_client.dart`, plus one `ProfileBinding`
class (lease + profile generation, optionally the selection generation for
PIV) replacing the five per-applet binding classes. Admin and Pass share
`AdminSessionCardClient` (in admin_card.dart) for the lease-evidenced
`Access::Existing` request path and Admin progress handling; NDEF stays
profile-free on `CardClientBase`. Admin/Pass `lastResponse` was renamed to
`lastStatusWord` for uniformity (the three controller call sites updated).
No protocol flow, lease/profile/selection generation check, error mapping or
public API semantics changed; the existing card-client, session, executor and
native transcript suites pin the behavior. `dart analyze` reports no issues
in the changed files, and the full `flutter test --no-pub` (383 tests) and
`flutter test --no-pub --tags native` (126 tests) runs passed.

## WebAuthn CTAP2 client-layer migration (2026-09-16)

The WebAuthn controller migrated off the Dart fido2 package onto the facade's
CTAP2 client layer. `lib/helper/utils/webauthn_card.dart` (a `CardClientBase`)
parses the getInfo/RP/credential byte encodings, owns the PIN session/token
handle lifecycles (fresh `beginPinSession` + `getPinTokenWithPermissions` per
use case, pinUvAuthProtocol V2 preferred when advertised) and marks every
operation as applet-selecting; `protocol_operation.dart` gained PIN
session/token executors. `_showPinError` recovers the PIN_INVALID (0x31) /
PIN_AUTH_BLOCKED (0x34) / PIN_BLOCKED (0x32) / PIN_POLICY_VIOLATION (0x37)
distinction from the raw CTAP status byte in `ProtocolError.statusWord`.
`WebAuthnItem.credentialId` is a local `Uint8List`. Removed: the fido2 2.0.0
pub dependency, `fido2_backend*.dart`, `ctap_transmitter.dart`, the
`initializeFido2Backend` startup calls, the `web/fido2` WASM artifacts and
their `index.html` loader, the `fido2_crypto` crate and its retained C ABI in
`rust/src/lib.rs`, and the FIDO2 web backend steps in deploy.yml (the usbip
workflow's backend step no longer exports `FIDO2_CRYPTO_LIBRARY`). The
wasm-bindgen family pins stay, with the comment reworded; FRB bindings were
not regenerated (no facade change).

Validation: `cargo test --locked` (74 tests), `cargo build --release --locked`
and `cargo check --target wasm32-unknown-unknown --locked` passed;
THIRD_PARTY_LICENSES.json regenerated without fido2_crypto. The new
`test/helper/utils/webauthn_card_test.dart` replays the upstream canokey-ctap
golden transcripts over injected transports (getInfo tri-states/minPinLength/
protocols, V1/V2 key agreement, set/changePIN, token minting, RP/credential
enumeration encodings, deletion, empty-enumeration, closed-handle and
status-byte error mapping); the old fido2_backend/ctap_transmitter tests were
removed. `flutter test --no-pub` passed (387 tests, including the updated
WebAuthn page/model tests and the usbip smoke's new `webauthn.client.get_info`
section), `flutter test --no-pub --tags native` passed (130 tests), and
`dart analyze` reports no issues. `flutter build web --no-pub` passed with no
fido2 reference left in the web output. The FRB WASM package was not
regenerated (no Rust facade change); no physical card, browser transport or
USB/IP firmware matrix was exercised.

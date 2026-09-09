# PIV certificates for macOS login

Console uses a two-slot setup: 9A authenticates the user, and 9D supplies the
private-key operation used to wrap/unwrap the login keychain key. Creating a
9A authentication certificate alone must not be reported as completing this
setup. The Mac still performs account pairing and applies its local trust policy.

## Evidence and limits

- On macOS 26.6.2, `sc_auth identities` enumerated the user's 9A P-256 certificate
  as an unpaired identity. Its Key Usage was only `digitalSignature`.
- In the same state, `sc_auth pairing_ui -f` reached `ctkbind`, which logged
  `updateTokenCache ... (requireWrapKey: 1)`, then
  `No RSA decryption key or ECDH key was found for token`, then
  `no unpaired identities found`. The UI was enabled. Enumeration alone therefore
  did not establish eligibility for the pairing UI.
- [Yubico's macOS provisioning guide](https://developers.yubico.com/PIV/Guides/Smart_card-only_authentication_on_macOS.html)
  explicitly provisions keys and self-signed certificates in both 9A and 9D.
  Its `ykman` self-signed certificates omit Key Usage, rather than restricting 9D
  to signing. Console emits explicit, role-appropriate Key Usage instead.
- The local CanoKey firmware's `piv_general_authenticate` implementation supports
  the RSA private-key operation and ECDH (SP800-73-4 Part 2 Appendix A.5).
  PIN policy is checked before either operation. The standard key-management
  slot is 9D.

The log establishes the missing capability; it does not establish that every
macOS version or every smart-card driver requires exactly these two slots. This
is the documented provisioning layout Console chooses, not a claim that 9D is
the only possible implementation. Tests below do not substitute for a real
macOS pairing and keychain-unlock test.

## Presets

| Slot | Algorithm | Key Usage (critical) | EKU | Basic Constraints | PIN |
| --- | --- | --- | --- | --- | --- |
| 9A | P-256 / RSA-2048 | digitalSignature | clientAuth | CA=false | once |
| 9D | P-256 | keyAgreement | omitted | CA=false | once |
| 9D | RSA-2048 | keyEncipherment | omitted | CA=false | once |

The preset keeps an already selected RSA-2048 algorithm; otherwise it selects
P-256. Subject, validity and touch policy are preserved. Setting 9D's EKU to
clientAuth would unnecessarily restrict a keychain-wrapping credential, so the
9D preset clears EKU. Changing algorithm or extensions afterwards updates the
preset indicator to custom whenever the selected slot's profile no longer matches.

## Standalone setup

The slot manager's “Set up Mac login” button inspects 9A and 9D before writing.
It preserves compatible certificates, reuses P-256/RSA-2048 keys when only a
certificate is needed, and creates P-256 keys for empty slots. Replacing a
certificate or unsupported key requires accepting the listed replacements.
New certificates are self-signed and valid for 365 days. Reused keys retain
PIN/touch policies; new keys use PIN once and no touch requirement.

The operation rereads the physical serial and slot contents before writing,
and rereads both certificates before reporting completion. A failed run can
be inspected again and resumed without replacing the successfully configured
slot. Firmware without key metadata is refused because an absent key cannot
be established safely. Missing certificate status 6A82 and missing key status
6A88 are handled separately from communication or permission failures.

The per-certificate extension presets still edit only the current form.
Completion means CanoKey configuration was checked, not that Mac trust,
account pairing, or login was tested.

## Verification

- Model/widget tests cover all four slot/algorithm combinations, the two-slot
  instructions, preserved user choices, and navigation without automatic writes.
- Full self-sign dialog tests verify the settings passed to the controller.
- Rust tests parse the resulting authentication and key-management certificates
  and check KU, EKU and Basic Constraints. The authentication certificate test
  also verifies a real signature.
- Hardware acceptance: configure both roles, reinsert CanoKey, inspect
  `system_profiler SPSmartCardsDataType` and `sc_auth identities`, then pair and
  verify login/keychain access. Certificate trust and account policy remain Mac
  settings. This investigation did not replace any keys on the user's device.

# Xiaomi release automation

`tool/xiaomi_release.py` downloads the Google Play-signed universal APK for
CanoKey Console and submits version updates to the mainland China Xiaomi app
store. Updates include only the required app information, release notes, APK
and icon. Screenshots and other optional metadata are omitted from the update
example.

## Prerequisites

- Python 3.11 or newer, Java, and Android SDK Build Tools containing `apksigner`
  and `aapt2`.
- A Google Play service account with Android Publisher API access to
  `org.canokeys.console`. Upload the release AAB to Play and wait for APK
  generation before downloading it.
- A Xiaomi developer account managing the same package name, with the required
  app qualifications and contact details completed in the developer console.
- Xiaomi automatic publishing API credentials and the public X.509 certificate
  supplied by Xiaomi.

Keep credentials outside the repository. By default, the script reads
`~/.config/canokey-release/google-play.json` and
`~/.config/canokey-release/xiaomi.json`; override these paths with `--play-key`
and `--credentials`.

Copy `tool/xiaomi-credentials.example.json` to the Xiaomi credentials path and
replace its placeholder values:

```json
{
  "user_name": "developer@example.com",
  "api_key": "YOUR_XIAOMI_API_ACCESS_KEY",
  "public_certificate": "xiaomi-public.pem"
}
```

`api_key` is the API access key supplied by Xiaomi, not the account password or
an APK signing key. The certificate path is relative to the credentials JSON,
or can be absolute. Restrict access to credential files, for example with
`chmod 600` on Unix systems.

## Submit an update

Run from the repository root:

```sh
python3 -m venv .venv-xiaomi
.venv-xiaomi/bin/python -m pip install -r tool/requirements-xiaomi-release.txt

# Replace with the versionCode of the AAB uploaded to Play.
VERSION_CODE=28

.venv-xiaomi/bin/python tool/xiaomi_release.py download \
  --version-code "$VERSION_CODE" \
  --output dist/android/play-signed/universal.apk
```

The downloader writes the verified APK and a JSON checksum manifest. It rejects
existing output files; use a fresh `--output` path for subsequent downloads and
update the configuration accordingly.

Place the reviewed release notes in `dist/xiaomi/release-notes.txt`.
`tool/xiaomi-update.example.json` references this file, the downloaded APK and
the repository's app icon. All paths in that configuration are relative to the
configuration file. Copy it to customize paths when needed.

```sh
# Local validation; does not require Xiaomi credentials or submit anything.
.venv-xiaomi/bin/python tool/xiaomi_release.py plan \
  --version-code "$VERSION_CODE" --config tool/xiaomi-update.example.json

# Query the latest package details and permitted operations.
.venv-xiaomi/bin/python tool/xiaomi_release.py query \
  --version-code "$VERSION_CODE"

# Submit the update for review.
.venv-xiaomi/bin/python tool/xiaomi_release.py submit \
  --version-code "$VERSION_CODE" --config tool/xiaomi-update.example.json
```

The default Build Tools path is `$ANDROID_HOME/build-tools/36.0.0`, falling back
to the standard macOS SDK location. Pass `--build-tools /path/to/build-tools/version`
for other installations.

## Validation and API behavior

- The APK must match the package name, requested versionCode, and pinned public
  Play app-signing certificate fingerprint. Validation uses `apksigner` and
  `aapt2`, and requires ARM64 support and a standalone APK.
- Downloads select the matching signing group from Play's generated APK
  metadata. A missing or ambiguous universal APK fails validation. The script
  never builds or re-signs a replacement APK.
- `--certificate` selects a different expected fingerprint for a signing-key
  rotation. Check compatibility with existing Xiaomi installations before
  changing it.
- Xiaomi requests use HTTPS, streaming multipart uploads and the documented
  MD5/RSA PKCS#1 v1.5 request authentication. Credentials and test accounts are
  excluded from local plan output.
- The update example uses `synchroType=1`. It omits optional fields, including
  versionName; the API reads versionName from the APK. If specified explicitly,
  versionName must match the APK.
- The script also supports initial submissions (`synchroType=0`), which require
  additional app information and screenshots. The API requires the first three
  phone screenshots, and four tablet screenshots when tablets are selected.
  The web creation guide separately requires at least four phone screenshots.
- Before submission, the script checks Xiaomi's permitted-operation flags and
  rejects updates to the same or a lower versionCode. Uploads are not retried
  automatically: after a timeout, inspect the developer console before retrying.
- Xiaomi has no public sandbox or review-status endpoint. A successful push
  confirms submission, not approval. `query` reports package details and
  operation flags; use the developer console to check review status.

## Official documentation

- [Xiaomi automatic publishing API](https://dev.mi.com/xiaomihyperos/documentation/detail?pId=1134)
- [Xiaomi app creation guide](https://dev.mi.com/xiaomihyperos/documentation/detail?pId=1072)
- [Xiaomi publishing FAQ](https://dev.mi.com/xiaomihyperos/documentation/detail?pId=1141)
- [Google generatedapks.list](https://developers.google.com/android-publisher/api-ref/rest/v3/generatedapks/list)
- [Google generatedapks.download](https://developers.google.com/android-publisher/api-ref/rest/v3/generatedapks/download)

#!/usr/bin/env python3
"""Download verified Play APKs and submit them through Xiaomi's public API."""
import argparse
import base64
from contextlib import ExitStack
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import time
from urllib.parse import quote

import requests
from requests_toolbelt.multipart.encoder import MultipartEncoder
from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding

PACKAGE = 'org.canokeys.console'
# Public SHA-256 fingerprint of the CanoKey Console Play app-signing certificate.
PLAY_CERT = 'b971be28ac5fbefdb80590d85aa80ce8bbd3cf793e0e515d173011849328d01a'
XIAOMI = 'https://api.developer.xiaomi.com/devupload/dev/'
PLAY = 'https://androidpublisher.googleapis.com/androidpublisher/v3/applications/'


def encoded(value):
    return json.dumps(value, ensure_ascii=False, separators=(',', ':')).encode('utf-8')


def digest(path, algorithm='sha256'):
    with Path(path).open('rb') as stream:
        return hashlib.file_digest(stream, algorithm).hexdigest()


def fingerprint(value):
    value = value.replace(':', '').lower()
    if not re.fullmatch('[0-9a-f]{64}', value):
        raise ValueError('Invalid SHA-256 certificate fingerprint')
    return value


def response_json(response):
    # Never print a request, auth headers, response body or credential-bearing URL.
    if not response.ok:
        raise ValueError(f'API returned HTTP {response.status_code}; inspect the provider console')
    return response.json()


def play_token(path):
    credentials = json.loads(Path(path).expanduser().read_text())
    now = int(time.time())
    def b64(data):
        return base64.urlsafe_b64encode(data).rstrip(b'=')
    message = b'.'.join(b64(encoded(v)) for v in [
        {'alg': 'RS256', 'typ': 'JWT'},
        {'iss': credentials['client_email'], 'scope': 'https://www.googleapis.com/auth/androidpublisher',
         'aud': 'https://oauth2.googleapis.com/token', 'iat': now, 'exp': now + 3600}])
    key = serialization.load_pem_private_key(credentials['private_key'].encode(), password=None)
    assertion = message + b'.' + b64(key.sign(message, padding.PKCS1v15(), hashes.SHA256()))
    return response_json(requests.post('https://oauth2.googleapis.com/token', data={
        'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        'assertion': assertion.decode()}, timeout=60))['access_token']


def select_universal(metadata, certificate):
    candidates = [g['generatedUniversalApk']['downloadId'] for g in metadata.get('generatedApks', [])
                  if fingerprint(g['certificateSha256Hash']) == fingerprint(certificate)
                  and g.get('generatedUniversalApk', {}).get('downloadId')]
    if len(candidates) != 1:
        raise ValueError('Expected exactly one universal APK signed by the pinned Play key; no local fallback')
    return candidates[0]


def verify(apk, version_code, build_tools, certificate=PLAY_CERT):
    signed = subprocess.run([str(build_tools / 'apksigner'), 'verify', '--print-certs', str(apk)],
                            check=True, capture_output=True, text=True).stdout
    certs = re.findall(r'^Signer #\d+ certificate SHA-256 digest: (\S+)', signed, re.M)
    if [fingerprint(c) for c in certs] != [fingerprint(certificate)]:
        raise ValueError('APK signer does not match the pinned Google Play app-signing certificate')
    badging = subprocess.run([str(build_tools / 'aapt2'), 'dump', 'badging', str(apk)],
                             check=True, capture_output=True, text=True).stdout
    package = re.search(r"^package: name='([^']+)' versionCode='(\d+)' versionName='([^']+)'", badging, re.M)
    if not package or package[1] != PACKAGE or int(package[2]) != version_code:
        raise ValueError('APK package name or versionCode mismatch')
    if "split='" in badging.splitlines()[0] or "'arm64-v8a'" not in badging:
        raise ValueError('Expected a standalone APK with arm64-v8a support')
    return {'packageName': package[1], 'versionCode': int(package[2]), 'versionName': package[3],
            'certificateSha256': fingerprint(certificate), 'sha256': digest(apk)}


def download(args):
    out = args.output.resolve()
    out.parent.mkdir(parents=True, exist_ok=True)
    if out.exists() or out.with_suffix('.json').exists():
        raise ValueError('Output already exists; choose a fresh path')
    headers = {'Authorization': 'Bearer ' + play_token(args.play_key)}
    url = PLAY + PACKAGE + '/generatedApks/' + str(args.version_code)
    metadata = response_json(requests.get(url, headers=headers, timeout=60))
    download_id = select_universal(metadata, args.certificate)
    url += '/downloads/' + quote(download_id, safe='') + ':download?alt=media'
    with tempfile.TemporaryDirectory(dir=out.parent) as tmp:
        apk = Path(tmp) / 'universal.apk'
        with requests.get(url, headers=headers, timeout=(30, 180), stream=True) as response:
            if not response.ok:
                raise ValueError(f'Play download returned HTTP {response.status_code}')
            with apk.open('wb') as stream:
                for chunk in response.iter_content(1024 * 1024):
                    stream.write(chunk)
        manifest = verify(apk, args.version_code, args.build_tools, args.certificate)
        manifest['source'] = 'Google Play generatedApks.download'
        apk.replace(out)
    out.with_suffix('.json').write_bytes(encoded(manifest) + b'\n')
    print(json.dumps({'apk': str(out), **manifest}, ensure_ascii=False, indent=2))


def encrypt_sig(request_data, files, password, certificate):
    sig = [{'name': 'RequestData', 'hash': hashlib.md5(request_data).hexdigest()}]
    sig += [{'name': name, 'hash': digest(path, 'md5')} for name, path in files.items()]
    plaintext = encoded({'sig': sig, 'password': password})
    key = x509.load_pem_x509_certificate(Path(certificate).read_bytes()).public_key()
    block_size = key.key_size // 8 - 11
    return b''.join(key.encrypt(plaintext[i:i + block_size], padding.PKCS1v15())
                    for i in range(0, len(plaintext), block_size)).hex()


def xiaomi_call(operation, credentials, data, files=None):
    files = files or {}
    raw = encoded(data)
    sig = encrypt_sig(raw, files, credentials['api_key'], credentials['public_certificate'])
    with ExitStack() as stack:
        attachments = {k: (p.name, stack.enter_context(p.open('rb'))) for k, p in files.items()}
        multipart = MultipartEncoder(fields={'RequestData': raw.decode(), 'SIG': sig, **attachments})
        response = requests.post(XIAOMI + operation, data=multipart,
                                 headers={'Content-Type': multipart.content_type},
                                 timeout=(30, 600), allow_redirects=False)
        result = response_json(response)
    if result.get('result') != 0:
        raise ValueError(f"Xiaomi error {result.get('result')}; consult official error-code table/console")
    return result


def load_credentials(path):
    path = path.expanduser().resolve()
    credentials = json.loads(path.read_text())
    cert = Path(credentials['public_certificate']).expanduser()
    credentials['public_certificate'] = str(cert if cert.is_absolute() else path.parent / cert)
    return credentials


def prepare(config_path, args):
    config_path = config_path.resolve()
    config = json.loads(config_path.read_text())
    kind = config['synchroType']
    if kind not in (0, 1):
        raise ValueError('Only new releases (0) and version updates (1) are supported')
    info = config['appInfo'].copy()
    if info.get('packageName') != PACKAGE:
        raise ValueError('Incorrect packageName')
    required = ['appName', 'privacyUrl'] + (['category', 'keyWords', 'desc', 'brief'] if kind == 0 else [])
    if any(not info.get(k) for k in required):
        raise ValueError('Missing required appInfo: ' + ', '.join(required))
    test_account = info.get('testAccount')
    if test_account is not None:
        if not isinstance(test_account, dict) or not isinstance(test_account.get('zh_CN'), dict):
            raise ValueError('testAccount must use the 2026 structured zh_CN object')
        info['testAccount'] = encoded(test_account).decode()
    notes = config.get('releaseNotes')
    if notes:
        info['updateDesc'] = (config_path.parent / notes).read_text().strip()
    if kind == 1 and not info.get('updateDesc'):
        raise ValueError('Version updates require releaseNotes or updateDesc')
    files = {k: (config_path.parent / v).resolve() for k, v in config['files'].items()}
    allowed = {'apk', 'icon'} | {f'screenshot_{n}' for n in range(1, 6)} | {f'screenshot_pad_{n}' for n in range(1, 6)}
    if files.keys() - allowed:
        raise ValueError('Unsupported attachment; use the unmodified universal APK')
    required_files = ['apk', 'icon']
    if kind == 0:
        required_files += [f'screenshot_{n}' for n in range(1, 4)]
        if info.get('suitableType', 0) in (1, 2):
            required_files += [f'screenshot_pad_{n}' for n in range(1, 5)]
    if any(k not in files for k in required_files):
        raise ValueError('Missing required files: ' + ', '.join(required_files))
    for path in files.values():
        if not path.is_file() or path.stat().st_size == 0:
            raise ValueError(f'Missing/empty file: {path}')
    for name, path in files.items():
        if name == 'apk':
            continue
        with path.open('rb') as image:
            header = image.read(24)
        if header[:8] != b'\x89PNG\r\n\x1a\n' or header[12:16] != b'IHDR':
            raise ValueError(f'{name} must be a PNG')
        dimensions = (int.from_bytes(header[16:20], 'big'), int.from_bytes(header[20:24], 'big'))
        if name == 'icon' and dimensions != (512, 512):
            raise ValueError('Icon must be 512 x 512')
        if name.startswith('screenshot_') and not name.startswith('screenshot_pad_'):
            if dimensions not in ((1080, 1920), (1920, 1080)) or path.stat().st_size > 5 * 1024 * 1024:
                raise ValueError('Phone screenshots must be 1080 x 1920 or 1920 x 1080 PNG, <= 5 MiB')
    manifest = verify(files['apk'], args.version_code, args.build_tools, args.certificate)
    if info.get('versionName', manifest['versionName']) != manifest['versionName']:
        raise ValueError('appInfo versionName does not match APK')
    return kind, info, files, manifest


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('command', choices=['download', 'plan', 'submit', 'query', 'categories'])
    parser.add_argument('--version-code', type=int, required=True)
    parser.add_argument('--certificate', default=PLAY_CERT)
    parser.add_argument('--build-tools', type=Path, default=Path(os.environ.get('ANDROID_HOME',
                        str(Path.home() / 'Library/Android/sdk'))) / 'build-tools/36.0.0')
    parser.add_argument('--play-key', default=str(Path.home() / '.config/canokey-release/google-play.json'))
    parser.add_argument('--credentials', type=Path, default=Path.home() / '.config/canokey-release/xiaomi.json')
    parser.add_argument('--config', type=Path)
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    if args.version_code <= 0:
        parser.error('--version-code must be positive')
    if args.output is None:
        args.output = Path(f'dist/android/play-signed/canokey-console-{args.version_code}.apk')
    if args.command == 'download':
        download(args)
    elif args.command == 'categories':
        print(json.dumps(response_json(requests.post(XIAOMI + 'category', timeout=60)), ensure_ascii=False, indent=2))
    elif args.command == 'query':
        credentials = load_credentials(args.credentials)
        result = xiaomi_call('query', credentials, {'userName': credentials['user_name'], 'packageName': PACKAGE})
        print(json.dumps(result, ensure_ascii=False, indent=2))
    else:
        if args.config is None:
            parser.error('--config is required')
        kind, info, files, manifest = prepare(args.config, args)
        if args.command == 'plan':
            print(json.dumps({'synchroType': kind, 'artifact': manifest,
                              'attachments': list(files), 'updateDesc': info.get('updateDesc'),
                              'submission': 'not sent'},
                             ensure_ascii=False, indent=2))
            return
        credentials = load_credentials(args.credentials)
        query = xiaomi_call('query', credentials, {'userName': credentials['user_name'], 'packageName': PACKAGE})
        existing = query.get('packageInfo') or {}
        if kind == 1 and int(existing.get('versionCode', -1)) >= args.version_code:
            raise ValueError('Same/newer version already pushed; inspect console instead of submitting again')
        if not query.get('create' if kind == 0 else 'updateVersion'):
            raise ValueError('Xiaomi does not permit this operation; inspect app/qualification state in console')
        xiaomi_call('push', credentials, {'userName': credentials['user_name'],
                    'synchroType': kind, 'appInfo': encoded(info).decode()}, files)
        print('Submitted to Xiaomi for review. Check the developer console for approval status.')


if __name__ == '__main__':
    try:
        main()
    except (ValueError, KeyError, OSError, subprocess.CalledProcessError, requests.RequestException) as error:
        # Transport exceptions can embed credentials or download IDs. Keep output minimal.
        message = str(error) if isinstance(error, ValueError) and not isinstance(error, requests.RequestException) else type(error).__name__
        print('Error: ' + message, file=sys.stderr)
        sys.exit(1)

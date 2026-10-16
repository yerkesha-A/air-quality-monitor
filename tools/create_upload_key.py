"""Explicit owner-approved local signing setup. Never print secret values."""
from pathlib import Path
import os
import secrets
import subprocess

root = Path(__file__).resolve().parents[1]
folder = Path('/Users/erkezhanabdraim/Documents/AirQualitySigning')
keystore = folder / 'air-quality-upload.p12'
private_config = folder / 'upload-signing.properties'
android_config = root / 'android/key.properties'
if any(p.exists() for p in [keystore, private_config, android_config]):
    raise SystemExit('Existing signing material found; no file overwritten.')
folder.mkdir(mode=0o700, parents=True, exist_ok=True)
folder.chmod(0o700)
password = secrets.token_urlsafe(36)
env = dict(os.environ, AQM_UPLOAD_PASSWORD=password)
keytool = '/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool'
result = subprocess.run([keytool, '-genkeypair', '-keystore', str(keystore),
    '-storetype', 'PKCS12', '-alias', 'air-quality-upload', '-keyalg', 'RSA',
    '-keysize', '3072', '-validity', '10000', '-storepass:env', 'AQM_UPLOAD_PASSWORD',
    '-keypass:env', 'AQM_UPLOAD_PASSWORD', '-dname',
    'CN=Air Quality Monitor Upload, OU=Mobile, O=Air Quality Monitor, C=KZ'],
    env=env, capture_output=True)
if result.returncode:
    raise SystemExit('Keytool failed; private output withheld. No signing configuration created.')
keystore.chmod(0o600)
content = f'storeFile={keystore}\nstorePassword={password}\nkeyAlias=air-quality-upload\nkeyPassword={password}\n'
for target in [private_config, android_config]:
    fd = os.open(target, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(fd, 'w') as handle:
        handle.write(content)
print('Private upload key created outside the repository; signing config connected. Secrets hidden.')

"""Validate release readiness without printing passwords or key contents."""
from pathlib import Path
import subprocess

root = Path(__file__).resolve().parents[1]
config = root / 'android/key.properties'
if not config.exists():
    raise SystemExit('Release blocked: owner must select/provide a private upload keystore. No key generated.')
values = {}
for line in config.read_text().splitlines():
    if '=' in line and not line.strip().startswith('#'):
        key, value = line.split('=', 1)
        values[key.strip()] = value.strip()
for key in ['storeFile', 'storePassword', 'keyAlias', 'keyPassword']:
    if not values.get(key):
        raise SystemExit(f'Release signing field missing: {key} (values hidden)')
file = Path(values['storeFile'])
if not file.is_absolute():
    file = root / 'android/app' / file
if not file.is_file():
    raise SystemExit('Keystore file not found (path hidden)')
ignored = subprocess.run(['git', 'check-ignore', '--quiet', 'android/key.properties'], cwd=root)
if ignored.returncode:
    raise SystemExit('Signing configuration must be ignored by Git')
print('Release signing fields and keystore present; secrets not displayed.')

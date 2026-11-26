"""Validate the owner's private plist and derive the Google callback build setting.

Run after downloading ios/Runner/GoogleService-Info.plist from the EXISTING
Firebase project. No credentials, identifiers or plist contents are printed.
"""
from pathlib import Path
import plistlib
import re


def main():
    root = Path(__file__).resolve().parent.parent
    source = root / 'ios/Runner/GoogleService-Info.plist'
    config = plistlib.loads(source.read_bytes())
    project = (root / 'ios/Runner.xcodeproj/project.pbxproj').read_text()
    bundle = config.get('BUNDLE_ID', '')
    if not bundle or f'PRODUCT_BUNDLE_IDENTIFIER = {bundle};' not in project:
        raise SystemExit('Firebase Bundle ID does not match Runner. No files changed.')
    if not all(config.get(key) for key in ('API_KEY', 'GOOGLE_APP_ID', 'PROJECT_ID')):
        raise SystemExit('Incomplete Firebase plist. No files changed.')
    callback = config.get('REVERSED_CLIENT_ID', '')
    if not re.fullmatch(r'[A-Za-z0-9.\-]+', callback):
        raise SystemExit('Missing or invalid Google callback. Download the current iOS plist.')
    (root / 'ios/Flutter/Firebase.xcconfig').write_text(
        '// Generated locally; excluded from Git.\n'
        f'AQM_GOOGLE_REVERSED_CLIENT_ID = {callback}\n'
    )
    print('Private iOS Firebase configuration validated; callback setting generated.')


if __name__ == '__main__':
    main()

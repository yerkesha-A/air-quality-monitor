"""Check publishable Git files/history without printing secret values."""
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
PATTERNS = {
    'private-key': re.compile(rb'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----'),
    'google-api-key': re.compile(rb'AIza[0-9A-Za-z_-]{35}'),
    'github-token': re.compile(rb'(?:gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{30,})'),
    'oauth-access-token': re.compile(rb'ya29\.[A-Za-z0-9_.-]{30,}'),
    'aws-access-key': re.compile(rb'AKIA[A-Z0-9]{16}'),
}
PRIVATE = re.compile(r'(^|/)(\.local-backups|node_modules|\.firebase|\.dart_tool)(/|$)|(^|/)(google-services\.json|firebase_options\.dart|key\.properties|local\.properties|service-account[^/]*\.json)$|\.(?:jks|keystore|p12|pem|apk|aab|tar|gz|zip)$|(^|/)\.env(?:\.|$)')


def git(*args):
    return subprocess.check_output(['git', *args], cwd=ROOT)


def check(name, data):
    findings = []
    if PRIVATE.search(name) and not name.endswith('gradle-wrapper.jar'):
        findings.append('private-file-name')
    for label, pattern in PATTERNS.items():
        if pattern.search(data):
            findings.append(label)
    for label in findings:
        print(f'{name}: {label} (value redacted)')
    return len(findings)


def main():
    failures = 0
    paths = git('ls-files', '--cached', '--others', '--exclude-standard', '-z').split(b'\0')
    checked = 0
    for raw in paths:
        if not raw:
            continue
        name = raw.decode()
        file = ROOT / name
        if file.is_file():
            failures += check(name, file.read_bytes())
            checked += 1
    if '--history' in sys.argv:
        seen = set()
        for raw in git('rev-list', '--objects', '--all').splitlines():
            parts = raw.decode().split(' ', 1)
            if len(parts) != 2:
                continue
            oid, name = parts
            if oid in seen or git('cat-file', '-t', oid).strip() != b'blob':
                continue
            seen.add(oid)
            failures += check(name, git('cat-file', 'blob', oid))
        print(f'History blobs checked: {len(seen)}')
    print(f'Publishable files checked: {checked}; findings: {failures}')
    print('Heuristic scan; manually review new configuration and artifacts before publication.')
    return int(failures > 0)


if __name__ == '__main__':
    raise SystemExit(main())

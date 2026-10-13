"""Check the measured LCOV report, not a guessed coverage figure."""
from pathlib import Path
lines = Path('coverage/lcov.info').read_text().splitlines()
found = sum(int(line[3:]) for line in lines if line.startswith('LF:'))
hit = sum(int(line[3:]) for line in lines if line.startswith('LH:'))
ratio = hit / found if found else 0
print(f'Flutter LCOV: {hit}/{found} lines ({ratio:.2%})')
if ratio <= 0.4:
    raise SystemExit('Coverage must be greater than 40%.')

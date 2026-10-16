"""Prepare local RK1 hand-in from publishable sources; never copy signing/config/data files."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import zipfile

from secret_scan import check

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / 'submission' / 'RK1_2026-10-16'


def main():
    raw = subprocess.check_output(
        ['git', 'ls-files', '--cached', '--others', '--exclude-standard', '-z'], cwd=ROOT)
    names = sorted({name.decode() for name in raw.split(b'\0') if name})
    sources = [(name, ROOT / name) for name in names if (ROOT / name).is_file()]
    findings = sum(check(name, file.read_bytes()) for name, file in sources)
    if findings:
        raise SystemExit('Refusing to package sources with secret-scan findings.')
    artifacts = {
        'AirQualityMonitor-release.apk': ROOT / 'build/app/outputs/flutter-apk/app-release.apk',
        'AirQualityMonitor-release.aab': ROOT / 'build/app/outputs/bundle/release/app-release.aab',
    }
    if not all(file.is_file() for file in artifacts.values()):
        raise SystemExit('Build signed APK and AAB first.')
    DEST.mkdir(parents=True, exist_ok=True)
    for name, file in sources:
        target = DEST / 'source' / name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(file, target)
    with zipfile.ZipFile(DEST / 'source.zip', 'w', zipfile.ZIP_DEFLATED) as archive:
        for name, file in sources:
            archive.write(file, name)
    for name, file in artifacts.items():
        shutil.copy2(file, DEST / name)
    (DEST / 'README_FOR_TEACHER.md').write_text(
        '# Air Quality Monitor — РК1, 16.10.2026\n\n'
        'Для запуска на отдельном Android 7+ устройстве: AirQualityMonitor-release.apk. '
        'Firebase уже включён; для новых данных и входа нужен интернет. '
        'Не устанавливать поверх debug-приложения владельца с другой подписью.\n\n'
        'Отчёт: [source/RK1_REPORT.md](source/RK1_REPORT.md). '
        'Если приложен RK1_REPORT.pdf, это готовая версия для чтения/печати. '
        'Инструкция сдачи: [source/docs/rk1/SUBMISSION.md](source/docs/rk1/SUBMISSION.md). '
        'Защита: [source/docs/rk1/DEFENSE_5_MIN.md](source/docs/rk1/DEFENSE_5_MIN.md).\n\n'
        'source.zip содержит исходники без приватной конфигурации и данных. '
        'AAB — дополнительный артефакт, напрямую на телефон не устанавливается. '
        'GitHub-ссылка добавляется после разрешённой публикации и проверки доступа.\n',
        encoding='utf-8')
    hashes = {}
    for name in ['source.zip', *artifacts, 'README_FOR_TEACHER.md']:
        file = DEST / name
        hashes[name] = {'bytes': file.stat().st_size,
                        'sha256': hashlib.sha256(file.read_bytes()).hexdigest()}
    (DEST / 'SHA256.json').write_text(json.dumps(hashes, indent=2) + '\n')
    commit = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
    (DEST / 'SOURCE_MANIFEST.json').write_text(json.dumps({
        'date': '2026-10-16', 'base_commit': commit,
        'working_tree_status': subprocess.check_output(
            ['git', 'status', '--porcelain'], cwd=ROOT, text=True).splitlines(),
        'source_count': len(sources), 'files': [name for name, _ in sources],
        'private_configuration_included': False,
    }, indent=2, ensure_ascii=False) + '\n')
    print(f'Prepared {DEST.relative_to(ROOT)}: {len(sources)} source files; APK/AAB; SHA256.json')


if __name__ == '__main__':
    main()

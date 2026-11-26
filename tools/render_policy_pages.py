"""Build static policy/request pages from the reviewed project documents."""
from pathlib import Path
import html
import re
from urllib.parse import quote


def inline(text):
    text = text.replace('(PRIVACY_POLICY.md)', '(privacy.html)').replace('(ACCOUNT_DELETION.md)', '(account-deletion.html)')
    text = html.escape(text)
    text = re.sub(r'\[([^\]]+)\]\(((?:https?://[^\s)]+|privacy\.html|account-deletion\.html))\)', r'<a href="\2">\1</a>', text)
    return re.sub(r'\*\*([^*]+)\*\*', r'<strong>\1</strong>', text)


def main():
    root = Path(__file__).resolve().parents[1]
    out = root / 'docs/store/site'
    out.mkdir(parents=True, exist_ok=True)
    for source, dest in [('PRIVACY_POLICY.md', 'privacy.html'), ('ACCOUNT_DELETION.md', 'account-deletion.html'), (None, 'support.html')]:
        sections = []
        document = (root / 'docs' / source).read_text() if source else '# Поддержка Air Quality Monitor\n\nКонтакт разработчика: **erkezhanabdraim@gmail.com**.\n\nДля вопроса или сообщения об ошибке укажите версию приложения, модель устройства и шаги воспроизведения. Не отправляйте пароль, коды входа, токены и личные фотографии. Приложение не отправляет письма автоматически.\n\n[Удаление аккаунта](ACCOUNT_DELETION.md) · [Политика конфиденциальности](PRIVACY_POLICY.md)'
        for line in document.splitlines():
            if not line.strip():
                continue
            heading = len(line) - len(line.lstrip('#'))
            sections.append(f'<h{heading}>{inline(line.lstrip("# "))}</h{heading}>' if heading else '<p>' + inline(line) + '</p>')
        content = '\n'.join(sections)
        deletion = dest == 'account-deletion.html'
        subject = quote('Удаление аккаунта Air Quality Monitor' if deletion else 'Air Quality Monitor')
        label = 'Запросить удаление по email' if deletion else 'Написать разработчику'
        page = '''<!doctype html><html lang="ru"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Air Quality Monitor</title>
<style>body{margin:0;background:#f7fafc;color:#20343c;font:17px/1.65 system-ui,sans-serif}main{max-width:800px;margin:auto;padding:32px 24px 64px}h1{font-size:2rem;line-height:1.2}h2{font-size:1.35rem;margin-top:2rem}a{color:#176578}nav{display:flex;gap:24px;flex-wrap:wrap}p{overflow-wrap:anywhere}@media(prefers-color-scheme:dark){body{background:#10191f;color:#edf6fa}a{color:#a5d8e5}}</style>
<main><nav><a href="privacy.html">Конфиденциальность</a><a href="account-deletion.html">Удаление аккаунта</a><a href="support.html">Поддержка</a></nav>''' + content + '<p><a href="mailto:erkezhanabdraim@gmail.com?subject=' + subject + '">' + label + '</a></p></main></html>'
        (out / dest).write_text(page)
    (out / 'README.md').write_text('# Страницы поддержки и политики\n\nprivacy.html, account-deletion.html и support.html генерируются из актуальных документов и контакта разработчика. Без PDF, JavaScript и трекеров; mailto открывает корректный черновик, не отправляет письмо. Страницы пока не развёрнуты: для магазинов нужны доступные HTTPS URL. Публикация на выбранном бесплатном хостинге требует отдельного разрешения владельца. Удаление внутри приложения и альтернативный запрос в поддержку описаны явно.\n')


if __name__ == '__main__':
    main()

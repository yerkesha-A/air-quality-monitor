"""CI helper: preserve the developer's local Gradle zip; use HTTPS on clean runners."""
from pathlib import Path
path = Path('android/gradle/wrapper/gradle-wrapper.properties')
content = path.read_text()
lines = content.splitlines()
lines = ['distributionUrl=https\\://services.gradle.org/distributions/gradle-9.3.1-all.zip'
         if line.startswith('distributionUrl=') else line for line in lines]
path.write_text('\n'.join(lines) + '\n')

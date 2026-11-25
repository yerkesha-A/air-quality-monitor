"""Static 16 KiB ELF/ZIP checks. This does not replace a real 16 KiB device run."""
import argparse
import json
import struct
import zipfile
from pathlib import Path


def check(apk):
    libraries = []
    with zipfile.ZipFile(apk) as archive, open(apk, 'rb') as raw:
        for item in archive.infolist():
            if not item.filename.endswith('.so') or not item.filename.startswith(('lib/arm64-v8a/', 'lib/x86_64/')):
                continue
            data = archive.read(item)
            if data[:5] != b'\x7fELF\x02':
                raise ValueError('Expected ELF64: ' + item.filename)
            endian = '<' if data[5] == 1 else '>'
            offset = struct.unpack_from(endian + 'Q', data, 32)[0]
            stride, count = struct.unpack_from(endian + 'HH', data, 54)
            aligns = [struct.unpack_from(endian + 'Q', data, offset + n * stride + 48)[0]
                      for n in range(count)
                      if struct.unpack_from(endian + 'I', data, offset + n * stride)[0] == 1]
            raw.seek(item.header_offset)
            header = raw.read(30)
            filename_size, extra_size = struct.unpack_from('<HH', header, 26)
            data_offset = item.header_offset + 30 + filename_size + extra_size
            zip_ok = item.compress_type != zipfile.ZIP_STORED or data_offset % 16384 == 0
            libraries.append({'library': item.filename, 'loadAlignments': aligns,
                              'elfAligned': bool(aligns) and min(aligns) >= 16384,
                              'zipAligned': zip_ok})
    return {'libraries': libraries, 'staticCompatible': bool(libraries) and
            all(x['elfAligned'] and x['zipAligned'] for x in libraries), 'runtime16kDeviceTested': False}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('apk', type=Path)
    result = check(parser.parse_args().apk)
    print(json.dumps(result, indent=2))
    raise SystemExit(0 if result['staticCompatible'] else 1)

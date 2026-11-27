"""Optional official Cairo font at build time; no font binaries in the source archive."""
from pathlib import Path
from urllib.request import urlopen, Request

root=Path(__file__).resolve().parent.parent
pub=root/'pubspec.yaml'
text=pub.read_text()
if 'family: Cairo' in text:
    if (root/'assets/fonts/Cairo.ttf').is_file(): raise SystemExit(0)
    text=text.split('  # Generated Cairo font')[0]
    pub.write_text(text)
base='https://raw.githubusercontent.com/google/fonts/main/ofl/cairo/'
try:
    def fetch(name):
        with urlopen(Request(base+name,headers={'User-Agent':'AlmasShop-build'}),timeout=15) as response:
            data=response.read(8*1024*1024+1)
            if len(data)>8*1024*1024: raise ValueError('download too large')
            return data
    font=fetch('Cairo%5Bslnt%2Cwght%5D.ttf')
    license=fetch('OFL.txt')
    if font[:4] not in (b'\x00\x01\x00\x00',b'OTTO') or b'SIL OPEN FONT LICENSE' not in license: raise ValueError('invalid font or license')
    dest=root/'assets/fonts';dest.mkdir(exist_ok=True)
    (dest/'Cairo.ttf').write_bytes(font);(dest/'OFL.txt').write_bytes(license)
    pub.write_text(text.rstrip()+'\n  # Generated Cairo font\n    - assets/fonts/OFL.txt\n  fonts:\n    - family: Cairo\n      fonts:\n        - asset: assets/fonts/Cairo.ttf\n')
except Exception as exc:
    print('Cairo unavailable; platform Arabic font fallback will be used:',exc)

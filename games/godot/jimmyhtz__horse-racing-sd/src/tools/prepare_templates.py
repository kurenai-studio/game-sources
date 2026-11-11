"""Fetch and verify the exact desktop templates used by this source release."""
from pathlib import Path
import argparse, hashlib, shutil, sys, urllib.request, zipfile

VERSION = '4.7.2-stable'
SHA256 = 'f298490b8d44d934be425a5a65a51bf15f422428b229a06a6e11d9ffea248011'
FILES = ('windows_release_x86_64.exe', 'linux_release.x86_64', 'linux_release.arm64', 'macos.zip')
ROOT = Path(__file__).resolve().parents[1]

def prepare(archive=None):
    if sys.version_info<(3,11):raise SystemExit('Python 3.11 or newer is required.')
    base = ROOT/'.build'
    base.mkdir(exist_ok=True)
    archive = Path(archive).resolve() if archive else base/f'Godot_v{VERSION}_export_templates.tpz'
    if not archive.exists():
        url=f'https://github.com/godotengine/godot-builds/releases/download/{VERSION}/{archive.name}'
        request=urllib.request.Request(url,headers={'User-Agent':'HorseRacingBuild/0.22'})
        partial=archive.with_suffix('.part')
        with urllib.request.urlopen(request,timeout=60) as src, partial.open('wb') as dst:
            shutil.copyfileobj(src,dst,1024*1024)
        partial.replace(archive)
    with archive.open('rb') as src:actual=hashlib.file_digest(src,'sha256').hexdigest()
    if actual != SHA256:raise SystemExit('Template archive failed SHA-256 verification.')
    destination=base/'templates';destination.mkdir(exist_ok=True)
    with zipfile.ZipFile(archive) as packed:
        for name in FILES:
            with packed.open('templates/'+name) as src,(destination/name).open('wb') as dst:
                shutil.copyfileobj(src,dst,1024*1024)
    print('Verified and extracted four desktop export templates.')

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--archive')
    prepare(parser.parse_args().archive)

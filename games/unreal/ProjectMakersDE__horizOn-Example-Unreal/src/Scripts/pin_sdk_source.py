#!/usr/bin/env python3
"""Record and verify a complete official plugin snapshot, excluding generated caches."""
import argparse
from datetime import date
import hashlib
import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]
def main():
    parser=argparse.ArgumentParser();parser.add_argument('--sdk-source',type=Path,required=True);parser.add_argument('--tag');parser.add_argument('--sdk-ref',default='HEAD');args=parser.parse_args()
    def git(*values): return subprocess.check_output(['git','-C',str(args.sdk_source),*values])
    commit=git('rev-parse',args.sdk_ref).decode().strip()
    names=git('ls-tree','-r','--name-only',commit,'Plugins/HorizonSDK').decode().splitlines()
    files={}
    for name in names:
        relative=str(Path(name).relative_to('Plugins/HorizonSDK'))
        official=git('show',commit+':'+name)
        copied=(ROOT/name).read_bytes()
        if official!=copied: raise SystemExit('Embedded SDK differs from official source: '+relative)
        files[relative]=hashlib.sha256(official).hexdigest()
    if not files: raise SystemExit('Official plugin is empty')
    descriptor=json.loads((ROOT/'Plugins/HorizonSDK/HorizonSDK.uplugin').read_text())
    lock=dict(repository='https://github.com/ProjectMakersDE/horizOn-SDK-Unreal',tag=args.tag,commit=commit,synced_at=date.today().isoformat(),source='Complete unmodified official plugin snapshot.',descriptorVersion=descriptor['VersionName'],files=files)
    (ROOT/'SDK-SOURCE.json').write_text(json.dumps(lock,indent=2)+'\n')
    print(f'Pinned {len(files)} official files at {commit}')
if __name__=='__main__': main()

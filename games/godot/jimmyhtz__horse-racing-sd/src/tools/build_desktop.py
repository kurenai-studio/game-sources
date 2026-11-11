"""Build desktop packages in a disposable source copy, preserving local game data."""
from pathlib import Path
import argparse, hashlib, os, shutil, subprocess, sys, tarfile, tempfile, zipfile

ROOT=Path(__file__).resolve().parents[1]
VERSION='0.22.0'
PRESETS={'windows':('Windows','windows/Horse Racing.exe','Windows-x86_64.zip'),
         'linux':('Linux','linux/horse-racing','Linux-x86_64.tar.gz'),
         'linux-arm64':('Linux ARM64','linux-arm64/horse-racing','Linux-arm64.tar.gz'),
         'macos':('macOS','Horse-Racing-'+VERSION+'-macOS-universal.zip','macOS-universal.zip')}
IGNORE={'.git','.godot','.build','dist','runtime','test-results','__pycache__'}

def command(args,cwd,env):
    result=subprocess.run([str(a) for a in args],cwd=cwd,env=env,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
    text=result.stdout
    log=ROOT/'.build'/('last-'+Path(str(args[0])).stem+'.log')
    log.write_text(text,encoding='utf-8')
    if result.returncode or 'SCRIPT ERROR:' in text or '\nERROR:' in text:
        print('\n'.join(line for line in text.splitlines() if 'ERROR' in line or 'WARNING' in line)[-4000:]);raise SystemExit('Build or validation command failed: '+str(args))
    print('Completed:', ' '.join(str(a) for a in args[-3:]),flush=True)

def copy_documents(folder,platform):
    (folder/'docs').mkdir(parents=True,exist_ok=True)
    for name in ('QUICK_START.html','USER_MANUAL.html'):shutil.copy2(ROOT/'docs'/name,folder/'docs'/name)
    shutil.copytree(ROOT/'licenses',folder/'licenses',dirs_exist_ok=True)
    for name in ('LICENSE','THIRD_PARTY_NOTICES.md'):shutil.copy2(ROOT/name,folder/name)
    launch={'windows':'Run Horse Racing.exe. Keep the PCK file beside it.',
            'linux':'Run ./horse-racing, or ./install.sh for a per-user installation.',
            'linux-arm64':'Run ./horse-racing on ARM64 Linux, or ./install.sh.',
            'macos':'Move Horse Racing.app to Applications. This build is ad-hoc signed and not notarized.'}[platform]
    (folder/'README.txt').write_text(f'Horse Racing {VERSION}\n\n{launch}\n\nOpen docs/QUICK_START.html, or press F1 in the game.\nFull help: docs/USER_MANUAL.html\nSource and updates: https://github.com/jimmyhtz/horse-racing-sd\nGPLv3 and third-party notices are included.\nWindows is locally tested. Other platforms need interactive and voice testing.\nSaved games are stored separately; uninstall preserves them.\n',encoding='utf-8')

def build(godot,platform,makensis=None):
    if sys.version_info<(3,11):raise SystemExit('Python 3.11 or newer is required.')
    if sys.platform=='darwin':
        hosted=os.environ.get('GITHUB_ACTIONS')=='true' and os.environ.get('RUNNER_ENVIRONMENT')=='github-hosted'
        real_data=Path.home()/'Library/Application Support/Godot/app_userdata/Superpuppy Sigma Derby'
        if not hosted and real_data.exists() and any(real_data.iterdir()):
            raise SystemExit('Use a separate Mac OS account for building: this account already contains game data.')
    godot=Path(godot).resolve()
    base=ROOT/'.build';base.mkdir(exist_ok=True)
    output=ROOT/'dist';output.mkdir(exist_ok=True)
    targets=list(PRESETS) if platform=='all' else [platform]
    with tempfile.TemporaryDirectory(prefix='export-',dir=base) as work:
        work=Path(work);project=work/'project'
        shutil.copytree(ROOT,project,ignore=lambda path,names:[n for n in names if n in IGNORE])
        shutil.copytree(base/'templates',project/'.build/templates')
        env=os.environ.copy()
        env['APPDATA']=str(work/'appdata');env['XDG_DATA_HOME']=str(work/'data');env['XDG_CONFIG_HOME']=str(work/'config')
        env['LOCALAPPDATA']=str(work/'localdata');env['XDG_CACHE_HOME']=str(work/'cache')
        if sys.platform=='darwin':
            bundle=next((parent for parent in godot.parents if parent.suffix=='.app'),None)
            if bundle is None:raise SystemExit('On macOS provide the executable inside the official Godot.app bundle.')
            portable=work/'editor'/bundle.name
            shutil.copytree(bundle,portable)
            godot=portable/godot.relative_to(bundle)
            (portable.parent/'_sc_').touch()
        command([godot,'--headless','--log-file',work/'editor.log','--path',project,'--editor','--import'],project,env)
        for target in targets:
            preset,relative,archive_name=PRESETS[target]
            artifact=work/'artifacts'/relative;artifact.parent.mkdir(parents=True,exist_ok=True)
            command([godot,'--headless','--log-file',work/'export.log','--path',project,'--export-release',preset,artifact],project,env)
            if target=='macos':
                docs=work/'mac-docs';copy_documents(docs,target)
                with zipfile.ZipFile(artifact,'a',compression=zipfile.ZIP_DEFLATED,compresslevel=6) as packed:
                    for file in docs.rglob('*'):
                        if file.is_file():packed.write(file,file.relative_to(docs))
                shutil.copy2(artifact,output/relative)
            else:
                folder=artifact.parent;copy_documents(folder,target)
                archive=output/f'Horse-Racing-{VERSION}-{archive_name}'
                if target=='windows':
                    with zipfile.ZipFile(archive,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=6) as packed:
                        for file in folder.rglob('*'):
                            if file.is_file():packed.write(file,Path('Horse Racing')/file.relative_to(folder))
                    if makensis:
                        command([Path(makensis).resolve(),f'/DPAYLOAD={folder}',f'/DOUTPUT={output / ("Horse-Racing-"+VERSION+"-Windows-Setup.exe")}',ROOT/'packaging/windows.nsi'],ROOT,env)
                else:
                    for name in ('install.sh','uninstall.sh'):shutil.copy2(ROOT/'packaging'/name,folder/name)
                    def permissions(info):
                        info.uid=info.gid=0;info.uname=info.gname=''
                        info.mode=0o755 if info.isdir() or Path(info.name).name in ('horse-racing','install.sh','uninstall.sh') else 0o644
                        return info
                    with tarfile.open(archive,'w:gz',compresslevel=6) as packed:packed.add(folder,arcname='horse-racing',filter=permissions)
                shutil.copytree(folder,(output/relative).parent,dirs_exist_ok=True)
            print('Built',target,flush=True)
    sums=[]
    for file in sorted(output.iterdir()):
        if file.is_file() and file.name!='SHA256SUMS.txt':
            with file.open('rb') as src:sums.append(hashlib.file_digest(src,'sha256').hexdigest()+'  '+file.name)
    (output/'SHA256SUMS.txt').write_text('\n'.join(sums)+'\n')

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--godot',required=True)
    parser.add_argument('--platform',choices=[*PRESETS,'all'],required=True);parser.add_argument('--makensis')
    args=parser.parse_args();build(args.godot,args.platform,args.makensis)

"""Native CI check using the pinned official editor and desktop templates."""
from pathlib import Path
import hashlib,json,os,platform,shutil,subprocess,sys,urllib.request,zipfile
ROOT=Path(__file__).resolve().parents[1]
BASE=ROOT/'.build';BASE.mkdir(exist_ok=True)

def run(args,env):
    result=subprocess.run([str(a) for a in args],cwd=ROOT,env=env,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
    print(result.stdout[-4000:])
    if result.returncode or 'SCRIPT ERROR:' in result.stdout or '\nERROR:' in result.stdout:raise SystemExit(1)

def main():
    if sys.version_info<(3,11):raise SystemExit('Python 3.11 or newer is required.')
    host=platform.system()
    if host=='Darwin':
        if os.environ.get('GITHUB_ACTIONS')!='true' or os.environ.get('RUNNER_ENVIRONMENT')!='github-hosted' or not os.environ.get('RUNNER_TEMP'):
            raise SystemExit('Mac packaged startup is restricted to a disposable GitHub runner. Use a separate OS account for manual testing.')
        real_data=Path.home()/'Library/Application Support/Godot/app_userdata/Superpuppy Sigma Derby'
        if real_data.exists():raise SystemExit('Refusing Mac validation: an existing game data directory was found.')
    record=json.loads((ROOT/'tools/editor_downloads.json').read_text())[host]
    archive=BASE/record['name']
    request=urllib.request.Request(record['url'],headers={'User-Agent':'HorseRacingBuild/0.22'})
    with urllib.request.urlopen(request,timeout=60) as src,archive.open('wb') as dst:shutil.copyfileobj(src,dst,1024*1024)
    with archive.open('rb') as src:actual=hashlib.file_digest(src,'sha256').hexdigest()
    if actual!=record['sha256']:raise SystemExit('Official editor digest mismatch')
    with zipfile.ZipFile(archive) as z:z.extractall(BASE/'editor')
    godot=BASE/'editor'/record['executable'];godot.chmod(0o755)
    if host=='Darwin':
        (BASE/'editor/_sc_').touch()
    env=os.environ.copy()
    for variable,folder in [('APPDATA','appdata'),('LOCALAPPDATA','localdata'),('XDG_DATA_HOME','data'),('XDG_CONFIG_HOME','config'),('XDG_CACHE_HOME','cache')]:env[variable]=str(BASE/'test-runtime'/folder)
    run([godot,'--headless','--path',ROOT,'--editor','--import'],env)
    for test in ['help_release_tests','settings_layout_tests','support_20_tests']:
        run([godot,'--headless','--path',ROOT,'--script',f'tests/{test}.gd'],env)
    run([sys.executable,'tools/build_help.py','--check'],env)
    run([sys.executable,'tools/prepare_templates.py'],env)
    target={'Windows':'windows','Darwin':'macos','Linux':'linux'}[host]
    run([sys.executable,'tools/build_desktop.py','--godot',godot,'--platform',target],env)
    if host=='Windows':executable=ROOT/'dist/windows/Horse Racing.exe'
    elif host=='Linux':
        executable=ROOT/'dist/linux/horse-racing';executable.chmod(0o755)
    else:
        package=ROOT/'dist/Horse-Racing-0.22.0-macOS-universal.zip'
        with zipfile.ZipFile(package) as z:
            z.extractall(BASE/'native-app')
            for item in z.infolist():
                path=BASE/'native-app'/item.filename
                if not item.is_dir() and (item.external_attr>>16)&0o111:path.chmod(0o755)
        executable=BASE/'native-app/Horse Racing.app/Contents/MacOS/Horse Racing'
    run([executable,'--headless','--quit-after','10'],env)
    print('Native packaged startup and selected checks passed on '+host)

if __name__=='__main__':main()

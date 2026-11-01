#!/usr/bin/env python3
"""Run real Unreal automation against an isolated loopback fixture, never production."""
import argparse
import json
from pathlib import Path
import shutil
import plistlib
import re
import sys
import subprocess
import time
import uuid

ROOT=Path(__file__).resolve().parents[1]
def main():
    parser=argparse.ArgumentParser()
    engine=parser.add_mutually_exclusive_group(required=True)
    engine.add_argument('--editor',type=Path);engine.add_argument('--game',type=Path)
    parser.add_argument('--output',type=Path,required=True);parser.add_argument('--port',type=int,default=18814)
    parser.add_argument('--statistics',action='store_true')
    parser.add_argument('--headless',action='store_true');parser.add_argument('--hello',action='store_true')
    parser.add_argument('--width',type=int,default=1280);parser.add_argument('--height',type=int,default=720)
    args=parser.parse_args();args.output=args.output.resolve();args.output.mkdir(parents=True,exist_ok=True)
    ready=args.output/'fixture.ready';result=args.output/'fixture.json';report=args.output/'report'
    if result.exists() or report.exists(): raise SystemExit('Use a fresh output directory to prevent stale evidence')
    run_id=uuid.uuid4().hex
    sandbox=None
    if args.game and sys.platform=='darwin':
        app=next((p for p in args.game.resolve().parents if p.suffix=='.app'),None)
        if app:
            identifier=plistlib.loads((app/'Contents/Info.plist').read_bytes())['CFBundleIdentifier']
            if not re.fullmatch(r'[A-Za-z0-9_.-]+',identifier): raise RuntimeError('Invalid bundle identity')
            sandbox=Path.home()/'Library/Containers'/identifier/'Data/tmp'/('horizon-acceptance-'+run_id)
            sandbox.mkdir(parents=True,exist_ok=False)
    native_output=sandbox or args.output
    report=native_output/'report'
    user_dir=native_output/'user' if sandbox else ROOT/'Saved'/('acceptance-'+run_id)
    test='Seagull.Acceptance.'+(('HelloStatistics' if args.hello else 'StatisticsRound') if args.statistics else ('HelloHorizon' if args.hello else 'GameAndPlayerValues'))
    command=[str(args.editor or args.game)]
    if args.editor: command += [str(ROOT/'SeagullStorm.uproject'),'-game']
    if args.hello: command += ['/Game/Maps/MainMap?game=/Script/Engine.GameModeBase']
    command += ['-windowed',f'-ResX={args.width}',f'-ResY={args.height}',f'-SeagullFixture=http://127.0.0.1:{args.port}',f'-UserDir={user_dir}',f'-ExecCmds=Automation RunTests {test}','-TestExit=Automation Test Queue Empty',f'-ReportExportPath={report}','-unattended','-NoSplash','-NoEpicPortal','-nosound','-log']
    if args.headless: command += ['-nullrhi']
    captures=native_output/'screenshots';captures.mkdir(exist_ok=True)
    command += [f'-SeagullCaptureDir={captures}']
    process=None
    with (args.output/'fixture.log').open('w') as fixture_log,(args.output/'launcher.log').open('w') as engine_log:
        fixture_args=['python3',str(ROOT/('Scripts/statistics_fixture.py' if args.statistics else 'Scripts/player_values_fixture.py')),'--port',str(args.port),'--ready',str(ready),'--result',str(result)]
        if args.statistics and args.hello:fixture_args.append('--hello')
        fixture=subprocess.Popen(fixture_args,cwd=ROOT,stdout=fixture_log,stderr=subprocess.STDOUT)
        try:
            deadline=time.monotonic()+10
            while not ready.exists():
                if fixture.poll() is not None: raise RuntimeError('Fixture failed before readiness; existing ports are never killed')
                if time.monotonic()>deadline: raise TimeoutError('Fixture readiness')
                time.sleep(.1)
            process=subprocess.Popen(command,cwd=ROOT,stdout=engine_log,stderr=subprocess.STDOUT)
            code=process.wait(timeout=300)
            if not (report/'index.json').is_file(): raise RuntimeError(f'Native report absent (launcher exit {code}); launcher exit alone is insufficient')
            summary=json.loads((report/'index.json').read_text(encoding='utf-8-sig'))
            if code or summary.get('failed',0) or not summary.get('tests') or any(t.get('state')!='Success' or t.get('errors') for t in summary['tests']): raise RuntimeError('Native automation failed')
        finally:
            for child in (process,fixture):
                if child and child.poll() is None:
                    child.terminate()
                    try: child.wait(timeout=15)
                    except subprocess.TimeoutExpired: child.kill();child.wait()
            ready.unlink(missing_ok=True)
            logs=user_dir/'Saved/Logs'
            if logs.is_dir(): shutil.copytree(logs,args.output/'engine-logs',dirs_exist_ok=True)
            if sandbox:
                for name in ('report','screenshots','user'):
                    source=sandbox/name
                    if source.is_dir(): shutil.copytree(source,args.output/name,dirs_exist_ok=True)
                shutil.rmtree(sandbox)
                report=args.output/'report';captures=args.output/'screenshots'
    proof=json.loads(result.read_text())
    if args.statistics:
        assert not proof['failure'] and proof['signup']==1 and proof['scores']==(1 if args.hello else 2) and proof['revision']==1
        assert proof['values']==dict(kills=3 if args.hello else 2,rounds=1,best_score=1200 if args.hello else 10)
        assert len(proof['batches'])==(1 if args.hello else 5) and proof['gets']==(2 if args.hello else 6)
        if not args.hello:
            assert proof['batches'][0]==proof['batches'][1]==proof['batches'][2]
            assert proof['batches'][3]==proof['batches'][4] and proof['batches'][0]['operationId']!=proof['batches'][3]['operationId']
    elif args.hello:
        assert proof['scores']==1 and proof['purchases']==0 and proof['adjustments']==0
        assert [c['route'] for c in proof['calls']]==['/actuator/health','/api/v1/app/user-management/signup','/api/v1/app/leaderboard/submit']
    else:
        assert proof['scores']==0 and proof['purchases']==3 and proof['adjustments']==1 and proof['gold']==93 and proof['energy']==9
    if not args.headless:
        names=(['20-statistics-hello.png'] if args.hello else ['17-statistics-original.png','18-statistics-snapshot.png','19-statistics-replay.png','21-statistics-expired.png']) if args.statistics else ['15-hello.png'] if args.hello else [f'{n:02}-' for n in range(1,15)]+['16-']
        for name in names:
            matches=list(captures.glob(name if args.hello or args.statistics else name+'*.png'))
            if len(matches)!=1: raise RuntimeError('Native screenshot absent or ambiguous: '+name)
    print(json.dumps(dict(passed=True,test=test,report=str(report),fixtureRequests=len(proof['calls']),userDir=str(user_dir),headless=args.headless)))
if __name__=='__main__': main()

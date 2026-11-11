"""Exercise actual scene refusal with one lightweight lock owner, no race windows."""
from pathlib import Path
import os
import subprocess
import tempfile

project = Path(__file__).resolve().parents[1]
engine = project / '../../work/tools/Godot_v4.7.2-stable_win64_console.exe'
command = [str(engine.resolve()), '--headless', '--path', str(project)]
with tempfile.TemporaryDirectory(prefix='instance-', dir=project / 'test-results') as runtime:
    env = dict(os.environ, APPDATA=runtime)
    owner = subprocess.Popen(command + ['--script', 'tests/instance_owner.gd'],
                             env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                             text=True, creationflags=subprocess.CREATE_NO_WINDOW)
    try:
        while True:
            line = owner.stdout.readline()
            if 'INSTANCE_LOCK_READY' in line:
                break
            if not line:
                raise AssertionError('Lock owner did not start')
        preflight = subprocess.run(['powershell.exe', '-NoProfile', '-ExecutionPolicy', 'Bypass',
                                    '-File', str(project / 'tests/legacy_instance_tests.ps1'),
                                    '-RunningEngine', str(engine.resolve())], env=env,
                                   capture_output=True, text=True, timeout=10,
                                   creationflags=subprocess.CREATE_NO_WINDOW)
        assert preflight.returncode == 0, preflight.stdout + preflight.stderr
        for scene in ['res://ui/main.tscn', 'res://ui/movement_lab.tscn']:
            result = subprocess.run(command + [scene], env=env, capture_output=True,
                                    text=True, timeout=10, creationflags=subprocess.CREATE_NO_WINDOW)
            assert result.returncode == 2, result.stdout + result.stderr
            assert 'already open' in result.stderr, result.stderr
        assert not list(Path(runtime).rglob('session.json*')), 'Blocked launch touched a saved game'
    finally:
        owner.kill()  # Only the helper created above, to verify OS crash cleanup.
        owner.communicate(timeout=10)
    result = subprocess.run(command + ['--script', 'tests/launch_budget_tests.gd'],
                            env=env, capture_output=True, text=True, timeout=10,
                            creationflags=subprocess.CREATE_NO_WINDOW)
    assert result.returncode == 0 and '0 failures' in result.stdout, result.stdout + result.stderr
    # Production port is free again after forced owner termination.
    import socket
    with socket.socket() as listener:
        listener.bind(('127.0.0.1', 57348))
print('INSTANCE INTEGRATION: main and preview blocked, saves untouched, crash lock released')

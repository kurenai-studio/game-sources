"""Export a separate, click-started Web integration harness without altering the game project."""
from pathlib import Path
import os
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]
WORK = ROOT/".qa/web-project"
OUT = ROOT/"exports/web-qa"
GODOT = os.environ.get("GODOT",str(Path.home()/"Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe"))
WORK.mkdir(parents=True,exist_ok=True)
OUT.mkdir(parents=True,exist_ok=True)
for folder in ["scripts","assets"]:
    shutil.copytree(ROOT/folder,WORK/folder,dirs_exist_ok=True)
(WORK/"tests").mkdir(exist_ok=True)
for name in ["web_qa.gd","web_qa.tscn"]:
    shutil.copy2(ROOT/"tests"/name,WORK/"tests"/name)
for name in ["main.tscn","LICENSE","CREDITS.md"]:
    shutil.copy2(ROOT/name,WORK/name)
project = (ROOT/"project.godot").read_text(encoding="utf-8")
project = project.replace('run/main_scene="res://main.tscn"','run/main_scene="res://tests/web_qa.tscn"')
project = project.replace('config/name="Kittyhm Skate"','config/name="Kittyhm Skate Web QA"')
(WORK/"project.godot").write_text(project,encoding="utf-8")
presets = (ROOT/"export_presets.cfg").read_text(encoding="utf-8").replace('exclude_filter="tests/*,','exclude_filter="')
presets = presets.replace('custom_features=""','custom_features="qa"')
(WORK/"export_presets.cfg").write_text(presets,encoding="utf-8")
for arguments in [["--headless","--quiet","--path",str(WORK),"--editor","--import","--quit"],["--headless","--quiet","--path",str(WORK),"--export-release","Web",str(OUT/"index.html")]]:
    result = subprocess.run([GODOT,*arguments],capture_output=True,text=True)
    print(result.stdout,end="")
    print(result.stderr,end="")
    if result.returncode or "SCRIPT ERROR" in result.stderr or "ERROR:" in result.stderr:
        raise SystemExit(result.returncode or 1)
print(f"QA-only Web build: {OUT}")

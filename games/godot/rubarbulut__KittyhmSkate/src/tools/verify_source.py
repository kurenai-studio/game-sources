"""Verify and test a clean source ZIP, independent of the development .godot cache."""
from pathlib import Path
import os
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[1]
ARCHIVE = ROOT/"exports/packages/KittyhmSkate-Source.zip"
DEST = ROOT/".qa/source-check"
GODOT = os.environ.get("GODOT",str(Path.home()/"Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe"))
DEST.mkdir(parents=True,exist_ok=True)
with zipfile.ZipFile(ARCHIVE) as bundle:
    names = set(bundle.namelist())
    required = {"KittyhmSkate/project.godot","KittyhmSkate/main.tscn","KittyhmSkate/LICENSE","KittyhmSkate/assets/fonts/OFL.txt","KittyhmSkate/RELEASE_NOTES.md"}
    assert required <= names,"Source archive is missing required files"
    for name in names:
        target = (DEST/name).resolve()
        assert target.is_relative_to(DEST.resolve()),"Unsafe archive path"
        assert not any(part in {".git",".godot",".qa","exports"} for part in Path(name).parts),"Development files in source archive"
        assert not name.endswith("JAM_READINESS.md"),"Private work journal in source archive"
    bundle.extractall(DEST)

project = DEST/"KittyhmSkate"
commands = [["--editor","--import","--quit"]]
commands += [["--script",f"res://tests/{suite}.gd"] for suite in ["smoke","tour","settings_calibration"]]
output = []
for command in commands:
    result = subprocess.run([GODOT,"--headless","--path",str(project),*command],capture_output=True,text=True,timeout=120)
    combined = result.stdout+result.stderr
    output.append(combined)
    if result.returncode or any(marker in combined for marker in ["SCRIPT ERROR:","ERROR:","FAILED"]):
        print(combined)
        raise SystemExit(result.returncode or 1)
(ROOT/".qa/source-check.log").write_text("\n".join(output),encoding="utf-8")
print("PASS: clean source ZIP imports and all three suites pass without development caches")

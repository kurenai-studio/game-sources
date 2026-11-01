#!/usr/bin/env python3
"""Run the pinned official SDK contract fixtures against this example's actual SDK files.

No network/backend writes. Requires a local official horizOn-SDK-Unreal Git clone.
This does not replace UnrealBuildTool or Play In Editor validation.
"""
from pathlib import Path
import argparse
import io
import json
import subprocess
import tarfile
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument("--sdk-source", type=Path, required=True)
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
commit = json.loads((root / "SDK-SOURCE.json").read_text())["commit"]
archive = subprocess.check_output(["git", "archive", commit, "Tests"], cwd=args.sdk_source)
with tempfile.TemporaryDirectory(prefix="seagull-sdk-contracts-") as temporary:
    folder = Path(temporary)
    with tarfile.open(fileobj=io.BytesIO(archive)) as source:
        source.extractall(folder, filter="data")
    (folder / "Plugins").mkdir()
    (folder / "Plugins" / "HorizonSDK").symlink_to(root / "Plugins" / "HorizonSDK", target_is_directory=True)
    subprocess.run(["bash", "Tests/run_transport_test.sh"], cwd=folder, check=True)

"""
Cyber Maze Runner 2.0 - Standalone Windows Executable Build Pipeline.
Automates pre-build test validation and single-file PyInstaller binary compilation.
Produces: dist/CyberMazeRunner.exe
"""

import os
import sys
import subprocess
import shutil

def run_step(description: str, command: list) -> bool:
    print(f"\n[BUILD PIPELINE] ==> {description}...")
    result = subprocess.run(command, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"[ERROR] Step failed with return code {result.returncode}")
        print(f"STDOUT:\n{result.stdout}")
        print(f"STDERR:\n{result.stderr}")
        return False
    print(f"[OK] {description} succeeded.")
    return True

def run_tests() -> bool:
    print("\n" + "=" * 60)
    print("STEP 1: PRE-BUILD TEST SUITE VALIDATION")
    print("=" * 60)

    test_files = [
        "tests/test_pure_game.py",
        "tests/test_modes.py",
        "tests/test_display_scaler.py",
        "tests/test_input_manager.py",
        "tests/test_audio_volume.py",
        "tests/test_full_system.py"
    ]

    for test_file in test_files:
        cmd = [sys.executable, test_file]
        res = subprocess.run(cmd, capture_output=True, text=True)
        if res.returncode != 0:
            print(f"[BUILD HALTED] Unit test failed in {test_file}:")
            print(res.stderr)
            return False
        print(f"[PASS] {test_file}")

    print("[SUCCESS] All pre-build validation tests passed 100% green.")
    return True

def build_executable():
    print("\n" + "=" * 60)
    print("STEP 2: PYINSTALLER STANDALONE BINARY COMPILATION")
    print("=" * 60)

    # Check if pyinstaller is installed
    try:
        import PyInstaller
    except ImportError:
        print("[INFO] PyInstaller not detected in current environment. Installing PyInstaller...")
        install_res = subprocess.run([sys.executable, "-m", "pip", "install", "pyinstaller"], capture_output=True, text=True)
        if install_res.returncode != 0:
            print("[ERROR] Failed to install PyInstaller automatically.")
            print(install_res.stderr)
            return False

    # Base build command for single-file, no-console Windows binary
    cmd = [
        sys.executable,
        "-m", "PyInstaller",
        "--name=CyberMazeRunner",
        "--onefile",
        "--windowed",
        "--clean",
        "--add-data=maze_master.db;.",
        "--hidden-import=pygame",
        "--hidden-import=sqlite3",
        "main.py"
    ]

    print("Running command:", " ".join(cmd))
    proc = subprocess.run(cmd)
    if proc.returncode != 0:
        print("[ERROR] PyInstaller compilation failed.")
        return False

    exe_path = os.path.abspath(os.path.join("dist", "CyberMazeRunner.exe"))
    if os.path.exists(exe_path):
        size_mb = os.path.getsize(exe_path) / (1024 * 1024)
        print("\n" + "=" * 60)
        print("BUILD COMPLETE! STANDALONE WINDOWS BINARY READY")
        print(f"Artifact: {exe_path}")
        print(f"Size: {size_mb:.2f} MB")
        print("=" * 60)
        return True
    else:
        print("[ERROR] Expected binary not found at dist/CyberMazeRunner.exe")
        return False

def main():
    print("Starting Cyber Maze Runner automated build pipeline...")
    if not run_tests():
        sys.exit(1)

    if not build_executable():
        sys.exit(1)

    print("\nBuild pipeline finished successfully.")

if __name__ == "__main__":
    main()

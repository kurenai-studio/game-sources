# -*- mode: python ; coding: utf-8 -*-
# Once oyun paketlenmeli (python packaging/build.py), sonra proje kokunden:
#   python -m PyInstaller packaging/ShinrinCS_Kurulum.spec

import os

ROOT = os.path.abspath(os.path.join(SPECPATH, '..'))

a = Analysis(
    [os.path.join(SPECPATH, 'custom_installer.py')],
    pathex=[],
    binaries=[],
    datas=[(os.path.join(ROOT, 'dist', 'ShinrinCS.exe'), '.')],
    hiddenimports=[],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    noarchive=False,
    optimize=0,
)
pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.datas,
    [],
    name='ShinrinCS_Kurulum',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)

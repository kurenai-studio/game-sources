# -*- mode: python ; coding: utf-8 -*-
# Kullanim (proje kokunden): python packaging/build.py

import os

ROOT = os.path.abspath(os.path.join(SPECPATH, '..'))

# Yalnizca var olan veri dosya/klasorlerini pakete ekle
datas = [(os.path.join(ROOT, src), dst)
         for src, dst in [('settings.json', '.'), ('saves', 'saves'),
                          ('assets', 'assets'), ('data', 'data')]
         if os.path.exists(os.path.join(ROOT, src))]

a = Analysis(
    [os.path.join(ROOT, 'main.py')],
    pathex=[ROOT],
    binaries=[],
    datas=datas,
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
    name='ShinrinCS',
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
    icon='NONE',
)

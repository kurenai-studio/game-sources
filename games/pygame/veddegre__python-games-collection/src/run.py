#!/usr/bin/env python3
"""
run.py — entry point for the Games Collection.
When running as scripts: launches menu.py as a subprocess.
When frozen by PyInstaller: menu.py is the direct entry point (see spec file),
so run.py is only used for the script/development workflow.
"""
import os
import sys
import subprocess

os.environ['PYGAME_HIDE_SUPPORT_PROMPT'] = '1'
sys.dont_write_bytecode = True
os.environ['PYTHONDONTWRITEBYTECODE'] = '1'

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
menu_path = os.path.join(BASE_DIR, 'menu.py')

if not os.path.exists(menu_path):
    print("Error: menu.py not found.")
    sys.exit(1)

subprocess.run([sys.executable, '-B', menu_path])

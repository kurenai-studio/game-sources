#!/bin/sh
# Godot's Android export plugin polls adb for connected devices while running.
# The container is ephemeral, so no adb server is up yet and every poll prints
# "cannot connect to daemon at tcp:5037". Start it once, quietly, then exec.
adb start-server >/dev/null 2>&1 || true
exec "$@"

# Fly Fight web duel

This is the browser presentation of the same continuous duel: HP combat,
respawns, kills, weapons, fullscreen, and live status from the connectome.
The browser sends controls to `webcatch_server.py`; Python runs the controller
and returns the current state.

From the repository root, serve it locally:

```powershell
python webcatch_server.py
```

Then open <http://localhost:8080>.

For the GTX 1060 setup, install the optional GPU stack once:

```powershell
python -m pip install -r requirements-gpu.txt
```

The server requests `FLY_DEVICE=cuda` and exposes the active device and update
rate in the status card. The connectome is stepped at 10 Hz while movement and
rendering stay responsive at 60 FPS.

The original Pygame bridge remains available with `python fly_catch_bridge.py`.

The Pygame bridge writes a JSONL session log by default to
`brain_logs/brain_session_<timestamp>.jsonl`. Set `FLY_BRAIN_LOG=off` to
disable it, or set it to a specific path.

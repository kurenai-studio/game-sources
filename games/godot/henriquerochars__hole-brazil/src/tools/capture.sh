#!/usr/bin/env bash
# Genuine viewport screenshots and a compact animated gameplay GIF.
set -euo pipefail
project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"
godot_bin="${GODOT_BIN:-godot}"
capture_dir="$(mktemp -d)"
trap 'rm -rf "$capture_dir"' EXIT
mkdir -p docs/media
launcher=(xvfb-run -a -s "-screen 0 1280x1280x24")
XDG_DATA_HOME="$capture_dir/user-data" "${launcher[@]}" "$godot_bin" --path . --rendering-method gl_compatibility \
  --audio-driver Dummy --fixed-fps 30 --script res://scripts/capture.gd \
  -- "--output=$capture_dir"
cp "$capture_dir"/{menu,selection,gameplay,pause,results}.png "$capture_dir/capture.json" docs/media/
ffmpeg -hide_banner -loglevel error -y -framerate 15 \
  -i "$capture_dir/frames/frame_%04d.png" \
  -filter_complex '[0:v]fps=10,scale=270:-1:flags=lanczos,split[a][b];[a]palettegen=max_colors=96[p];[b][p]paletteuse=dither=bayer:bayer_scale=3' \
  -loop 0 docs/media/gameplay.gif
echo "Captured screenshots and gameplay GIF in docs/media/"

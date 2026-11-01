#!/bin/sh
# Records the Mac app and cuts the trailer for the landing page. Usage: art/trailer.sh <built Hamurapi.app>
# Each scene is a staged moment (HAMURABI_SHOT) left to play (HAMURABI_LIVE), with a caption laid over it.
set -e
APP="$1"; ROOT="$(cd "$(dirname "$0")/.." && pwd)"; T="${TMPDIR:-/tmp}/hamurapi-trailer"
rm -rf "$T"; mkdir -p "$T"
FONT=/System/Library/Fonts/Supplemental/Arial\ Bold.ttf

scene() {  # name, seconds, caption
  pkill -x Hamurapi 2>/dev/null || true; sleep 0.5
  HAMURABI_SHOT=$1 HAMURABI_LIVE=1 "$APP/Contents/MacOS/Hamurapi" >/dev/null 2>&1 &
  sleep 2
  osascript -e 'tell application "System Events" to tell process "Hamurapi"
    set frontmost to true
    set position of window 1 to {300, 120}
    set size of window 1 to {1280, 800}
  end tell' >/dev/null
  command -v cliclick >/dev/null && cliclick m:1900,1070  # park the pointer out of frame
  sleep 0.6
  screencapture -x -v -V "$2" -R300,120,1280,800 "$T/$1.mov"
  if [ -n "$3" ]; then
    magick -size 1280x800 xc:none -font "$FONT" -pointsize 44 -gravity north \
      -fill 'rgba(255,255,255,0.88)' -draw "roundrectangle 340,96 940,170 37,37" \
      -fill '#23262d' -annotate +0+108 "$3" "$T/$1.png"
  else
    magick -size 1280x800 xc:none "$T/$1.png"  # the title screen names itself
  fi
  ffmpeg -y -loglevel error -i "$T/$1.mov" -i "$T/$1.png" -filter_complex \
    "[0:v]scale=1280:800,fps=30[v];[v][1:v]overlay=0:0:enable='gte(t,0.4)'" -an -c:v libx264 -pix_fmt yuv420p -crf 20 "$T/$1.mp4"
  echo "file '$T/$1.mp4'" >> "$T/list.txt"
}

scene title 4 ""
scene orders 5 "Feed your people."
scene report 7 "Fill the barn."
scene plague 8 "Things go wrong."
scene card 5 "Make hard choices."
scene over 6 "Keep your crown."
pkill -x Hamurapi 2>/dev/null || true

# End card: icon, name, where to play.
magick -size 1280x800 xc:'#f6f6f4' \( "$ROOT/web/icon.png" -filter point -resize 200x200 \) -gravity center -geometry +0-150 -composite \
  -font "$FONT" -fill '#23262d' -pointsize 96 -annotate +0+40 "Hamurapi" \
  -fill '#666b75' -pointsize 34 -annotate +0+130 "Play now at hamurapi.jaybulb.com" "$T/end.png"
ffmpeg -y -loglevel error -loop 1 -t 3.5 -i "$T/end.png" -r 30 -c:v libx264 -pix_fmt yuv420p -crf 20 "$T/end.mp4"
echo "file '$T/end.mp4'" >> "$T/list.txt"

ffmpeg -y -loglevel error -f concat -safe 0 -i "$T/list.txt" -c copy "$T/silent.mp4"
LEN=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$T/silent.mp4")
ffmpeg -y -loglevel error -i "$T/silent.mp4" -stream_loop -1 -i "$ROOT/web/play/audio/music.mp3" -t "$LEN" \
  -af "afade=t=in:d=0.5,afade=t=out:st=$(echo "$LEN - 2" | bc):d=2" -c:v copy -c:a aac -b:a 128k -movflags +faststart "$ROOT/web/trailer.mp4"
ffmpeg -y -loglevel error -ss 6 -i "$ROOT/web/trailer.mp4" -frames:v 1 -vf scale=1200:-2 "$ROOT/web/og.png"
ls -la "$ROOT/web/trailer.mp4" | awk '{print $5, "bytes"}'; echo "length $LEN s"

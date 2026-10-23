#!/bin/bash

# Convert all .ogg and .wav files in current directory (not recursive) to .opus
for f in *.ogg; do
  # skip if no files match
  [ -e "$f" ] || continue

  # output filename: replace .ogg with .opus
  out="${f%.ogg}.opus"

  echo "Converting: $f → $out"
  ffmpeg -y -i "$f" -c:a libopus -b:a 128k "$out"
done

for f in *.wav; do
  # skip if no files match
  [ -e "$f" ] || continue

  # output filename: replace .wav with .opus
  out="${f%.wav}.opus"

  echo "Converting: $f → $out"
  ffmpeg -y -i "$f" -c:a libopus -b:a 128k "$out"
done

echo "Done!"

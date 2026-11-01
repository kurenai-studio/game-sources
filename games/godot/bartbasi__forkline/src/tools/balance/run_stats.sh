#!/bin/bash
# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
#
# What-ifs on tower numbers, for the report's suggestions to the game designer. Plays the bots on
# levels with edited tower stats (run.gd `stat=`; the data files are never touched). Run from the
# repo root after run_region1.sh:
#     bash tools/balance/run_stats.sh 2026-10-23 8
# Output: docs/balance/raw/<date>/stats/<level>_<variant>_<job>.json.

DATE="${1:-2026-10-23}"
JOBS="${2:-6}"
OUT="docs/balance/raw/$DATE/stats"
mkdir -p "$OUT"
LIST="$OUT/jobs.txt"
: > "$LIST"
add_variant() {
  # $1 level, $2 variant name, $3 level tweak, $4 stat tweak
  local V=${1: -1}   # the level number, so every variant of one level uses the same seeds
  local F="$OUT/${1}_${2}"
  local ARGS="level=$1 tweak=$3 stat=$4"
  echo "mode=search $ARGS seed=$((13000 + V)) evals=800 only=any out=${F}_any.json" >> "$LIST"
  echo "mode=search $ARGS seed=$((14000 + V)) evals=800 only=sling_post out=${F}_sling_post.json" >> "$LIST"
  if [ "$1" != "r1_l5" ]; then
    echo "mode=search $ARGS seed=$((15000 + V)) evals=800 only=pumpkin_catapult out=${F}_pumpkin_catapult.json" >> "$LIST"
  fi
  echo "mode=spread $ARGS seed=$((16000 + V)) n=100 out=${F}_spread.json" >> "$LIST"
}
for LEVEL_TWEAK in "r1_l4 count_pct:200" "r1_l5 count_pct:150" "r1_l2 count_pct:150"; do
  set -- $LEVEL_TWEAK
  L=$1
  T=$2
  add_variant $L base "$T" "sling_post.cost:+0"
  add_variant $L splash25 "$T" "pumpkin_catapult.splash:+25"
  add_variant $L splash50 "$T" "pumpkin_catapult.splash:+50"
  add_variant $L damage150 "$T" "pumpkin_catapult.damage:x150"
  add_variant $L splash50_damage130 "$T" "pumpkin_catapult.splash:+50~pumpkin_catapult.damage:x130"
  add_variant $L sling_damage80 "$T" "sling_post.damage:x80"
  add_variant $L cat_plus_sling_minus "$T" "pumpkin_catapult.splash:+25~pumpkin_catapult.damage:x125~sling_post.damage:x85"
done
cat "$LIST" | xargs -P "$JOBS" -I{} bash -c 'timeout 3000 godot --headless --path . --script res://tools/balance/run.gd -- {} > /dev/null 2>> '"$OUT"'/errors.txt'
echo "done: $(ls "$OUT" | wc -l) files in $OUT"

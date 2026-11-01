#!/bin/bash
# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
#
# The jobs of a balance pass that need the first jobs done (run it after run_pass.sh has finished, from the repo root):
#     bash tools/balance/run_pass_post.sh 2026-10-26 3 [levels]
# 1. A pair of lone attacker searches where only one stopped dry (no win in the first 2500 builds) and the other did not:
#    the dry one is played again in full, as `..._full.json` (RULES 12.6 lets both stop only when neither has won).
# 2. The determinism jobs again, each in a new process: the chain hashes must match the first set.
#    And for a Twist whose 1500 build search won nothing, two searches of 6000 builds (`..._search_twist_deep_a.json` and `_b.json`).
# 3. The timing runs (benchmark.gd), one at a time so the other jobs do not slow them down. Run this part when nothing
#    else of yours is running.
# Environment: EVALS_SOLO (default 6000), SEED_SHIFT (as in run_pass.sh), SKIP_BENCH=1 (do 1 and 2 only), FIXTURE=1 (as in run_pass.sh:
# the fixture levels on the test catalog).

DATE="${1:-2026-10-26}"
JOBS="${2:-3}"
shift $(( $# < 2 ? $# : 2 ))
LEVELS="$*"
FX=""
if [ "$FIXTURE" = "1" ]; then FX=" fixture=1"; fi
if [ -z "$LEVELS" ] && [ "$FIXTURE" = "1" ]; then
  LEVELS="r5_fx1 r6_fx1 r7_fx1 r8_fx1 r8_fx2"
fi
if [ -z "$LEVELS" ]; then
  LEVELS=$(grep -o '"r[0-9]*_l[0-9]*"' data/levels/campaign.json | tr -d '"')
fi
EVALS_SOLO="${EVALS_SOLO:-6000}"
STOP_DRY="${STOP_DRY:-2500}"
SHIFT="${SEED_SHIFT:-0}"
OUT="docs/balance/raw/$DATE"
LIST="$OUT/post_jobs.txt"
: > "$LIST"
for FILE in "$OUT"/*_solo_*_a.json; do
  [ -f "$FILE" ] || continue
  B_FILE="${FILE%_a.json}_b.json"
  [ -f "$B_FILE" ] || continue
  # Dry: no win, and fewer builds than the full search (the first files of the 2026-10-25 pass lack the stopped_dry flag).
  A_DRY=$(tr -d '[:space:]' < "$FILE" | grep -c '"evals":'"$STOP_DRY"',.*"wins":0[,}]')
  B_DRY=$(tr -d '[:space:]' < "$B_FILE" | grep -c '"evals":'"$STOP_DRY"',.*"wins":0[,}]')
  if [ "$A_DRY" != "$B_DRY" ]; then
    if [ "$A_DRY" = "1" ]; then DRY_FILE="$FILE"; else DRY_FILE="$B_FILE"; fi
    LEVEL=$(basename "$DRY_FILE" | sed 's/_solo_.*//')
    TOWER=$(basename "$DRY_FILE" | sed 's/.*_solo_\(.*\)_[ab].json/\1/')
    SEED=$(grep -o '"seed": [0-9]*' "$DRY_FILE" | head -1 | grep -o '[0-9]*')
    echo "mode=search level=$LEVEL seed=$SEED evals=$EVALS_SOLO only=solo:$TOWER$FX out=${DRY_FILE%.json}_full.json" >> "$LIST"
  fi
done
for LEVEL in $LEVELS; do
  REGION=$(echo "$LEVEL" | sed 's/^r\([0-9]*\)_.*/\1/')
  NUM=$(echo "$LEVEL" | sed 's/.*_l//; s/.*_fx//')
  S=$((SHIFT + (REGION * 10 + NUM) * 100))
  echo "mode=det level=$LEVEL seed=$((750000 + S))$FX out=$OUT/${LEVEL}_det_again.json" >> "$LIST"
  # A Twist whose 1500 build search won nothing: two searches of 6000 builds with different seeds (RULES 12.6).
  if [ -f "$OUT/${LEVEL}_search_twist.json" ] && tr -d '[:space:]' < "$OUT/${LEVEL}_search_twist.json" | grep -q '"wins":0[,}]'; then
    echo "mode=search level=$LEVEL twist=1 seed=$((772000 + S)) evals=$EVALS_SOLO only=any$FX out=$OUT/${LEVEL}_search_twist_deep_a.json" >> "$LIST"
    echo "mode=search level=$LEVEL twist=1 seed=$((774000 + S)) evals=$EVALS_SOLO only=any$FX out=$OUT/${LEVEL}_search_twist_deep_b.json" >> "$LIST"
  fi
done
run_one() {
  OUTFILE=$(echo "$1" | sed 's/.*out=//')
  if [ -f "$OUTFILE" ]; then return; fi
  if ! mkdir "$2/.lock_$(basename "$OUTFILE")" 2> /dev/null; then return; fi
  timeout 7200 godot --headless --path . --script res://tools/balance/run.gd -- $1 > /dev/null 2>> "$2/errors.txt"
}
export -f run_one
cat "$LIST" | xargs -P "$JOBS" -I{} bash -c 'run_one "{}" '"$OUT"
if [ -z "$SKIP_BENCH" ]; then
  for LEVEL in $LEVELS; do
    if [ ! -f "$OUT/${LEVEL}_bench.json" ] && mkdir "$OUT/.lock_${LEVEL}_bench.json" 2> /dev/null; then
      timeout 3000 godot --headless --path . --script res://tools/balance/benchmark.gd -- level=$LEVEL$FX \
        build="$OUT/${LEVEL}_search_any.json,$OUT/${LEVEL}_spread.json" out="$OUT/${LEVEL}_bench.json" > /dev/null 2>> "$OUT/errors.txt"
    fi
  done
fi
echo "done: $(ls "$OUT" | wc -l) files in $OUT"

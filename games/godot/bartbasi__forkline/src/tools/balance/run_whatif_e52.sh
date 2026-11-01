#!/bin/bash
# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
#
# The star 3 what-ifs of the region 5 report (docs/balance/region5-2026-10-28.md). On the region 5 levels where the lone Sling Post earned
# three stars it plays other star 3 rules (run.gd tweak=star3:KIND;N, in memory only): one search with the towers the rule leaves, and one
# lone Sling Post search unless the rule bans the Sling Post (a lone Catapult, Longbow, Bramble Cottage or Firework cannot keep 15 lives
# on these levels, RULES 12.6). Run it from the repo root, after run_pass.sh:
#     bash tools/balance/run_whatif_e52.sh 2026-10-28-e52 3
# Seeds: 990000 + 1000 * R + 100 * K + A, R the rule's number below, K = 10 * region + level number, A 0 for the search with the towers
# the rule leaves and 1 for the lone Sling Post. With CHECKS=1 the lone Sling Post searches are 6000 builds and use the seeds + 500.
# Output: docs/balance/raw/<date>/whatif_star3/<level>_r<R>_<job>.json. Several copies can work on one folder (a lock folder per job).
# Environment: EVALS (default 2500), DRY=1 (only write the list).

DATE="${1:-2026-10-28-e52}"
JOBS="${2:-3}"
EVALS="${EVALS:-2500}"
OUT="docs/balance/raw/$DATE/whatif_star3"
mkdir -p "$OUT"
LIST="$OUT/jobs.txt"
: > "$LIST"
# level, then the rules to try. The towers the level offers (without the Sling Post and, for 5-3, the Bell is allowed again).
RULES=(
  "r5_l1 star3:tower_ban;sling_post star3:tier_at_most;2 star3:towers_at_most;4"
  "r5_l3 star3:tower_ban;sling_post star3:tier_at_most;2 star3:towers_at_most;6"
  "r5_l4 star3:tower_ban;sling_post star3:tier_at_most;2 star3:towers_at_most;5"
  "r5_l6 star3:tower_ban;sling_post star3:tier_at_most;2 star3:towers_at_most;6"
)
LEFT_5_1="lullaby_bell,pumpkin_catapult,longbow_loft,firework_tower,bakery"
LEFT_5_X="lullaby_bell,pumpkin_catapult,longbow_loft,firework_tower,bakery,bramble_cottage"
for LINE in "${RULES[@]}"; do
  set -- $LINE
  LEVEL=$1
  NUM=$(echo "$LEVEL" | sed 's/.*_l//')
  REGION=$(echo "$LEVEL" | sed 's/^r\([0-9]*\)_l.*/\1/')
  K=$((REGION * 10 + NUM))
  for R in 1 2 3; do
    RULE=$((R + 1))
    RULE=${!RULE}
    if [ "$RULE" = "star3:tower_ban;sling_post" ]; then
      if [ "$LEVEL" = "r5_l1" ]; then ONLY="$LEFT_5_1"; else ONLY="$LEFT_5_X"; fi
      echo "mode=search level=$LEVEL seed=$((990000 + 1000 * R + K * 100)) evals=$EVALS only=$ONLY tweak=$RULE out=$OUT/${LEVEL}_r${R}_nosling_any.json" >> "$LIST"
    else
      echo "mode=search level=$LEVEL seed=$((990000 + 1000 * R + K * 100)) evals=$EVALS only=any tweak=$RULE out=$OUT/${LEVEL}_r${R}_any.json" >> "$LIST"
      if [ -n "$CHECKS" ]; then
        echo "mode=search level=$LEVEL seed=$((990000 + 1000 * R + K * 100 + 501)) evals=6000 stop_dry=2500 only=solo:sling_post tweak=$RULE out=$OUT/check_${LEVEL}_r${R}_solo_sling_post.json" >> "$LIST"
      else
        echo "mode=search level=$LEVEL seed=$((990000 + 1000 * R + K * 100 + 1)) evals=$EVALS only=solo:sling_post tweak=$RULE out=$OUT/${LEVEL}_r${R}_solo_sling_post.json" >> "$LIST"
      fi
    fi
  done
done
if [ -n "$DRY" ]; then
  echo "wrote $(wc -l < "$LIST") jobs to $LIST"
  exit 0
fi
run_one() {
  OUTFILE=$(echo "$1" | sed 's/.*out=//')
  if [ -f "$OUTFILE" ]; then return; fi
  if ! mkdir "$2/.lock_$(basename "$OUTFILE")" 2> /dev/null; then return; fi
  timeout 7200 godot --headless --path . --script res://tools/balance/run.gd -- $1 > /dev/null 2>> "$2/errors.txt"
}
export -f run_one
cat "$LIST" | xargs -P "$JOBS" -I{} bash -c 'run_one "{}" '"$OUT"
echo "done: $(ls "$OUT" | wc -l) files in $OUT"

#!/bin/bash
# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
#
# The star 3 what-ifs of the 2026-10-25 report. On the levels where the lone Sling Post earned three stars it plays other
# star 3 rules (run.gd tweak=star3:KIND;N, in memory only): one any-tower search, and one lone Sling Post search unless
# the rule bans the Sling Post (a lone Catapult, Longbow or Firework cannot keep 15 lives on these levels, RULES 12.6).
# Run it from the repo root, after run_pass.sh:
#     bash tools/balance/run_whatif_b3.sh 2026-10-25-b3 3
# Seeds: 890000 + 1000 * R + 100 * K + A, R the rule's number below, K = 10 * region + level number, A 0 for the
# any-tower search and 1 for the lone Sling Post. Output: docs/balance/raw/<date>/whatif/<level>_r<R>_<job>.json.
# Several copies can work on one folder (a lock folder per job). A job whose file exists is skipped.
# Environment: EVALS (default 2500), DRY=1 (only write jobs.txt), CHECKS=1 (the longer checks of the recommended rules instead).

DATE="${1:-2026-10-25-b3}"
JOBS="${2:-3}"
EVALS="${EVALS:-2500}"
OUT="docs/balance/raw/$DATE/whatif"
mkdir -p "$OUT"
LIST="$OUT/jobs.txt"
: > "$LIST"
RULES=(
  "r3_l1 star3:tower_ban;sling_post star3:tier_at_most;2 star3:towers_at_most;5"
  "r3_l2 star3:towers_at_most;5 star3:towers_at_most;4 star3:tier_at_most;2 star3:tower_ban;sling_post"
  "r3_l3 star3:tier_at_most;2 star3:towers_at_most;5 star3:tower_ban;sling_post star3:gates_at_most;0"
  "r3_l6 star3:tower_ban;sling_post star3:towers_at_most;6 star3:tier_at_most;2"
)
for LINE in "${RULES[@]}"; do
  set -- $LINE
  LEVEL=$1
  NUM=$(echo "$LEVEL" | sed 's/.*_l//')
  REGION=$(echo "$LEVEL" | sed 's/^r\([0-9]*\)_l.*/\1/')
  S=$(((REGION * 10 + NUM) * 100))
  for R in 1 2 3 4; do
    RULE=$((R + 1))
    RULE=${!RULE}
    if [ -z "$RULE" ]; then continue; fi
    echo "mode=search level=$LEVEL seed=$((890000 + 1000 * R + S)) evals=$EVALS only=any tweak=$RULE out=$OUT/${LEVEL}_r${R}_any.json" >> "$LIST"
    if [ "$RULE" != "star3:tower_ban;sling_post" ]; then
      echo "mode=search level=$LEVEL seed=$((890000 + 1000 * R + S + 1)) evals=$EVALS only=solo:sling_post tweak=$RULE out=$OUT/${LEVEL}_r${R}_solo_sling_post.json" >> "$LIST"
    fi
  done
done
# CHECKS=1: the longer checks of the rules the report recommends (RULES 12.6: two lone Sling Post searches of 6000 builds, so
# 2500 build screens above are not the verdict), and any-tower searches with the Sling Post left out for the levels where a
# ban was tried (the any-tower search can miss such builds: 3-4 and 4-2 in the main pass). Seeds 960000 + 100 K + 10 N + A.
if [ -n "$CHECKS" ]; then
  LIST="$OUT/jobs_checks.txt"
  : > "$LIST"
  check() {  # level tag rule N
    K=$((10 * ${1:1:1} + ${1:4:1}))
    echo "mode=search level=$1 seed=$((960000 + K * 100 + 10 * $4 + 1)) evals=6000 only=solo:sling_post tweak=$3 out=$OUT/check_$1_$2_sling_post_$4.json" >> "$LIST"
  }
  for N in 0 1; do
    check r3_l1 tier2 "star3:tier_at_most;2" $N
    check r3_l2 tier2 "star3:tier_at_most;2" $N
    check r3_l2 towers5 "star3:towers_at_most;5" $N
    check r3_l3 tier2 "star3:tier_at_most;2" $N
    check r3_l3 towers5 "star3:towers_at_most;5" $N
  done
  for N in 0 1; do
    echo "mode=search level=r3_l3 seed=$((960000 + 3300 + 10 * N + 2)) evals=6000 only=lullaby_bell,pumpkin_catapult,longbow_loft,firework_tower tweak=star3:tower_ban;sling_post out=$OUT/check_r3_l3_nosling_any_$N.json" >> "$LIST"
    echo "mode=search level=r3_l6 seed=$((960000 + 3600 + 10 * N + 2)) evals=6000 only=lullaby_bell,pumpkin_catapult,longbow_loft,firework_tower tweak=star3:tower_ban;sling_post out=$OUT/check_r3_l6_nosling_any_$N.json" >> "$LIST"
    echo "mode=search level=r3_l1 seed=$((960000 + 3100 + 10 * N + 2)) evals=6000 only=lullaby_bell,pumpkin_catapult,longbow_loft,firework_tower tweak=star3:tower_ban;sling_post out=$OUT/check_r3_l1_nosling_any_$N.json" >> "$LIST"
    echo "mode=search level=r3_l2 seed=$((960000 + 3200 + 10 * N + 2)) evals=6000 only=lullaby_bell,pumpkin_catapult,longbow_loft,firework_tower tweak=star3:tower_ban;sling_post out=$OUT/check_r3_l2_nosling_any_$N.json" >> "$LIST"
  done
fi
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

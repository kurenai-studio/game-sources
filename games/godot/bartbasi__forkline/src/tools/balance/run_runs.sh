#!/bin/bash
# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
#
# The job list of the run and daily report (task B2, docs/balance/runs-2026-10-24.md). Run it from the
# root of a clean copy of the commit being measured (git archive), with the raw folder given as OUT:
#     OUT=C:/path/to/forkline/docs/balance/raw/2026-10-24-b2 bash tools/balance/run_runs.sh 3
# Arguments: how many jobs run at once (default 3; the machine is shared). DRY=1 only writes jobs.txt.
#
# Seeds. Run i (1 to 200) has the run seed (i * 2654435761) mod 2^32 (runs.gd seed_of). Day n (0 to 399)
# is 2026-10-25 plus n days, with the daily seed YYYYMMDD. A random strategy's generator is seeded from
# the run seed ("<seed>:search".hash()), a bot's own generator from "<seed>:<strategy id>:bot".hash().
#   rates   200 seeds in 4 chunks of 50, the 16 named strategies, Normal and Relaxed, no unlocks (base) and all cards
#   search  100 random strategies on each of seeds 1 to 50 (2 chunks of 25), Normal base, Normal all, Relaxed base
#   daily   400 days in 8 chunks, the 16 named strategies, and up to 100 random strategies on a day none of them wins
#   det     the same-seed checks, seeds 1 to 50 and the first 50 days; run twice in two processes
#   static  the stacks, the packs and the largest wave with each risk card
#   risk    snapshots before each wave, then each risk card on that wave (STRATS, default economy_wide)
#   cardvalue  random_wide and random_tall play seeds 1 to 200; before each pick the state is saved and each offered card
#              is taken in turn and the run played on, base pool and all cards
#   whatif  seeds 1 to 50, Normal, no unlocks, with the final strength 236 (strength_step:8) and 202 (strength_step:6),
#           and with Tea Break giving 3 lives and 1 life (tea_break:3, tea_break:1),
#           and with bots that build a Bakery reaching only one spot (bakery_min=1)

JOBS="${1:-3}"
OUT="${OUT:-docs/balance/raw/2026-10-24-b2}"
STRATS="${STRATS:-economy_wide}"
mkdir -p "$OUT"
LIST="$OUT/jobs.txt"
: > "$LIST"
echo "mode=static out=$OUT/static.json" >> "$LIST"
echo "mode=det first=1 count=50 out=$OUT/det.json" >> "$LIST"
for STRAT in $STRATS; do
  echo "mode=risk first=1 count=30 strat=$STRAT out=$OUT/risk_$STRAT.json" >> "$LIST"
done
for FIRST in 1 51 101 151; do
  for POOL in base all; do
    echo "mode=cardvalue first=$FIRST count=50 pool=$POOL out=$OUT/cardvalue_${POOL}_$FIRST.json" >> "$LIST"
  done
done
for FIRST in 1 51 101 151; do
  for POOL in base all; do
    for R in 0 1; do
      echo "mode=rates first=$FIRST count=50 pool=$POOL relaxed=$R out=$OUT/rates_${POOL}_r${R}_$FIRST.json" >> "$LIST"
    done
  done
done
for STEP in 8 6; do
  echo "mode=rates first=1 count=50 pool=base relaxed=0 tweak=strength_step:$STEP out=$OUT/whatif_step${STEP}_base_r0.json" >> "$LIST"
done
for POOL in base all; do
  echo "mode=rates first=1 count=50 pool=$POOL relaxed=0 bakery_min=1 out=$OUT/whatif_bakery1_${POOL}_r0.json" >> "$LIST"
done
for TEA in 3 1; do
  echo "mode=rates first=1 count=50 pool=base relaxed=0 tweak=tea_break:$TEA out=$OUT/whatif_tea${TEA}_base_r0.json" >> "$LIST"
done
for FROM in 0 50 100 150 200 250 300 350; do
  echo "mode=daily from=$FROM count=50 extra=100 out=$OUT/daily_$FROM.json" >> "$LIST"
done
for FIRST in 1 26; do
  echo "mode=search first=$FIRST count=25 n=100 pool=base relaxed=0 out=$OUT/search_base_r0_$FIRST.json" >> "$LIST"
  echo "mode=search first=$FIRST count=25 n=100 pool=all relaxed=0 out=$OUT/search_all_r0_$FIRST.json" >> "$LIST"
  echo "mode=search first=$FIRST count=25 n=100 pool=base relaxed=1 out=$OUT/search_base_r1_$FIRST.json" >> "$LIST"
done
if [ -n "$DRY" ]; then
  echo "wrote $(wc -l < "$LIST") jobs to $LIST"
  exit 0
fi
run_one() {
  OUTFILE=$(echo "$1" | sed 's/.*out=//')
  if [ -f "$OUTFILE" ]; then return; fi
  timeout 7200 godot --headless --path . --script res://tools/balance/runs.gd -- $1 > /dev/null 2>> "$2/errors.txt"
}
export -f run_one
cat "$LIST" | xargs -P "$JOBS" -I{} bash -c 'run_one "{}" '"$OUT"
# The same-seed checks again in a new process: the chain hash must match the first.
if [ ! -f "$OUT/det_again.json" ]; then
  timeout 7200 godot --headless --path . --script res://tools/balance/runs.gd -- mode=det first=1 count=50 out="$OUT/det_again.json" > /dev/null 2>> "$OUT/errors.txt"
fi
echo "done: $(ls "$OUT" | wc -l) files in $OUT"

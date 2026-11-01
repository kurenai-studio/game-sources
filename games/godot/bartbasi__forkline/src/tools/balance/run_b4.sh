#!/bin/bash
# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
#
# The job list of the second run and daily report (task B4, docs/balance/runs-2026-10-25.md). Run it from the root of a
# clean copy of the commit being measured (git archive, then godot --headless --path . --import), with the raw folder in OUT:
#     OUT=C:/path/to/forkline/docs/balance/raw/2026-10-25-b4 bash tools/balance/run_b4.sh A 3
#     OUT=... bash tools/balance/run_b4.sh B 3        (after A: it reads jobs_B_extra.txt, made from A's results)
#     OUT=... bash tools/balance/run_b4.sh C 3        (jobs_C_extra.txt: runs_summary.gd part=allstacks, OUTDIR replaced by $OUT)
#     OUT=... bash tools/balance/run_b4.sh D 2        (jobs_D_extra.txt, written by hand)
# jobs_B_extra.txt is the output of runs_summary.gd part=flags (OUTDIR replaced by $OUT) plus the what-ifs below.
# Arguments: the phase (A, B, C or D) and how many jobs run at once (default 3; the machine is shared). DRY=1 only writes the list.
#
# Seeds. Run i has the run seed (i * 2654435761) mod 2^32 (runs.gd seed_of). Day n (0 to 399) is 2026-10-25 plus n days, with
# the daily seed YYYYMMDD (the same 400 days as B2, so the two reports can be compared day by day). A random strategy's
# generator is seeded from the run seed ("<seed>:search".hash()), a bot's own from "<seed>:<strategy id>:bot".hash().
# The bots are B4's: Bakery from wave 9, perks that fit, no boss aim (runs.gd bakery_from, perk_fit, boss_aim).
#
# Phase A
#   rates      seeds 1 to 200 in 4 chunks of 50, the 16 named strategies, Normal and Relaxed, base cards and all cards
#   det        seeds 1 to 50 and the first 50 days (run twice, in two processes), and seeds 51 to 200 with days 50 to 149
#   static     the stacks, the packs and the most creatures a pack wave spawns with each risk card
#   risk       economy_wide on seeds 1 to 30, every risk card on waves 2 to 17
#   daily      400 days in 8 chunks, the 16 named strategies, and up to 400 random strategies on a day none of them wins
#   cardvalue  random_wide and random_tall play seeds 1 to 200, base cards and all cards, each offered card taken in turn
# Phase B (what the results of A call for)
#   search     100 random strategies on each seed of 1 to 50 that no named strategy won (Normal, base cards)
#   force      every stack and every pack that fails a check of RULES 14.8, played on seeds 1 to 200 (16 plays a seed)
#   whatif     bots as in B2 (perk_fit=0 and bakery_from=0), blind perks, Bakery at once, boss_aim=1, and pools with the unlock cards
#              put back a few at a time (pool=plus:id,id), on seeds 1 to 100
# Phase C    every one of the 42 stacks forced onto seeds 1 to 200 (natural seeds miss walls: TUNING_RUNS 3.5)
# Phase D    perk_fit=2 (every sidegrade perk passed) with every card, seeds 1 to 100

# B6: TIER=N plays the runs and dailies at content tier N (RULES 14.9), FIXTURE=1 on the fixture data (tools/balance/fixtures.gd). Use a
# folder of its own for each tier (OUT=.../tier4). Phases B, C and D read their job files, which runs_summary.gd prints with the flags (tier=N fixture=1).
TF=""
if [ -n "$TIER" ] && [ "$TIER" != "0" ]; then TF="$TF tier=$TIER"; fi
if [ "$FIXTURE" = "1" ]; then TF="$TF fixture=1"; fi

PHASE="${1:-A}"
JOBS="${2:-3}"
OUT="${OUT:-docs/balance/raw/2026-10-25-b4}"
mkdir -p "$OUT"
LIST="$OUT/jobs_$PHASE.txt"
: > "$LIST"
if [ "$PHASE" = "A" ]; then
  for FIRST in 1 51 101 151; do
    echo "mode=rates first=$FIRST count=50 pool=base relaxed=0$TF out=$OUT/rates_base_r0_$FIRST.json" >> "$LIST"
  done
  for FIRST in 1 51 101 151; do
    echo "mode=rates first=$FIRST count=50 pool=base relaxed=1$TF out=$OUT/rates_base_r1_$FIRST.json" >> "$LIST"
  done
  echo "mode=static$TF out=$OUT/static.json" >> "$LIST"
  echo "mode=det first=1 count=50$TF out=$OUT/det.json" >> "$LIST"
  echo "mode=det first=51 count=150 days=100 day_from=50$TF out=$OUT/det_more.json" >> "$LIST"
  for FIRST in 1 51 101 151; do
    echo "mode=rates first=$FIRST count=50 pool=all relaxed=0$TF out=$OUT/rates_all_r0_$FIRST.json" >> "$LIST"
    echo "mode=rates first=$FIRST count=50 pool=all relaxed=1$TF out=$OUT/rates_all_r1_$FIRST.json" >> "$LIST"
  done
  echo "mode=risk first=1 count=30 strat=economy_wide$TF out=$OUT/risk_economy_wide.json" >> "$LIST"
  for FROM in 0 50 100 150 200 250 300 350; do
    echo "mode=daily from=$FROM count=50 extra=400$TF out=$OUT/daily_$FROM.json" >> "$LIST"
  done
  for FIRST in 1 51 101 151; do
    for POOL in base all; do
      echo "mode=cardvalue first=$FIRST count=50 pool=$POOL$TF out=$OUT/cardvalue_${POOL}_$FIRST.json" >> "$LIST"
    done
  done
else
  # Phases B, C and D read a list made from phase A's files: see the header.
  cat "$OUT/jobs_${PHASE}_extra.txt" >> "$LIST"
fi
if [ -n "$DRY" ]; then
  echo "wrote $(wc -l < "$LIST") jobs to $LIST"
  exit 0
fi
run_one() {
  OUTFILE=$(echo "$1" | sed 's/.*out=//')
  if [ -f "$OUTFILE" ]; then return; fi
  timeout 14400 godot --headless --path . --script res://tools/balance/runs.gd -- $1 > /dev/null 2>> "$2/errors.txt"
}
export -f run_one
cat "$LIST" | xargs -P "$JOBS" -I{} bash -c 'run_one "{}" '"$OUT"
if [ "$PHASE" = "A" ] && [ ! -f "$OUT/det_again.json" ]; then
  # The same-seed checks again in a new process: the chain hash must match the first.
  timeout 7200 godot --headless --path . --script res://tools/balance/runs.gd -- mode=det first=1 count=50$TF out="$OUT/det_again.json" > /dev/null 2>> "$OUT/errors.txt"
fi
echo "done: $(ls "$OUT" | wc -l) files in $OUT"

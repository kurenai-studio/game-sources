#!/bin/bash
# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
#
# The job lists of task B6 (docs/balance/b6-trial-2026-10-28.md). Run from the repo root:
#     OUT=docs/balance/raw/2026-10-28-b6 bash tools/balance/run_b6.sh T0 4     # tier 0 jobs of the last runs, played again
#     OUT=... bash tools/balance/run_b6.sh PL 4                                # the need and plain-recipe jobs of every level and Twist in campaign.json
#     OUT=... bash tools/balance/run_b6.sh LS 4                                # forced lone searches for the Bramble Cottage and the Snow Fort
#     OUT=... bash tools/balance/run_b6.sh RT 4                                # runs and the daily at content tiers 1 to 4 (fixture data)
#     OUT=... bash tools/balance/run_b6.sh FS 4                                # whole runs forced onto a map with each feature segment (fixture data)
#     OUT=... bash tools/balance/run_b6.sh PK 2                                # the most crowded wave as a saved game (fixture data)
# And the fixture levels through the pass scripts (RULES 12.6 on the test catalog):
#     FIXTURE=1 EVALS=600 EVALS_SOLO=600 STOP_DRY=300 bash tools/balance/run_pass.sh 2026-10-28-b6/fixtures 4
#     FIXTURE=1 EVALS_SOLO=600 STOP_DRY=300 bash tools/balance/run_pass_post.sh 2026-10-28-b6/fixtures 4
# Arguments: the phase and how many jobs run at once (default 4; the machine is shared). DRY=1 only writes the list.
#
# T0 plays again, with the tools as they are now, jobs that the 2026-10-26 campaign recheck and the 2026-10-27 run report played with the
# tools before B6: the same command lines (so the same seeds), written to OUT/campaign and OUT/runs. Then compare the files:
#     godot --headless --path . --script res://tools/balance/compare_raw.gd -- old=res://docs/balance/raw/2026-10-26-b4b new=res://docs/balance/raw/2026-10-28-b6/campaign ignore=digest,chain_hash,search_hash
#     godot --headless --path . --script res://tools/balance/compare_raw.gd -- old=res://docs/balance/raw/2026-10-27-b5 new=res://docs/balance/raw/2026-10-28-b6/runs ignore=battle_hash,run_hash,chain_hash,map_hash
# (A hash is a hash of a saved battle or run, and the save format has grown since, so hashes are ignored; every other value must match.)
# Environment OLD_C and OLD_R name the raw folders whose job lists T0 reads (defaults: the two above).
#
# Fixture data. RT and PK use `fixture=1` (tools/balance/fixtures.gd): the real data holds no content tiers yet. RT, for each tier T from 1 to 4,
# writes OUT/tierT: the 16 named strategies on run seeds 1 to RT_SEEDS (default 12), Normal and Relaxed, base cards and every card; the same-seed
# checks (det.json, and det_again.json in a second process); the daily on 12 days (RT_DAYS) with up to 20 random strategies on a day no named strategy wins; the packs and maps (static).
# Summarize a tier with: runs_summary.gd -- dir=OUT/tierT tier=T fixture=1 part=b4

PHASE="${1:-T0}"
JOBS="${2:-4}"
OUT="${OUT:-docs/balance/raw/2026-10-28-b6}"
OLD_C="${OLD_C:-docs/balance/raw/2026-10-26-b4b}"
OLD_R="${OLD_R:-docs/balance/raw/2026-10-27-b5}"
mkdir -p "$OUT"
LIST="$OUT/jobs_$PHASE.txt"
: > "$LIST"
SCRIPT=run.gd
if [ "$PHASE" = "T0" ]; then
  mkdir -p "$OUT/campaign" "$OUT/runs"
  for LEVEL in r3_l1 r3_l2 r3_l3 r3_l6; do
    echo "SCRIPT=run.gd mode=need level=$LEVEL out=$OUT/campaign/${LEVEL}_need.json" >> "$LIST"
  done
  grep -h '^mode=' "$OLD_C/jobs.txt" "$OLD_C/post_jobs.txt" | sed "s#out=.*/#out=$OUT/campaign/#; s#^#SCRIPT=run.gd #" >> "$LIST"
  grep -E 'rates_base_r0_1\.json|rates_all_r1_51\.json|mode=static|first=1 count=50 out=.*/det\.json|risk_economy_wide|daily_0\.json' "$OLD_R/jobs_A.txt" \
    | sed "s#out=.*/#out=$OUT/runs/#; s#^#SCRIPT=runs.gd #" >> "$LIST"
  echo "SCRIPT=runs.gd mode=det first=1 count=50 out=$OUT/runs/det_again.json" >> "$LIST"
elif [ "$PHASE" = "PL" ]; then
  # Cheap and wide: run it with the tools as they were before B6 (a copy of the repo with tools/balance from the commit before) and with the tools
  # now, into two folders, and compare them with compare_raw.gd (ignore=digest). The files must be equal.
  mkdir -p "$OUT/plain"
  for LEVEL in $(grep -o '"r[0-9]*_l[0-9]*"' data/levels/campaign.json | tr -d '"'); do
    OPT=""
    if [ "${LEVEL:1:1}" = "1" ]; then OPT=" compare_old=1"; fi
    echo "SCRIPT=run.gd mode=need level=$LEVEL out=$OUT/plain/${LEVEL}_need.json" >> "$LIST"
    echo "SCRIPT=run.gd mode=plain level=$LEVEL$OPT out=$OUT/plain/${LEVEL}_plain.json" >> "$LIST"
    if grep -q '"twist"' "data/levels/$LEVEL.json"; then
      echo "SCRIPT=run.gd mode=plain level=$LEVEL twist=1 out=$OUT/plain/${LEVEL}_plain_twist.json" >> "$LIST"
    fi
  done
elif [ "$PHASE" = "LS" ]; then
  mkdir -p "$OUT/fixtures"
  # The need rule skips these searches on the fixture levels (their flyers cost 6 lives or more), so they are forced here.
  # Bramble Cottage on 5-fx1 and 6-fx1, Snow Fort on 7-fx1 and 8-fx1: two seeds each, 600 builds.
  for PAIR in "r5_fx1 bramble_cottage 5" "r6_fx1 bramble_cottage 5" "r7_fx1 snow_fort 6" "r8_fx1 snow_fort 6"; do
    set -- $PAIR
    K=$(( 100 * (10 * ${1:1:1} + 1) + $3 ))
    echo "SCRIPT=run.gd mode=search level=$1 fixture=1 seed=$((730000 + K)) evals=600 stop_dry=300 only=solo:$2 out=$OUT/fixtures/${1}_forced_solo_$2_a.json" >> "$LIST"
    echo "SCRIPT=run.gd mode=search level=$1 fixture=1 seed=$((760000 + K)) evals=600 stop_dry=300 only=solo:$2 out=$OUT/fixtures/${1}_forced_solo_$2_b.json" >> "$LIST"
  done
elif [ "$PHASE" = "RT" ]; then
  SEEDS="${RT_SEEDS:-12}"
  DAYS="${RT_DAYS:-12}"
  for T in 1 2 3 4; do
    D="$OUT/tier$T"
    mkdir -p "$D"
    for CFG in "base 0" "base 1" "all 0" "all 1"; do
      set -- $CFG
      echo "SCRIPT=runs.gd mode=rates fixture=1 tier=$T first=1 count=$SEEDS pool=$1 relaxed=$2 out=$D/rates_$1_r$2_1.json" >> "$LIST"
    done
    echo "SCRIPT=runs.gd mode=det fixture=1 tier=$T first=1 count=$SEEDS days=$DAYS out=$D/det.json" >> "$LIST"
    echo "SCRIPT=runs.gd mode=det fixture=1 tier=$T first=1 count=$SEEDS days=$DAYS out=$D/det_again.json" >> "$LIST"
    echo "SCRIPT=runs.gd mode=static fixture=1 tier=$T out=$D/static.json" >> "$LIST"
    echo "SCRIPT=runs.gd mode=daily fixture=1 tier=$T from=0 count=$DAYS extra=20 out=$D/daily_0.json" >> "$LIST"
  done
elif [ "$PHASE" = "FS" ]; then
  # A natural draw of 12 seeds may not draw a feature segment, so one stack with each is forced onto seeds 1 to 6 (full plays, tier 4,
  # all 16 named strategies): the first stack runs_summary.gd part=allstacks lists for it.
  mkdir -p "$OUT/forced"
  for SEG in mid_tunnel mid_bridge mid_slide mid_stump; do
    godot --headless --path . --script res://tools/balance/runs_summary.gd -- dir="$OUT" tier=4 fixture=1 part=allstacks 2> /dev/null       | grep '^mode=' | grep ",$SEG," | grep ' first=1 ' | head -1       | sed "s# count=50# count=6#; s# stop=6##; s#OUTDIR#$OUT/forced#; s#^#SCRIPT=runs.gd #" >> "$LIST"
  done
elif [ "$PHASE" = "PK" ]; then
  mkdir -p "$OUT/perf"
  for LEVEL in r5_fx1 r6_fx1 r7_fx1 r8_fx1 r8_fx2; do
    echo "SCRIPT=perf_peak.gd fixture=1 level=$LEVEL seeds=40 out=$OUT/perf/perf_$LEVEL.json save=$OUT/perf/save_$LEVEL" >> "$LIST"
  done
  for T in 1 2 3 4; do
    BOSS=$(echo "burrowbelly old_hayrick snowsnore glimmertoad" | cut -d' ' -f$T)
    echo "SCRIPT=perf_peak.gd fixture=1 tier=$T run=fx_$BOSS wave=16 card=crowded_night seeds=4 out=$OUT/perf/perf_run_tier${T}_fx_$BOSS.json save=$OUT/perf/save_run_tier$T" >> "$LIST"
  done
else
  echo "unknown phase $PHASE"
  exit 1
fi
if [ -n "$DRY" ]; then
  echo "wrote $(wc -l < "$LIST") jobs to $LIST"
  exit 0
fi
run_one() {
  LINE="$1"
  SCRIPT_NAME=$(echo "$LINE" | sed 's/^SCRIPT=\([^ ]*\) .*/\1/')
  ARGS=$(echo "$LINE" | sed 's/^SCRIPT=[^ ]* //')
  OUTFILE=$(echo "$ARGS" | sed 's/ save=.*//; s/.*out=//')
  if [ -f "$OUTFILE" ]; then return; fi
  timeout 14400 godot --headless --path . --script "res://tools/balance/$SCRIPT_NAME" -- $ARGS > /dev/null 2>> "$2/errors.txt"
}
export -f run_one
cat "$LIST" | xargs -P "$JOBS" -I{} bash -c 'run_one "{}" '"$OUT"
echo "done: $(find "$OUT" -name '*.json' | wc -l) files in $OUT"

#!/bin/bash
# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
#
# The jobs of task E5.2 (docs/balance/region5-2026-10-28.md) that the pass scripts do not write. Run it from the repo root of a clean copy
# of the commit measured, after `godot --headless --path . --import`:
#     OUT=docs/balance/raw/2026-10-28-e52 bash tools/balance/run_e52.sh BR 3      # forced lone Bramble Cottage searches on 5-2 to 5-6
#     OUT=... bash tools/balance/run_e52.sh PK 3                                  # the most crowded new wave as a saved game
# The campaign pass itself is `SEED_SHIFT=100000 bash tools/balance/run_pass.sh 2026-10-28-e52 6` and run_pass_post.sh, the run and
# daily passes are `TIER=1 OUT=.../runs_t1 bash tools/balance/run_b4.sh A 4` (and the same with no TIER for tier 0).
# Arguments: the phase and how many jobs run at once (default 3). DRY=1 only writes the list.
#
# BR. RULES 12.6 skips a lone Bramble Cottage search where flyers cost 6 lives or more (it cannot hit flyers), and `mode=need` says so on
# every region 5 level. The game designer asked to see it anyway, so it is forced here: two searches of 6000 builds (stopping dry at 2500)
# with the run_pass.sh seeds (SEED_SHIFT 100000, A = 5).
# PK. perf_peak.gd on every region 5 level and Twist, and on the run packs that hold a tier 1 creature or boss, at every risk card that
# makes their waves bigger (RULES 14.9). `save=` writes the build phase as a saved game.

PHASE="${1:-BR}"
JOBS="${2:-3}"
OUT="${OUT:-docs/balance/raw/2026-10-28-e52}"
SHIFT="${SEED_SHIFT:-100000}"
mkdir -p "$OUT"
LIST="$OUT/jobs_e52_$PHASE.txt"
: > "$LIST"
SCRIPT=run.gd
if [ "$PHASE" = "BR" ]; then
  for NUM in 2 3 4 5 6; do
    S=$((SHIFT + (50 + NUM) * 100))
    echo "SCRIPT=run.gd mode=search level=r5_l$NUM seed=$((730000 + S + 5)) evals=6000 stop_dry=2500 only=solo:bramble_cottage out=$OUT/r5_l${NUM}_forced_solo_bramble_cottage_a.json" >> "$LIST"
    echo "SCRIPT=run.gd mode=search level=r5_l$NUM seed=$((760000 + S + 5)) evals=6000 stop_dry=2500 only=solo:bramble_cottage out=$OUT/r5_l${NUM}_forced_solo_bramble_cottage_b.json" >> "$LIST"
  done
elif [ "$PHASE" = "PK" ]; then
  mkdir -p "$OUT/perf"
  for NUM in 1 2 3 4 5 6; do
    echo "SCRIPT=perf_peak.gd level=r5_l$NUM seeds=300 targets=3 out=$OUT/perf/perf_r5_l$NUM.json save=$OUT/perf/save_r5_l$NUM" >> "$LIST"
    echo "SCRIPT=perf_peak.gd level=r5_l$NUM twist=1 seeds=300 targets=3 out=$OUT/perf/perf_r5_l${NUM}_twist.json save=$OUT/perf/save_r5_l${NUM}_twist" >> "$LIST"
  done
  # Tier 1 run packs: the cases are set by hand from perf_cases.gd tier=1 and the pack file (see the report). A line per case in $OUT/jobs_e52_PK_extra.txt.
  if [ -f "$OUT/jobs_e52_PK_extra.txt" ]; then cat "$OUT/jobs_e52_PK_extra.txt" >> "$LIST"; fi
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

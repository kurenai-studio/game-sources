#!/bin/bash
# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
#
# The job list for the benchmark's largest wave (docs/ARCHITECTURE.md B5, docs/balance/runs-2026-10-27.md). Run it from the root
# of a clean copy of the commit measured (git archive, then godot --headless --path . --import):
#     OUT=C:/path/to/forkline/docs/balance/raw/2026-10-27-b5 bash tools/balance/run_perf.sh 6
# Arguments: how many jobs run at once (default 3). DRY=1 only writes the list.
# Jobs (perf_peak.gd, one process each): every campaign level and every Twist (60 random strategies each, the largest wave and the
# largest pair of waves tried), and the run pack waves with a risk card that perf_cases.gd lists as the biggest (10 seeds, 16 strategies
# each). Results: OUT/perf_*.json. The timings are best read from a quiet machine: run perf_peak.gd again on the top cases alone.

JOBS="${1:-3}"
OUT="${OUT:-docs/balance/raw/2026-10-27-b5}"
# A second, wider round: PREFIX=perf2 LEVEL_SEEDS=300 TARGETS=3 RUN_SEEDS=25 (more strategies, and the 3 biggest waves and pairs of each level).
PREFIX="${PREFIX:-perf}"
LEVEL_SEEDS="${LEVEL_SEEDS:-60}"
TARGETS="${TARGETS:-1}"
RUN_SEEDS="${RUN_SEEDS:-10}"
mkdir -p "$OUT"
LIST="$OUT/jobs_$PREFIX.txt"
: > "$LIST"
for LEVEL in $(grep -o '"r[0-9]*_l[0-9]*"' data/levels/campaign.json | tr -d '"'); do
  echo "level=$LEVEL seeds=$LEVEL_SEEDS targets=$TARGETS out=$OUT/${PREFIX}_$LEVEL.json" >> "$LIST"
  if grep -q '"twist"' "data/levels/$LEVEL.json"; then
    echo "level=$LEVEL twist=1 seeds=$LEVEL_SEEDS targets=$TARGETS out=$OUT/${PREFIX}_${LEVEL}_twist.json" >> "$LIST"
  fi
done
godot --headless --path . --script res://tools/balance/perf_cases.gd -- out="$OUT/perf_cases.json" jobs=8 2> /dev/null | grep '^JOB ' | sed "s/^JOB //; s#OUTDIR#$OUT#; s#seeds=10#seeds=$RUN_SEEDS#; s#/perf_run_#/${PREFIX}_run_#" >> "$LIST"
if [ -n "$DRY" ]; then
  echo "wrote $(wc -l < "$LIST") jobs to $LIST"
  exit 0
fi
run_one() {
  OUTFILE=$(echo "$1" | sed 's/.*out=//')
  if [ -f "$OUTFILE" ]; then return; fi
  timeout 7200 godot --headless --path . --script res://tools/balance/perf_peak.gd -- $1 > /dev/null 2>> "$2/errors.txt"
}
export -f run_one
cat "$LIST" | xargs -P "$JOBS" -I{} bash -c 'run_one "{}" '"$OUT"
echo "done: $(ls "$OUT" | wc -l) files in $OUT"

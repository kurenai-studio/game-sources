#!/bin/bash
# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
#
# Runs a job list (E6.2). Run it from the repo root of a clean copy, after `godot --headless --path . --import`:
#     bash tools/balance/run_list.sh LISTFILE 3
# Each line of the list is `SCRIPT=run.gd mode=... out=PATH` (the script defaults to run.gd when the line has no SCRIPT=; save= may follow out=).
# Arguments: the list file and how many jobs run at once (default 3). A job whose output file exists is skipped. A job is taken by making a
# lock folder beside its output file, so several copies of this script can work on one list and no job runs twice. If a copy is stopped,
# remove the `.lock_*` folders of the jobs it had running before starting again. Only the processes this script starts are used.
# Errors go to errors.txt in the folder of the first output. The run time limit is 4 hours a job.

LIST="$1"
JOBS="${2:-3}"
run_one() {
  LINE="$1"
  case "$LINE" in
    SCRIPT=*) SCRIPT_NAME=$(echo "$LINE" | sed 's/^SCRIPT=\([^ ]*\) .*/\1/'); ARGS=$(echo "$LINE" | sed 's/^SCRIPT=[^ ]* //') ;;
    *) SCRIPT_NAME=run.gd; ARGS="$LINE" ;;
  esac
  OUTFILE=$(echo "$ARGS" | sed 's/ save=.*//; s/.*out=//')
  DIR=$(dirname "$OUTFILE")
  mkdir -p "$DIR"
  if [ -f "$OUTFILE" ]; then return; fi
  if ! mkdir "$DIR/.lock_$(basename "$OUTFILE")" 2> /dev/null; then return; fi
  timeout 14400 godot --headless --path . --script "res://tools/balance/$SCRIPT_NAME" -- $ARGS > /dev/null 2>> "$DIR/errors.txt"
}
export -f run_one
grep -v '^#' "$LIST" | grep -v '^$' | xargs -P "$JOBS" -I{} bash -c 'run_one "{}"'
echo "list done: $LIST"

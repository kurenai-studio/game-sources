# Writing content through Bash

Two heredocs failed in this session, both with
`/usr/bin/bash: -c: line N: unexpected EOF while looking for matching '` — once for a ~130-line JSON
level file and once for a ~90-line Markdown section. The command aborted before running at all: the
first left the old `level-01.json` untouched, which is easy to mistake for a successful write if the
next step does not check.

`core-domain` has the same note for Java (`feedback_bash-heredoc-limits.md`), so it is not a
content-specific problem: long payloads, quotes and backticks through the Bash tool are unreliable.

What worked, every time:

- the `Write` tool for the file itself;
- for appending to an existing file, `Write` the new section into the session scratchpad and then
  `cat scratchpad/section.md >> target.md`;
- short `python - <<'PYEOF'` heredocs for structured edits (inserting a section before a known
  marker) — small enough to survive, and they fail loudly with an `assert` if the marker moved.

After any Bash write, check `wc -l` or `git diff --stat` before assuming it landed.

---
name: bash-heredoc-limits
description: Writing Java files through Bash heredocs in this repo mangles backslashes and truncates long commands
metadata:
  type: feedback
---

When writing source files with `cat > file <<'EOF'` in this environment, two things go wrong silently.

**Why:** the command text is processed before it reaches bash. Doubled backslashes collapse to one, so `"\."` in a regex or `'\'` as a char literal arrives broken and only fails at compile time. And a command longer than roughly 150 lines gets truncated mid-heredoc, which surfaces as `unexpected EOF while looking for matching quote` pointing at an unrelated line.

**How to apply:** write one file per command, keep each under about 120 lines, and split larger files into parts merged with a short python script. Avoid literal backslashes in Java: use `java.io.File.separatorChar` instead of `'\'`, and plain text searches instead of regex escapes. Python heredocs suffer the same collapsing, so build backslashes with `chr(92)` there.

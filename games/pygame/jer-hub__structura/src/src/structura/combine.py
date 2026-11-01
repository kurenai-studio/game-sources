"""Report combiner: turns a folder of students' Progress Reports into one CSV for the instructor.

    python -m structura.combine "Classroom downloads" class.csv

One row per student per Puzzle. A report whose signature doesn't verify is kept
and marked "no" in the Verified column; anything that isn't a Progress Report is
skipped with a message. When a student sent several reports, the newest is used.
"""
from __future__ import annotations

import argparse
import csv
import io
import json
import sys
from dataclasses import dataclass
from pathlib import Path

from .persistence.report import FORMAT, verify

# CSV header and the Progress Report field it comes from, per Puzzle row.
PUZZLE_COLUMNS = [("Zone", "zone"), ("Puzzle", "title"), ("Stage", "stage"), ("Stars", "stars"),
                  ("Moves", "moves"), ("Reference Moves", "reference_moves"), ("Glitches", "glitches"),
                  ("Hints", "hints"), ("Attempts", "attempts"), ("Completed", "completed_at")]
COLUMNS = ["Student", "Student ID", *(header for header, _ in PUZZLE_COLUMNS), "Verified"]


@dataclass
class _Report:
    path: Path
    name: str
    student_id: str
    generated_at: str
    verified: bool
    puzzles: list[list]


def _read(path: Path) -> _Report | str:
    """The report in `path`, or why it was skipped."""
    try:
        data = json.loads(path.read_text(encoding="utf-8-sig"))
    except (OSError, ValueError, RecursionError):
        return "not a Progress Report (not readable JSON)"
    if not isinstance(data, dict) or data.get("format") != FORMAT:
        return "not a Progress Report"
    try:
        student = data["student"]
        puzzles = [[row[key] for _, key in PUZZLE_COLUMNS] for row in data["results"]]
        return _Report(path, _text(student["name"]), _text(student["student_id"]),
                       _text(data.get("generated_at", "")), verify(data), puzzles)
    except (KeyError, TypeError):
        return "a damaged Progress Report (its contents are incomplete)"


def _text(value: object) -> str:
    """An edited report can hold text UTF-8 can't encode (a lone surrogate); it becomes "?"."""
    return str(value).encode("utf-8", "replace").decode("utf-8")


def _newest_per_student(paths: list[Path]) -> tuple[list[_Report], list[str]]:
    newest: dict[str, _Report] = {}
    messages = []
    for path in paths:
        got = _read(path)
        if isinstance(got, str):
            messages.append(f"Skipped {path.name}: {got}.")
            continue
        kept = newest.get(got.student_id)
        if kept is None:
            newest[got.student_id] = got
            continue
        older, newer = sorted((kept, got), key=lambda r: r.generated_at)
        newest[got.student_id] = newer
        messages.append(f"Skipped {older.path.name}: {older.name} sent a newer report ({newer.path.name}).")
    return sorted(newest.values(), key=lambda r: (r.name.casefold(), r.student_id)), messages


def _cell(value: object) -> object:
    """Students type their own names, so text that a spreadsheet would run as a formula is quoted."""
    if value is None:
        return ""
    if not isinstance(value, str):
        return value
    value = _text(value)
    return "'" + value if value[:1] in ("=", "+", "-", "@", "\t", "\r") else value


def combine(folder: Path, out: Path) -> list[str]:
    """Write the CSV for every report under `folder`. Returns a message per file skipped or flagged.

    Raises OSError if `out` can't be written; nothing is written in that case.
    """
    target = out.resolve()
    reports, messages = _newest_per_student(
        sorted(p for p in folder.rglob("*") if p.is_file() and p.resolve() != target))
    messages += [f"Flagged {r.path.name}: {r.name}'s report fails signature verification; it may have been edited."
                 for r in reports if not r.verified]
    text = io.StringIO()
    writer = csv.writer(text)
    writer.writerow(COLUMNS)
    for r in reports:
        for puzzle in r.puzzles:
            writer.writerow([_cell(v) for v in (r.name, r.student_id, *puzzle)] + ["yes" if r.verified else "no"])
    out.write_text(text.getvalue(), encoding="utf-8-sig", newline="")
    return messages


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="python -m structura.combine",
                                     description="Combine a folder of Structura Progress Reports into one CSV.")
    parser.add_argument("folder", type=Path, help="folder holding the downloaded Progress Reports")
    parser.add_argument("out", type=Path, help="CSV file to write, e.g. class.csv")
    args = parser.parse_args(argv)
    if not args.folder.is_dir():
        print(f"No folder at {args.folder}.", file=sys.stderr)
        return 2
    try:
        messages = combine(args.folder, args.out)
    except OSError as e:
        print(f"Couldn't write {args.out} ({e.strerror}). If it is open in Excel, close it and run this again.",
              file=sys.stderr)
        return 1
    for message in messages:
        print(message, file=sys.stderr)
    print(f"Wrote {args.out}.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

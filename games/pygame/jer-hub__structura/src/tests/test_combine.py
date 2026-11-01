"""The report combiner, run as the instructor runs it, on reports the game really exported."""
import csv
import json
from datetime import datetime, timezone

import pytest

from structura import combine
from structura.persistence import report
from structura.persistence.store import Store
from structura.puzzles.schema import Puzzle, Zone


def puzzle(pid, title, stage, initial):
    return Puzzle(id=pid, title=title, type="sort", stage=stage, structure="array",
                  brief="", goal={"kind": "sorted"}, initial=initial, ops=["swap"])


ZONES = [Zone(id="z", name="Test Zone", order=1, structure="array", color=(1, 2, 3), intro="",
              requires=[], map_pos=(0.5, 0.5), lesson=None,
              puzzles=[puzzle("z_p1", "Swap", "guided", [2, 1]),
                       puzzle("z_p2", "Sort Three", "challenge", [3, 2, 1])])]


@pytest.fixture
def store(tmp_path):
    s = Store(tmp_path / "game.db")
    yield s
    s.close()


@pytest.fixture
def inbox(tmp_path):
    folder = tmp_path / "Classroom downloads"
    folder.mkdir()
    return folder


def export(store, folder, name, sid, *records):
    """Export a real Progress Report, as the game does."""
    profile = next((p for p in store.profiles() if p.student_id == sid), None) \
        or store.create_profile(name, sid)
    for pid, stars, moves, glitches, hints in records:
        store.record(profile.id, pid, stars=stars, moves=moves, glitches=glitches, hints=hints)
    return report.export(profile, store.results(profile.id), ZONES, folder=folder)


def set_clock(monkeypatch, when):
    """Make the game believe it is `when` while exporting."""
    class At(datetime):
        @classmethod
        def now(cls, tz=None):
            return when if tz else when.replace(tzinfo=None)
    monkeypatch.setattr(report, "datetime", At)


def run(folder, out, capsys):
    code = combine.main([str(folder), str(out)])
    err = capsys.readouterr().err
    with open(out, newline="", encoding="utf-8-sig") as f:
        return code, list(csv.DictReader(f)), err


def test_every_student_gets_a_row_per_puzzle(store, inbox, tmp_path, capsys):
    export(store, inbox, "Ana Peña", "2024-0001", ("z_p1", 3, 1, 0, 0), ("z_p2", 2, 4, 1, 1))
    export(store, inbox, "Ben Cruz", "2024-0002", ("z_p1", 1, 5, 3, 2))
    code, rows, _ = run(inbox, tmp_path / "class.csv", capsys)
    assert code == 0
    assert rows == [
        {"Student": "Ana Peña", "Student ID": "2024-0001", "Zone": "Test Zone", "Puzzle": "Swap",
         "Stage": "guided", "Stars": "3", "Moves": "1", "Reference Moves": "1", "Glitches": "0",
         "Hints": "0", "Attempts": "1", "Completed": rows[0]["Completed"], "Verified": "yes"},
        {"Student": "Ana Peña", "Student ID": "2024-0001", "Zone": "Test Zone", "Puzzle": "Sort Three",
         "Stage": "challenge", "Stars": "2", "Moves": "4", "Reference Moves": "1", "Glitches": "1",
         "Hints": "1", "Attempts": "1", "Completed": rows[1]["Completed"], "Verified": "yes"},
        {"Student": "Ben Cruz", "Student ID": "2024-0002", "Zone": "Test Zone", "Puzzle": "Swap",
         "Stage": "guided", "Stars": "1", "Moves": "5", "Reference Moves": "1", "Glitches": "3",
         "Hints": "2", "Attempts": "1", "Completed": rows[2]["Completed"], "Verified": "yes"},
        {"Student": "Ben Cruz", "Student ID": "2024-0002", "Zone": "Test Zone", "Puzzle": "Sort Three",
         "Stage": "challenge", "Stars": "0", "Moves": "", "Reference Moves": "1", "Glitches": "",
         "Hints": "", "Attempts": "0", "Completed": "", "Verified": "yes"},
    ]
    assert all(datetime.fromisoformat(r["Completed"]) for r in rows[:3])


def test_an_edited_report_is_kept_but_flagged(store, inbox, tmp_path, capsys):
    path = export(store, inbox, "Ana Peña", "2024-0001", ("z_p1", 1, 6, 4, 2))
    data = json.loads(path.read_text(encoding="utf-8"))
    data["results"][0]["stars"] = 3
    path.write_text(json.dumps(data), encoding="utf-8")
    export(store, inbox, "Ben Cruz", "2024-0002", ("z_p1", 2, 2, 0, 1))
    _, rows, err = run(inbox, tmp_path / "class.csv", capsys)
    ana = [r for r in rows if r["Student ID"] == "2024-0001"]
    assert [r["Verified"] for r in ana] == ["no", "no"]
    assert ana[0]["Stars"] == "3", "the edited value is shown, so the instructor can see what changed"
    assert {r["Verified"] for r in rows if r["Student ID"] == "2024-0002"} == {"yes"}
    assert path.name in err and "verif" in err


def test_files_that_are_not_progress_reports_are_skipped_with_a_message(store, inbox, tmp_path, capsys):
    export(store, inbox, "Ana Peña", "2024-0001", ("z_p1", 3, 1, 0, 0))
    (inbox / "settings.json").write_text('{"theme": "dark"}', encoding="utf-8")
    (inbox / "notes.txt").write_text("not json at all", encoding="utf-8")
    (inbox / "list.json").write_text("[1, 2, 3]", encoding="utf-8")
    (inbox / "deep.json").write_text("[" * 100_000, encoding="utf-8")
    broken = json.loads(export(store, tmp_path, "Cy Lim", "2024-0003").read_text(encoding="utf-8"))
    broken["results"] = "lots"
    (inbox / "broken.json").write_text(json.dumps(broken), encoding="utf-8")
    code, rows, err = run(inbox, tmp_path / "class.csv", capsys)
    assert code == 0
    assert {r["Student ID"] for r in rows} == {"2024-0001"}
    for name in ("settings.json", "notes.txt", "list.json", "deep.json", "broken.json"):
        assert name in err


def test_an_edited_name_that_is_not_valid_text_is_still_written(store, inbox, tmp_path, capsys):
    path = export(store, inbox, "Ana Peña", "2024-0001", ("z_p1", 3, 1, 0, 0))
    edited = path.read_text(encoding="utf-8").replace("Ana Pe\\u00f1a", "Ana \\ud800")
    path.write_text(edited.replace('"Swap"', '"Sw\\udfffap"'), encoding="utf-8")
    export(store, inbox, "Ben Cruz", "2024-0002", ("z_p1", 2, 2, 0, 1))
    code, rows, _ = run(inbox, tmp_path / "class.csv", capsys)
    assert code == 0
    assert [(r["Student ID"], r["Verified"]) for r in rows[::2]] == [("2024-0001", "no"), ("2024-0002", "yes")]


def test_a_csv_that_cannot_be_written_is_explained_not_a_crash(store, inbox, tmp_path, capsys):
    export(store, inbox, "Ana Peña", "2024-0001", ("z_p1", 3, 1, 0, 0))
    locked = tmp_path / "class.csv"
    locked.mkdir()  # Windows refuses the write, as it does when Excel has the file open.
    code = combine.main([str(inbox), str(locked)])
    assert code != 0
    assert "class.csv" in capsys.readouterr().err


def test_the_csv_opens_in_excel_with_accented_names_intact(store, inbox, tmp_path, capsys):
    export(store, inbox, "Ana Peña", "2024-0001", ("z_p1", 3, 1, 0, 0))
    run(inbox, tmp_path / "class.csv", capsys)
    assert (tmp_path / "class.csv").read_bytes().startswith(b"\xef\xbb\xbf"), "Excel needs the BOM to read UTF-8"


def test_reports_in_subfolders_are_found(store, inbox, tmp_path, capsys):
    (inbox / "Ana Peña").mkdir()
    export(store, inbox / "Ana Peña", "Ana Peña", "2024-0001", ("z_p1", 3, 1, 0, 0))
    _, rows, _ = run(inbox, tmp_path / "class.csv", capsys)
    assert {r["Student ID"] for r in rows} == {"2024-0001"}


def test_the_newest_report_per_student_is_used(store, inbox, tmp_path, capsys, monkeypatch):
    staging = tmp_path / "staging"
    staging.mkdir()
    set_clock(monkeypatch, datetime(2026, 10, 2, 8, 0, tzinfo=timezone.utc))
    first = export(store, staging, "Ana Peña", "2024-0001")
    set_clock(monkeypatch, datetime(2026, 10, 9, 8, 0, tzinfo=timezone.utc))
    export(store, inbox, "Ana Peña", "2024-0001", ("z_p1", 3, 1, 0, 0))
    # Copied in last and named to sort first: only generated_at says this is the older report.
    (inbox / "first try.json").write_text(first.read_text(encoding="utf-8"), encoding="utf-8")
    _, rows, err = run(inbox, tmp_path / "class.csv", capsys)
    assert [r["Stars"] for r in rows] == ["3", "0"]
    assert "first try.json" in err


def test_a_name_that_looks_like_a_formula_stays_text_in_a_spreadsheet(store, inbox, tmp_path, capsys):
    export(store, inbox, '=HYPERLINK("http://x","Ana")', "2024-0001", ("z_p1", 3, 1, 0, 0))
    _, rows, _ = run(inbox, tmp_path / "class.csv", capsys)
    assert rows[0]["Student"] == '\'=HYPERLINK("http://x","Ana")'
    assert rows[0]["Student ID"] == "2024-0001" and rows[0]["Stars"] == "3"


def test_a_missing_folder_is_an_error_not_a_crash(tmp_path, capsys):
    code = combine.main([str(tmp_path / "nowhere"), str(tmp_path / "class.csv")])
    assert code != 0
    assert "nowhere" in capsys.readouterr().err
    assert not (tmp_path / "class.csv").exists()

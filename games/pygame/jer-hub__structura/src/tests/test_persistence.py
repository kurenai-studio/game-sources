import errno
import json
import sqlite3
from pathlib import Path

import pytest

from structura.persistence import report
from structura.persistence.store import Store
from structura.puzzles.schema import Puzzle, Zone


def zone():
    p = Puzzle(id="z_p1", title="Swap", type="sort", stage="guided", structure="array",
               brief="", goal={"kind": "sorted"}, initial=[2, 1], ops=["swap"])
    return Zone(id="z", name="Test Zone", order=1, structure="array", color=(1, 2, 3), intro="",
                requires=[], map_pos=(0.5, 0.5), lesson=None, puzzles=[p])


def test_store_keeps_best_attempt(tmp_path):
    s = Store(tmp_path / "t.db")
    p = s.create_profile("Ana", "2024-001")
    s.record(p.id, "z_p1", stars=2, moves=3, glitches=1, hints=0)
    s.record(p.id, "z_p1", stars=1, moves=9, glitches=4, hints=2)
    r = s.record(p.id, "z_p1", stars=3, moves=1, glitches=0, hints=0)
    assert (r.stars, r.moves, r.attempts) == (3, 1, 3)


def test_a_clean_run_after_a_better_messy_one_is_remembered(tmp_path):
    s = Store(tmp_path / "t.db")
    p = s.create_profile("Ana", "2024-001")
    s.record(p.id, "z_p1", stars=2, moves=4, glitches=1, hints=0)
    r = s.record(p.id, "z_p1", stars=1, moves=7, glitches=0, hints=0)
    assert r.ever_clean
    assert (r.stars, r.moves, r.glitches, r.hints) == (2, 4, 1, 0), "the best attempt is unchanged"


def test_a_messy_run_after_a_clean_one_does_not_forget_it(tmp_path):
    s = Store(tmp_path / "t.db")
    p = s.create_profile("Ana", "2024-001")
    assert s.record(p.id, "z_p1", stars=1, moves=7, glitches=0, hints=0).ever_clean
    r = s.record(p.id, "z_p1", stars=2, moves=4, glitches=1, hints=0)
    assert r.ever_clean and r.stars == 2


def test_a_run_with_a_hint_is_not_clean(tmp_path):
    s = Store(tmp_path / "t.db")
    p = s.create_profile("Ana", "2024-001")
    assert not s.record(p.id, "z_p1", stars=3, moves=4, glitches=0, hints=1).ever_clean


OLD_SCHEMA = """
CREATE TABLE profile (
    id INTEGER PRIMARY KEY, name TEXT NOT NULL, student_id TEXT NOT NULL,
    language TEXT NOT NULL DEFAULT 'python', speed REAL NOT NULL DEFAULT 1.0, created_at TEXT NOT NULL);
CREATE TABLE result (
    profile_id INTEGER NOT NULL REFERENCES profile(id) ON DELETE CASCADE, puzzle_id TEXT NOT NULL,
    stars INTEGER NOT NULL, moves INTEGER NOT NULL, glitches INTEGER NOT NULL, hints INTEGER NOT NULL,
    attempts INTEGER NOT NULL DEFAULT 1, completed_at TEXT NOT NULL, PRIMARY KEY (profile_id, puzzle_id));
INSERT INTO profile VALUES (1, 'Ana', '2024-001', 'java', 1.0, '2026-09-01T00:00:00+00:00');
INSERT INTO result VALUES (1, 'clean', 3, 4, 0, 0, 2, '2026-09-01T00:00:00+00:00');
INSERT INTO result VALUES (1, 'glitched', 2, 4, 1, 0, 1, '2026-09-01T00:00:00+00:00');
INSERT INTO result VALUES (1, 'hinted', 2, 4, 0, 1, 1, '2026-09-01T00:00:00+00:00');
"""


def old_database(tmp_path, extra="") -> Path:
    path = tmp_path / "old.db"
    old = sqlite3.connect(path)
    old.executescript(OLD_SCHEMA + extra)
    old.close()
    return path


def clean_flags(path) -> dict[str, bool]:
    s = Store(path)
    flags = {pid: r.ever_clean for pid, r in s.results(1).items()}
    s.close()
    return flags


def test_a_database_from_before_clean_runs_were_remembered_still_opens(tmp_path):
    path = old_database(tmp_path)
    s = Store(path)
    results = s.results(1)
    assert {pid: r.ever_clean for pid, r in results.items()} == {"clean": True, "glitched": False, "hinted": False}
    assert (results["clean"].stars, results["clean"].attempts) == (3, 2)
    assert s.record(1, "glitched", stars=1, moves=9, glitches=0, hints=0).ever_clean
    s.close()
    assert clean_flags(path)["glitched"], "opening it again doesn't migrate twice"


def test_an_upgrade_that_fails_partway_is_redone_next_time(tmp_path):
    fails = "CREATE TRIGGER fail BEFORE UPDATE ON result BEGIN SELECT RAISE(ABORT, 'disk I/O error'); END;"
    path = old_database(tmp_path, fails)
    with pytest.raises(sqlite3.DatabaseError):
        Store(path)
    db = sqlite3.connect(path)
    db.execute("DROP TRIGGER fail")
    db.commit()
    db.close()
    assert clean_flags(path) == {"clean": True, "glitched": False, "hinted": False}


def test_report_signature_detects_edits(tmp_path):
    s = Store(tmp_path / "t.db")
    p = s.create_profile("Ana", "2024-001")
    s.record(p.id, "z_p1", stars=2, moves=2, glitches=0, hints=1)
    path = report.export(p, s.results(p.id), [zone()], folder=tmp_path)
    data = json.loads(path.read_text())
    assert report.verify(data)
    assert data["results"][0]["reference_moves"] == 1
    data["results"][0]["stars"] = 3
    assert not report.verify(data)


def exported_report(tmp_path) -> dict:
    s = Store(tmp_path / "t.db")
    p = s.create_profile("Ana", "2024-001")
    return json.loads(report.export(p, s.results(p.id), [zone()], folder=tmp_path).read_text())


def test_a_report_that_fails_partway_through_saving_leaves_nothing_behind(tmp_path, monkeypatch):
    s = Store(tmp_path / "t.db")
    p = s.create_profile("Ana", "2024-001")
    folder = tmp_path / "reports"
    real_write = Path.write_text

    def disk_fills_up(path, text, **kwargs):
        real_write(path, text[: len(text) // 2], **kwargs)
        raise OSError(errno.ENOSPC, "No space left on device")

    monkeypatch.setattr(Path, "write_text", disk_fills_up)
    with pytest.raises(OSError):
        report.export(p, s.results(p.id), [zone()], folder)
    assert list(folder.iterdir()) == []


def test_a_report_without_a_text_signature_is_not_verified(tmp_path):
    data = exported_report(tmp_path)
    for signature in (12345, ["abc"], None, "ñandú", json.loads('"\\ud800"')):
        assert not report.verify({**data, "signature": signature}), signature
    del data["signature"]
    assert not report.verify(data)


def test_something_that_is_not_a_report_is_not_verified(tmp_path):
    data = exported_report(tmp_path)
    for other in ([data], "a report", 7, None, {"name": "Ana"}, {**data, "format": "something-else/1"}):
        assert not report.verify(other), other

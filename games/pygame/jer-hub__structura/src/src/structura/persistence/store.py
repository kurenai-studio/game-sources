"""Local SQLite storage for Profiles and Puzzle results."""
from __future__ import annotations

import os
import sqlite3
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path


def data_dir() -> Path:
    base = os.environ.get("STRUCTURA_HOME") or os.environ.get("APPDATA") or Path.home()
    path = Path(base) / "Structura"
    path.mkdir(parents=True, exist_ok=True)
    return path


@dataclass
class Profile:
    id: int
    name: str
    student_id: str
    language: str = "python"
    speed: float = 1.0


@dataclass
class Result:
    puzzle_id: str
    stars: int
    moves: int
    glitches: int
    hints: int
    attempts: int
    completed_at: str
    ever_clean: bool             # any attempt, not only the best, finished with no Glitches and no Hints


SCHEMA = """
CREATE TABLE IF NOT EXISTS profile (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    student_id TEXT NOT NULL,
    language TEXT NOT NULL DEFAULT 'python',
    speed REAL NOT NULL DEFAULT 1.0,
    created_at TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS result (
    profile_id INTEGER NOT NULL REFERENCES profile(id) ON DELETE CASCADE,
    puzzle_id TEXT NOT NULL,
    stars INTEGER NOT NULL,
    moves INTEGER NOT NULL,
    glitches INTEGER NOT NULL,
    hints INTEGER NOT NULL,
    attempts INTEGER NOT NULL DEFAULT 1,
    completed_at TEXT NOT NULL,
    ever_clean INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (profile_id, puzzle_id)
);
"""


def _has_ever_clean(db: sqlite3.Connection) -> bool:
    return "ever_clean" in {row[1] for row in db.execute("PRAGMA table_info(result)")}


def _migrate(db: sqlite3.Connection) -> None:
    """Bring a database from an earlier version up to SCHEMA. CREATE TABLE IF NOT
    EXISTS leaves an existing table as it was, so new columns are added here.
    sqlite3 commits ALTER TABLE by itself, so the column and its back-fill share
    one explicit transaction: a crash between them must not leave the column unfilled."""
    if _has_ever_clean(db):
        return
    db.execute("BEGIN IMMEDIATE")
    try:
        if not _has_ever_clean(db):               # another window may have upgraded it first
            db.execute("ALTER TABLE result ADD COLUMN ever_clean INTEGER NOT NULL DEFAULT 0")
            db.execute("UPDATE result SET ever_clean = (glitches = 0 AND hints = 0)")
        db.execute("COMMIT")
    except BaseException:
        db.execute("ROLLBACK")
        raise


def _now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


class Store:
    def __init__(self, path: Path | str | None = None):
        self.path = Path(path) if path else data_dir() / "structura.db"
        self.db = sqlite3.connect(self.path)
        try:
            self.db.execute("PRAGMA foreign_keys = ON")
            self.db.executescript(SCHEMA)
            _migrate(self.db)
        except BaseException:
            self.db.close()
            raise

    def close(self) -> None:
        self.db.close()

    # ---- profiles ------------------------------------------------------
    def profiles(self) -> list[Profile]:
        rows = self.db.execute("SELECT id, name, student_id, language, speed FROM profile ORDER BY name")
        return [Profile(*r) for r in rows]

    def create_profile(self, name: str, student_id: str, language: str = "python") -> Profile:
        name, student_id = name.strip(), student_id.strip()
        if not name or not student_id:
            raise ValueError("Name and student ID are both required.")
        cur = self.db.execute(
            "INSERT INTO profile (name, student_id, language, created_at) VALUES (?, ?, ?, ?)",
            (name, student_id, language, _now()))
        self.db.commit()
        return Profile(cur.lastrowid, name, student_id, language)

    def update_profile(self, p: Profile) -> None:
        self.db.execute("UPDATE profile SET language = ?, speed = ? WHERE id = ?", (p.language, p.speed, p.id))
        self.db.commit()

    def delete_profile(self, profile_id: int) -> None:
        self.db.execute("DELETE FROM profile WHERE id = ?", (profile_id,))
        self.db.commit()

    # ---- results -------------------------------------------------------
    def results(self, profile_id: int) -> dict[str, Result]:
        rows = self.db.execute(
            "SELECT puzzle_id, stars, moves, glitches, hints, attempts, completed_at, ever_clean "
            "FROM result WHERE profile_id = ?",
            (profile_id,))
        return {r[0]: Result(*r[:-1], ever_clean=bool(r[-1])) for r in rows}

    def record(self, profile_id: int, puzzle_id: str, stars: int, moves: int, glitches: int, hints: int) -> Result:
        """Keep the best attempt (most stars, then fewest Moves); always count the attempt,
        and remember if any attempt was clean."""
        old = self.results(profile_id).get(puzzle_id)
        ever_clean = (glitches == 0 and hints == 0) or (old is not None and old.ever_clean)
        if old is None:
            self.db.execute(
                "INSERT INTO result VALUES (?, ?, ?, ?, ?, ?, 1, ?, ?)",
                (profile_id, puzzle_id, stars, moves, glitches, hints, _now(), ever_clean))
        elif (stars, -moves) > (old.stars, -old.moves):
            self.db.execute(
                "UPDATE result SET stars=?, moves=?, glitches=?, hints=?, attempts=attempts+1, completed_at=?, "
                "ever_clean=? WHERE profile_id=? AND puzzle_id=?",
                (stars, moves, glitches, hints, _now(), ever_clean, profile_id, puzzle_id))
        else:
            self.db.execute("UPDATE result SET attempts=attempts+1, ever_clean=? WHERE profile_id=? AND puzzle_id=?",
                            (ever_clean, profile_id, puzzle_id))
        self.db.commit()
        return self.results(profile_id)[puzzle_id]

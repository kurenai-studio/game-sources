"""Safe local persistence for the ranking."""

from __future__ import annotations

from dataclasses import asdict, dataclass
import json
from pathlib import Path

from game.config import DATA_DIR, RANKING_LIMIT, RANKING_PATH


@dataclass(frozen=True, slots=True)
class ScoreEntry:
    """One ranking entry."""

    name: str
    score: int
    time_seconds: float


def normalize_name(value: str) -> str:
    """Return a short display name without control characters."""

    cleaned = "".join(
        character
        for character in value.strip().upper()
        if character.isalnum() or character in " _-"
    )
    cleaned = " ".join(cleaned.split())
    return cleaned[:12] or "PILOTO"


class RankingStore:
    """Read and update a small JSON ranking using atomic replacement."""

    def __init__(self, path: Path = RANKING_PATH, limit: int = RANKING_LIMIT):
        self.path = Path(path)
        self.limit = max(1, limit)

    def load(self) -> list[ScoreEntry]:
        if not self.path.exists():
            return []

        try:
            raw = json.loads(self.path.read_text(encoding="utf-8"))
            if not isinstance(raw, list):
                return []
            entries = [self._parse_entry(item) for item in raw]
        except (OSError, UnicodeError, json.JSONDecodeError, TypeError, ValueError):
            return []

        valid_entries = [entry for entry in entries if entry is not None]
        return self._ordered(valid_entries)[: self.limit]

    def save(self, name: str, score: int, time_seconds: float) -> list[ScoreEntry]:
        entry = ScoreEntry(
            name=normalize_name(name),
            score=max(0, int(score)),
            time_seconds=max(0.0, round(float(time_seconds), 2)),
        )
        entries = self._ordered([*self.load(), entry])[: self.limit]

        self.path.parent.mkdir(parents=True, exist_ok=True)
        temporary_path = self.path.with_suffix(self.path.suffix + ".tmp")
        payload = [asdict(item) for item in entries]
        temporary_path.write_text(
            json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        temporary_path.replace(self.path)
        return entries

    @staticmethod
    def _parse_entry(value: object) -> ScoreEntry | None:
        if not isinstance(value, dict):
            return None
        try:
            name = normalize_name(str(value["name"]))
            score = max(0, int(value["score"]))
            time_seconds = max(0.0, float(value["time_seconds"]))
        except (KeyError, TypeError, ValueError):
            return None
        return ScoreEntry(name=name, score=score, time_seconds=time_seconds)

    @staticmethod
    def _ordered(entries: list[ScoreEntry]) -> list[ScoreEntry]:
        return sorted(entries, key=lambda item: (-item.score, item.time_seconds, item.name))


class SaveSystem:
    """Persist ranking and resumable progress in separate JSON files."""

    def __init__(self, directory: Path = DATA_DIR):
        self.directory = Path(directory)
        self.ranking = RankingStore(self.directory / RANKING_PATH.name)
        self.progress_path = self.directory / "progress.json"

    def load_progress(self) -> dict[str, int] | None:
        try:
            raw = json.loads(self.progress_path.read_text(encoding="utf-8"))
            if not isinstance(raw, dict):
                return None
            return {
                "score": max(0, int(raw["score"])),
                "lives": min(3, max(0, int(raw["lives"]))),
                "elapsed_seconds": max(0, int(raw["elapsed_seconds"])),
            }
        except (
            OSError,
            UnicodeError,
            json.JSONDecodeError,
            KeyError,
            TypeError,
            ValueError,
        ):
            return None

    def save_progress(self, score: int, lives: int, elapsed_seconds: int) -> None:
        payload = {
            "score": max(0, int(score)),
            "lives": min(3, max(0, int(lives))),
            "elapsed_seconds": max(0, int(elapsed_seconds)),
        }
        self.directory.mkdir(parents=True, exist_ok=True)
        temporary_path = self.progress_path.with_suffix(".json.tmp")
        temporary_path.write_text(
            json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        temporary_path.replace(self.progress_path)

    def clear_progress(self) -> None:
        try:
            self.progress_path.unlink()
        except FileNotFoundError:
            pass

    def has_progress(self) -> bool:
        return self.load_progress() is not None

    def load_ranking(self) -> list[ScoreEntry]:
        return self.ranking.load()

    def save_score(self, name: str, score: int, time_seconds: float) -> list[ScoreEntry]:
        return self.ranking.save(name, score, time_seconds)

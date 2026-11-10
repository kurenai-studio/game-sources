"""
Lane Legends: Human vs AI
scoreboard.py - Score tracking, race metrics, persistent high scores, and leaderboard.
"""

import json
import time
from pathlib import Path
from typing import Dict, List, Any, Optional

from settings import HIGH_SCORES_FILE


class Scoreboard:
    """
    Manages in-game scores, metrics, and local persistent high-score leaderboard.
    """

    def __init__(self, filepath: Optional[Path] = None):
        self.filepath = filepath or HIGH_SCORES_FILE
        self.data: Dict[str, Any] = {
            "leaderboard": [],
            "mode_records": {
                "vs_ai": {"score": 0, "player": "Player 1", "time": 0.0},
                "pvp": {"score": 0, "player": "Player 1", "time": 0.0},
            },
            "difficulty_records": {
                "EASY": {"score": 0, "player": "Player 1", "time": 0.0},
                "MEDIUM": {"score": 0, "player": "Player 1", "time": 0.0},
                "HARD": {"score": 0, "player": "Player 1", "time": 0.0},
            },
            "tallies": {
                "human_vs_ai": {"human_wins": 0, "ai_wins": 0, "draws": 0},
                "pvp": {"p1_wins": 0, "p2_wins": 0, "draws": 0},
            },
        }
        self.load()

    def load(self) -> bool:
        """Load persistent records from JSON. Falls back to default if missing or invalid."""
        if not self.filepath.exists():
            self.save()
            return True
        try:
            with open(self.filepath, "r", encoding="utf-8") as f:
                loaded = json.load(f)
                if isinstance(loaded, dict):
                    # Merge keys to ensure schema consistency
                    for key in ["leaderboard", "mode_records", "difficulty_records", "tallies"]:
                        if key in loaded:
                            self.data[key] = loaded[key]
            return True
        except Exception as e:
            print(f"[Scoreboard] Warning loading high scores ({e}), reinitializing default records.")
            self.save()
            return False

    def save(self) -> bool:
        """Persist records to JSON file."""
        self.filepath.parent.mkdir(parents=True, exist_ok=True)
        try:
            with open(self.filepath, "w", encoding="utf-8") as f:
                json.dump(self.data, f, indent=2)
            return True
        except Exception as e:
            print(f"[Scoreboard] Error saving high scores: {e}")
            return False

    def record_race_result(
        self,
        mode: str,  # "vs_ai" or "pvp"
        p1_stats: Dict[str, Any],
        p2_stats: Dict[str, Any],
        winner_name: str,
        difficulty: Optional[str] = None,
    ) -> None:
        """
        Record race outcome, update win/loss tallies, check records, and update top-10 leaderboard.
        """
        # 1. Update tallies
        if mode == "vs_ai":
            tally = self.data["tallies"]["human_vs_ai"]
            if "Player 1" in winner_name:
                tally["human_wins"] += 1
            elif "AI" in winner_name or "Panda" in winner_name or "Nawab" in winner_name or "Cheetah" in winner_name:
                tally["ai_wins"] += 1
            else:
                tally["draws"] += 1
        else:
            tally = self.data["tallies"]["pvp"]
            if "Player 1" in winner_name:
                tally["p1_wins"] += 1
            elif "Player 2" in winner_name:
                tally["p2_wins"] += 1
            else:
                tally["draws"] += 1

        # 2. Add candidates to leaderboard (Human players only)
        candidates = []
        if not p1_stats.get("is_ai", False):
            candidates.append({
                "player": p1_stats.get("name", "Player 1"),
                "score": int(p1_stats.get("score", 0)),
                "time": round(float(p1_stats.get("finish_time", 0.0)), 2),
                "mode": "Player vs AI" if mode == "vs_ai" else "2 Players",
                "difficulty": difficulty or "-",
                "date": time.strftime("%Y-%m-%d %H:%M"),
            })
        if not p2_stats.get("is_ai", False):
            candidates.append({
                "player": p2_stats.get("name", "Player 2"),
                "score": int(p2_stats.get("score", 0)),
                "time": round(float(p2_stats.get("finish_time", 0.0)), 2),
                "mode": "2 Players",
                "difficulty": "-",
                "date": time.strftime("%Y-%m-%d %H:%M"),
            })

        for entry in candidates:
            # Check mode record
            rec_key = "vs_ai" if mode == "vs_ai" else "pvp"
            current_mode_rec = self.data["mode_records"].get(rec_key, {"score": 0})
            if entry["score"] > current_mode_rec.get("score", 0):
                self.data["mode_records"][rec_key] = entry

            # Check difficulty record
            if difficulty and difficulty in self.data["difficulty_records"]:
                diff_rec = self.data["difficulty_records"][difficulty]
                if entry["score"] > diff_rec.get("score", 0):
                    self.data["difficulty_records"][difficulty] = entry

            # Add to leaderboard list
            self.data["leaderboard"].append(entry)

        # Sort leaderboard descending by score, tie-breaking by lowest time
        self.data["leaderboard"].sort(
            key=lambda item: (-item["score"], item["time"] if item["time"] > 0 else 9999.0)
        )
        # Retain top 10
        self.data["leaderboard"] = self.data["leaderboard"][:10]

        # Save to disk
        self.save()

    def get_leaderboard(self) -> List[Dict[str, Any]]:
        """Return the top 10 leaderboard entries."""
        return self.data.get("leaderboard", [])

    def get_tallies(self) -> Dict[str, Any]:
        """Return win/loss statistics."""
        return self.data.get("tallies", {})

    def get_records(self) -> Dict[str, Any]:
        """Return mode and difficulty records."""
        return {
            "mode": self.data.get("mode_records", {}),
            "difficulty": self.data.get("difficulty_records", {}),
        }

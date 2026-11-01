"""Level library: scanning, validation, creation and saving.

Folder layout::

    music_levels/
        <level_name>.json            # chart
        music_<level_name>.mp3|.wav  # copied audio

Level JSON schema::

    {
      "name":  "Neon Skyline",
      "audio": "music_Neon_Skyline.mp3",
      "end":   93450.0,
      "notes": [
        {"lane": 0, "time": 1200.0, "end": null, "boost": false}
      ]
    }

``time``/``end`` are milliseconds from the start of the song; ``end`` is
present only for sustain notes. The top-level ``end`` is the song length,
captured when the creator stopped recording (null = play the whole file).
"""

from __future__ import annotations

import json
import os
import re
import shutil
from dataclasses import dataclass, field

AUDIO_EXTS = (".mp3", ".wav")
MAX_NAME = 48
_ILLEGAL = re.compile(r'[<>:"/\\|?*\x00-\x1f]')


@dataclass
class LevelInfo:
    name: str
    json_path: str
    audio_path: str | None
    notes: list = field(default_factory=list)
    end: float | None = None      # song length in ms (None = whole track)
    valid: bool = False
    error: str = ""

    @property
    def audio_file(self) -> str | None:
        return os.path.basename(self.audio_path) if self.audio_path else None


class LevelLibrary:
    def __init__(self, root: str = "music_levels"):
        self.root = root
        os.makedirs(self.root, exist_ok=True)

    # ------------------------------------------------------------- helpers
    def json_path(self, name: str) -> str:
        return os.path.join(self.root, f"{name}.json")

    @staticmethod
    def sanitize(raw: str) -> str:
        name = _ILLEGAL.sub("_", (raw or "").strip())
        name = re.sub(r"\s+", " ", name).strip(" .")
        return name[:MAX_NAME] or "level"

    # -------------------------------------------------------------- scan
    def scan(self) -> list:
        levels = []
        try:
            entries = sorted(os.listdir(self.root))
        except OSError:
            return levels
        for fn in entries:
            if not fn.endswith(".json"):
                continue
            levels.append(self._load_file(os.path.join(self.root, fn)))
        return levels

    def get(self, name: str) -> LevelInfo:
        return self._load_file(self.json_path(name))

    def _load_file(self, path: str) -> LevelInfo:
        name = os.path.splitext(os.path.basename(path))[0]
        info = LevelInfo(name=name, json_path=path, audio_path=None)
        try:
            with open(path, "r", encoding="utf-8") as fh:
                data = json.load(fh)
            info.notes = self._validate_notes(data.get("notes"))
            info.end = self._validate_end(data.get("end"))
            audio_file = data.get("audio")
            if not isinstance(audio_file, str) or not audio_file:
                raise ValueError("missing audio reference")
            audio_path = os.path.join(self.root, audio_file)
            if not os.path.isfile(audio_path):
                raise ValueError(f"audio file missing: {audio_file}")
            info.audio_path = audio_path
            info.valid = True
        except (OSError, ValueError) as exc:
            info.error = str(exc)
        return info

    @staticmethod
    def _validate_end(raw) -> float | None:
        if raw is None:
            return None
        if isinstance(raw, (int, float)) and raw > 0:
            return float(raw)
        return None

    @staticmethod
    def _validate_notes(raw) -> list:
        if not isinstance(raw, list):
            raise ValueError("notes must be a list")
        notes = []
        for item in raw:
            if not isinstance(item, dict):
                raise ValueError("bad note entry")
            lane = item.get("lane")
            time_ms = item.get("time")
            if not isinstance(lane, int) or not 0 <= lane <= 3:
                raise ValueError("note lane out of range")
            if not isinstance(time_ms, (int, float)) or time_ms < 0:
                raise ValueError("bad note time")
            end = item.get("end")
            if end is not None:
                if not isinstance(end, (int, float)) or end <= time_ms:
                    raise ValueError("bad sustain end")
                end = float(end)
            notes.append({
                "lane": lane,
                "time": float(time_ms),
                "end": end,
                "boost": bool(item.get("boost", False)),
            })
        notes.sort(key=lambda n: (n["time"], n["lane"]))
        return notes

    # ----------------------------------------------------------- create
    def unique_name(self, raw: str) -> str:
        base = self.sanitize(raw)
        name, n = base, 1
        while os.path.exists(self.json_path(name)) or self._audio_exists(name):
            n += 1
            name = f"{base}_{n}"
        return name

    def _audio_exists(self, name: str) -> bool:
        return any(os.path.exists(os.path.join(self.root, f"music_{name}{ext}"))
                   for ext in AUDIO_EXTS)

    def create(self, raw_name: str, source_audio: str) -> LevelInfo:
        """Copy ``source_audio`` into the level folder and write a chart."""
        name = self.unique_name(raw_name)
        ext = os.path.splitext(source_audio)[1].lower()
        if ext not in AUDIO_EXTS:
            raise ValueError(f"unsupported audio format: {ext or 'unknown'}")
        audio_name = f"music_{name}{ext}"
        shutil.copy2(source_audio, os.path.join(self.root, audio_name))
        info = LevelInfo(name=name, json_path=self.json_path(name),
                         audio_path=os.path.join(self.root, audio_name),
                         notes=[], valid=True)
        try:
            self.write(info)
        except OSError:
            # never leave a copied audio file without its chart
            self.delete(info)
            raise
        return info

    def write(self, info: LevelInfo) -> None:
        payload = {
            "name": info.name,
            "audio": info.audio_file,
            "end": info.end,
            "notes": [
                {"lane": n["lane"], "time": n["time"],
                 "end": n["end"], "boost": n["boost"]}
                for n in info.notes
            ],
        }
        tmp = info.json_path + ".tmp"
        with open(tmp, "w", encoding="utf-8") as fh:
            json.dump(payload, fh, indent=2)
        os.replace(tmp, info.json_path)

    def delete(self, info: LevelInfo) -> None:
        """Remove a level's chart and audio (used when recording is cancelled)."""
        for path in (info.json_path, info.audio_path):
            if not path:
                continue
            try:
                os.remove(path)
            except FileNotFoundError:
                pass
            except OSError as exc:
                # e.g. the audio file is still locked by the audio device
                print(f"[levels] could not remove {path}: {exc}")

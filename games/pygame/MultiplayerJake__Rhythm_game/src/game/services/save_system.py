"""Tamper-evident local statistics (``./stats.dat``).

Format (stdlib only):
    payload  = compact JSON {"highscores": {...}, "totals": {...}}
    body     = payload XORed with a sha256 keystream (unreadable binary)
    tag      = HMAC-SHA256(MAC_KEY, body)
    file     = base64(body + tag)  + newline

Any modification invalidates the HMAC: the file is moved to
``stats.dat.bak`` and defaults are loaded, so simple text-editor tampering
cannot produce believable scores.
"""

from __future__ import annotations

import base64
import hashlib
import hmac
import json
import os

SALT = b"rhythm-fest::stats-v1"
MAC_KEY = hashlib.sha256(SALT + b"|mac").digest()
XOR_KEY = hashlib.sha256(SALT + b"|xor").digest()
_TAG_LEN = hashlib.sha256().digest_size  # 32


def _keystream(n: int) -> bytes:
    out = bytearray()
    counter = 0
    while len(out) < n:
        out += hashlib.sha256(XOR_KEY + counter.to_bytes(8, "little")).digest()
        counter += 1
    return bytes(out[:n])


def _xor(data: bytes) -> bytes:
    stream = _keystream(len(data))
    return bytes(a ^ b for a, b in zip(data, stream))


def _defaults() -> dict:
    return {"highscores": {}, "totals": {"plays": 0}}


class SaveSystem:
    def __init__(self, path: str = "stats.dat"):
        self.path = path
        self.data = self._load()

    # ------------------------------------------------------------------ io
    def _load(self) -> dict:
        try:
            with open(self.path, "rb") as fh:
                raw = fh.read()
        except FileNotFoundError:
            return _defaults()
        except OSError as exc:
            print(f"[stats] cannot read {self.path}: {exc}")
            return _defaults()

        try:
            blob = base64.b64decode(raw.strip(), validate=True)
            if len(blob) <= _TAG_LEN:
                raise ValueError("truncated")
            body, tag = blob[:-_TAG_LEN], blob[-_TAG_LEN:]
            expect = hmac.new(MAC_KEY, body, hashlib.sha256).digest()
            if not hmac.compare_digest(tag, expect):
                raise ValueError("HMAC mismatch")
            data = json.loads(_xor(body).decode("utf-8"))
            if not isinstance(data.get("highscores"), dict):
                raise ValueError("bad schema")
            return data
        except Exception as exc:  # noqa: BLE001 - any failure => reset
            self._quarantine(exc)
            return _defaults()

    def _quarantine(self, exc: Exception) -> None:
        print(f"[stats] invalid stats.dat ({exc}); backing up and resetting")
        try:
            os.replace(self.path, self.path + ".bak")
        except OSError:
            pass

    def persist(self) -> None:
        body = _xor(json.dumps(self.data, separators=(",", ":")).encode("utf-8"))
        tag = hmac.new(MAC_KEY, body, hashlib.sha256).digest()
        blob = base64.b64encode(body + tag) + b"\n"
        tmp = self.path + ".tmp"
        try:
            with open(tmp, "wb") as fh:
                fh.write(blob)
            os.replace(tmp, self.path)
        except OSError as exc:
            print(f"[stats] could not save: {exc}")

    # ------------------------------------------------------------ scores
    def high_score(self, level_name: str) -> int:
        try:
            return int(self.data["highscores"].get(level_name, 0))
        except (TypeError, ValueError):
            return 0

    def record_score(self, level_name: str, score: int) -> bool:
        """Store ``score``; returns True if it is a new high score."""
        score = int(score)
        is_high = score > self.high_score(level_name)
        if is_high:
            self.data["highscores"][level_name] = score
        totals = self.data.setdefault("totals", {})
        totals["plays"] = int(totals.get("plays", 0)) + 1
        self.persist()
        return is_high

    def level_names(self) -> list:
        try:
            return sorted(self.data["highscores"].keys())
        except AttributeError:
            return []

"""Create screen: audio setup + real-time chart recording.

Setup state picks the audio (tkinter file dialog or a pasted path) and
the level name, copies the audio into ``music_levels/`` and writes an
empty chart. Recording state plays the song once while the creator taps
the lane keys; short taps become single notes, holding a key for
``SUSTAIN_MIN_MS`` or longer becomes a sustain, and holding Ctrl marks
the note as a boost note.

Editor-Stop key (default Space) saves; Esc cancels and removes anything
that was created.
"""

from __future__ import annotations

import os

import pygame

from ..core.scene import Scene
from ..ui import theme
from ..ui.highway import HighwayView, key_labels
from ..ui.widgets import Button, TextField

SUSTAIN_MIN_MS = 400.0        # must hold at least this long to be a sustain
BTN_W, BTN_H = 200, 50


class EditorScene(Scene):
    def __init__(self, game):
        super().__init__(game)
        self.state = "setup"          # "setup" | "recording"
        self.status = ""
        self.info = None              # LevelInfo once created
        self.recorded = []            # saved note dicts
        self.open_holds = {}          # lane -> {"start": ms, "boost": bool}
        self.highway = HighwayView()

        y = 300
        self.path_field = TextField((360, y, 560, 48),
                                    placeholder="audio file path (.mp3 / .wav)")
        self.name_field = TextField((360, y + 74, 560, 48),
                                    placeholder="level name")
        self.browse_btn = Button((940, y, 180, 48), "BROWSE...", self._browse,
                                 size=20)
        self.cancel_btn = Button((360, y + 158, 180, 50), "CANCEL", self._back,
                                 size=20)
        self.start_btn = Button((940, y + 158, 180, 50), "START RECORDING",
                                self._start_recording, size=18, kind="primary")
        self.setup_buttons = [self.browse_btn, self.cancel_btn, self.start_btn]

    # ------------------------------------------------------------- setup
    def _browse(self) -> None:
        try:
            import tkinter as tk
            from tkinter import filedialog
            root = tk.Tk()
            root.withdraw()
            root.attributes("-topmost", True)
            path = filedialog.askopenfilename(
                title="Select an audio file",
                filetypes=[("Audio files", "*.mp3 *.wav"),
                           ("All files", "*.*")])
            root.destroy()
        except Exception as exc:  # noqa: BLE001 - tkinter may be unavailable
            self.status = f"File dialog unavailable ({exc}) - paste the path"
            return
        if path:
            self.path_field.text = path
            if not self.name_field.text:
                self.name_field.text = os.path.splitext(os.path.basename(path))[0]
            self.status = ""

    def _start_recording(self) -> None:
        src = self.path_field.text.strip().strip('"')
        name = self.name_field.text.strip() or os.path.splitext(
            os.path.basename(src))[0]
        if not src:
            self.status = "Pick an audio file first (Browse or paste a path)."
            return
        if not os.path.isfile(src):
            self.status = f"File not found: {src}"
            return
        if os.path.splitext(src)[1].lower() not in (".mp3", ".wav"):
            self.status = "Only .mp3 and .wav files are supported."
            return
        try:
            self.info = self.game.levels.create(name, src)
        except (OSError, ValueError) as exc:
            self.status = f"Could not create level: {exc}"
            return

        try:
            self.game.audio.play(self.info.audio_path)
        except pygame.error as exc:
            self.game.audio.stop()   # release any handle taken by load()
            self.game.levels.delete(self.info)
            self.info = None
            self.status = f"Audio error: {exc}"
            return

        self.state = "recording"
        self.status = ""
        self.recorded = []
        self.open_holds = {}

    def _back(self) -> None:
        from .main_menu import MainMenuScene
        self.game.scenes.change(MainMenuScene(self.game))

    # --------------------------------------------------------- recording
    def _lane_map(self) -> dict:
        mapping = {}
        for i in range(4):
            key = self.game.config.lane_key(i)
            if key is not None:
                mapping[key] = i
        return mapping

    def _pos(self) -> float:
        return self.game.audio.position_ms()

    def _stop_key(self):
        return self.game.config.editor_stop_key()

    def _save(self) -> None:
        pos = self._pos()
        for lane, hold in list(self.open_holds.items()):
            self._close_hold(lane, pos)
        self.info.notes = sorted(self.recorded,
                                 key=lambda n: (n["time"], n["lane"]))
        # the level ends where the creator stopped the recording
        self.info.end = pos if pos > 0 else None
        self.game.levels.write(self.info)
        self.game.audio.stop()
        print(f"[editor] saved level '{self.info.name}' "
              f"with {len(self.info.notes)} note(s), end={self.info.end}")
        self._back()

    def _cancel(self) -> None:
        # stop first: the loaded music file is locked on Windows and the
        # delete below would silently fail, leaving the audio behind
        self.game.audio.stop()
        if self.info is not None:
            self.game.levels.delete(self.info)
            self.info = None
        self._back()

    def _place(self, lane: int, boost: bool) -> None:
        self.open_holds[lane] = {"start": self._pos(), "boost": boost}

    def _close_hold(self, lane: int, end_pos: float) -> None:
        hold = self.open_holds.pop(lane, None)
        if hold is None:
            return
        start = hold["start"]
        end = max(end_pos, start + 1.0)
        boost = hold["boost"]
        if end - start >= SUSTAIN_MIN_MS:
            self.recorded.append({"lane": lane, "time": start,
                                  "end": end, "boost": boost})
        else:
            self.recorded.append({"lane": lane, "time": start,
                                  "end": None, "boost": boost})

    # -------------------------------------------------------------- events
    def handle_event(self, event) -> None:
        if self.state == "setup":
            for widget in (self.path_field, self.name_field):
                if widget.handle_event(event):
                    return
            for btn in self.setup_buttons:
                if btn.handle_event(event):
                    return
            if event.type == pygame.KEYDOWN and event.key == \
                    self.game.config.key("cancel"):
                self._back()
            return

        # recording
        if event.type == pygame.KEYDOWN:
            cfg = self.game.config
            if event.key == cfg.key("cancel"):
                self._cancel()
                return
            if event.key == cfg.key("editor_undo"):
                if self.recorded:
                    self.recorded.pop()
                return
            stop = self._stop_key()
            if stop is not None and event.key == stop:
                self._save()
                return
            lanes = self._lane_map()
            if event.key in lanes:
                mods = event.mod if hasattr(event, "mod") else pygame.key.get_mods()
                boost = bool(mods & (pygame.KMOD_CTRL | pygame.KMOD_LCTRL |
                                     pygame.KMOD_RCTRL))
                lane = lanes[event.key]
                if lane not in self.open_holds:
                    self._place(lane, boost)
        elif event.type == pygame.KEYUP:
            lanes = self._lane_map()
            if event.key in lanes and lanes[event.key] in self.open_holds:
                self._close_hold(lanes[event.key], self._pos())

    # -------------------------------------------------------------- update
    def update(self, dt: float) -> None:
        self.path_field.update(dt)
        self.name_field.update(dt)
        if self.state == "recording" and self.game.audio.finished:
            self._save()

    # ---------------------------------------------------------------- draw
    def draw(self, surface) -> None:
        if self.state == "setup":
            self._draw_setup(surface)
        else:
            self._draw_recording(surface)

    def _draw_setup(self, surface) -> None:
        theme.title_text(surface, "NEW LEVEL", theme.BASE_W // 2, 74, 42)
        # labels sit to the left of their input, vertically centred on it
        theme.draw_text(surface, "1. Choose an audio file", 330, 313, 20,
                        color=theme.CYAN, align="right")
        theme.draw_text(surface, "2. Name the level", 330, 387, 20,
                        color=theme.CYAN, align="right")

        self.path_field.draw(surface)
        self.name_field.draw(surface)
        for btn in self.setup_buttons:
            btn.draw(surface)

        theme.draw_text(surface,
                        "The audio is copied into music_levels/ and a chart "
                        "file is created.",
                        theme.BASE_W // 2, 534, 15, color=theme.DIM,
                        align="center")
        if self.status:
            theme.draw_text(surface, self.status, theme.BASE_W // 2, 566, 17,
                            color=theme.RED, align="center")
        theme.draw_text(surface,
                        f"{self.game.config.label('cancel')} = back to main menu",
                        theme.BASE_W // 2, theme.BASE_H - 60, 16,
                        color=theme.DIM, align="center")

    def _centered_line(self, surface, text, y, size, color, pad=10, glow=None):
        """Backdrop panel first, then the text on top of it."""
        w, h = theme.font(size).size(text)
        cx = theme.BASE_W // 2
        bg = pygame.Rect(cx - w // 2 - pad, y - 4, w + pad * 2, h + 8)
        theme.panel(surface, bg, fill=theme.PANEL, border=theme.BORDER, radius=6)
        theme.draw_text(surface, text, cx, y, size, color=color,
                        align="center", glow=glow)

    def _draw_recording(self, surface) -> None:
        pos = self._pos()
        minutes, seconds = divmod(int(pos // 1000), 60)

        # top bar: recording timer (y=14, above the highway which starts at y=60)
        theme.draw_text(surface,
                        f"\u25cf RECORDING  {minutes:02d}:{seconds:02d}",
                        theme.BASE_W // 2, 14, 26, color=theme.YELLOW,
                        align="center", glow=theme.ORANGE)

        display_notes = list(self.recorded)
        for lane, hold in self.open_holds.items():
            held_for = pos - hold["start"]
            is_sustain = held_for >= SUSTAIN_MIN_MS
            display_notes.append({"lane": lane, "time": hold["start"],
                                  "end": pos if is_sustain else None,
                                  "boost": hold["boost"]})

        cfg = self.game.config
        self.highway.draw(surface, pos, display_notes,
                          lane_down=[lane in self.open_holds for lane in range(4)],
                          labels=key_labels(cfg))

        # level info drawn ON TOP of the highway so it always reads
        self._centered_line(
            surface,
            f"{self.info.name}  ·  "
            f"{len(self.recorded) + len(self.open_holds)} note(s)",
            66, 16, theme.WHITE)

        pending = [lane for lane, hold in self.open_holds.items()
                   if pos - hold["start"] < SUSTAIN_MIN_MS]
        if pending:
            left = max(SUSTAIN_MIN_MS - (pos - self.open_holds[pending[0]]["start"]),
                       0.0)
            self._centered_line(
                surface, f"keep holding  {left / 1000:.1f}s for a sustain",
                96, 15, theme.YELLOW, pad=8)

        # bottom hints with backdrop - moved lower
        stop = cfg.editor_stop_name
        hint = (f"Lane keys = note  ·  hold >= {SUSTAIN_MIN_MS / 1000:.1f}s = sustain"
                f"  ·  Ctrl+key = boost note\n"
                f"{stop} = stop & save  ·  {cfg.label('editor_undo')} = undo"
                f"  ·  {cfg.label('cancel')} = cancel")
        y = 590
        for line in hint.split("\n"):
            self._centered_line(surface, line, y, 16, theme.WHITE)
            y += 28

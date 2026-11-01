"""Choose or create a Profile. No passwords: a shared lab PC holds several."""
from __future__ import annotations

import pygame

from .. import theme
from ..app import SIZE, Scene
from ..widgets import Button, Row, TextField


TOP, PITCH, VISIBLE = 250, 56, 7     # seven rows still leave New Profile on screen
ROW_W, LABEL_PAD = 440, 20
HINT_X = SIZE[0] // 2 + ROW_W // 2 + 16


def _label(name: str, student_id: str) -> str:
    """Name and student ID, the name shortened with an ellipsis if the two don't fit on a row."""
    tail = f"  ({student_id})"

    def fits(text: str) -> bool:
        return theme.font(20).size(text)[0] <= ROW_W - LABEL_PAD

    if fits(name + tail):
        return name + tail
    while name and not fits(name + "\u2026" + tail):
        name = name[:-1]
    label = name.rstrip() + "\u2026" + tail
    while not fits(label):
        label = label[:-2] + "\u2026"
    return label


class ProfileScene(Scene):
    def __init__(self, app):
        super().__init__(app)
        self.creating = False
        self.language = "python"
        self.profiles = app.store.profiles()
        self.first = 0                # index of the top Profile shown
        self._build()

    @property
    def more_above(self) -> int:
        return self.first

    @property
    def more_below(self) -> int:
        return max(0, len(self.profiles) - self.first - VISIBLE)

    def _scroll(self, rows: int):
        first = min(max(self.first + rows, 0), max(0, len(self.profiles) - VISIBLE))
        if first != self.first:
            self.first = first
            self._build()

    def _build(self):
        self.buttons, self.fields = [], []
        cx = SIZE[0] // 2
        if not self.creating:
            y = TOP
            for p in self.profiles[self.first:self.first + VISIBLE]:
                self.buttons.append(Button(_label(p.name, p.student_id), pygame.Rect(cx - ROW_W // 2, y, ROW_W, 46),
                                           lambda p=p: self.app.sign_in(p)))
                y += PITCH
            self.buttons.append(Button("New Profile", pygame.Rect(cx - 110, max(y + 20, 330), 220, 48),
                                       self._start_create, accent=theme.GOOD))
            return
        self.name = TextField("Name", pygame.Rect(cx - 220, 260, 440, 44))
        self.sid = TextField("Student ID", pygame.Rect(cx - 220, 350, 440, 44))
        self.name.focused = True
        self.fields = [self.name, self.sid]
        row = Row(cx - 220, 440)
        self.buttons += [
            row.add("Python", lambda: self._lang("python"), selected=self.language == "python"),
            row.add("Java", lambda: self._lang("java"), selected=self.language == "java"),
        ]
        row = Row(cx - 220, 520)
        self.buttons += [row.add("Create", self._create, accent=theme.GOOD), row.add("Cancel", self._cancel)]

    def _start_create(self):
        self.creating, self.message = True, ""
        self._build()

    def _cancel(self):
        self.creating, self.message = False, ""
        self._build()

    def _lang(self, lang):
        self.language = lang
        for b in self.buttons:
            if b.label in ("Python", "Java"):
                b.selected = b.label.lower() == lang

    def _create(self):
        try:
            profile = self.app.store.create_profile(self.name.text, self.sid.text, self.language)
        except ValueError as exc:
            self.message = "Name and student ID are both required."
            return
        self.app.sign_in(profile)

    def on_event(self, event):
        if not self.creating:
            if event.type == pygame.MOUSEWHEEL:
                self._scroll(-event.y)
            elif event.type == pygame.KEYDOWN and event.key in (pygame.K_UP, pygame.K_DOWN):
                self._scroll(1 if event.key == pygame.K_DOWN else -1)
        elif event.type == pygame.KEYDOWN and event.key == pygame.K_TAB:
            self.name.focused, self.sid.focused = self.sid.focused, self.name.focused
        elif event.type == pygame.KEYDOWN and event.key == pygame.K_RETURN:
            self._create()

    def draw(self, surf):
        cx = SIZE[0] // 2
        theme.draw_text(surf, "STRUCTURA", (cx, 80), 64, theme.SELECT, bold=True, center=True)
        theme.draw_text(surf, "Repair the Datasphere, one data structure at a time.", (cx, 160), 22,
                        theme.MUTED, center=True)
        if self.creating:
            theme.draw_text(surf, "Code Mirror language", (cx - 220, 414), 18, theme.MUTED)
        else:
            theme.draw_text(surf, "Who's playing?", (cx, 210), 24, center=True)
            last = TOP + (VISIBLE - 1) * PITCH
            if self.more_above:
                theme.draw_text(surf, f"\u2191 {self.more_above} more", (HINT_X, TOP + 12), 18, theme.MUTED)
            if self.more_below:
                theme.draw_text(surf, f"\u2193 {self.more_below} more", (HINT_X, last + 12), 18, theme.MUTED)
            if self.more_above or self.more_below:
                theme.draw_text(surf, "Scroll or use the arrow keys", (HINT_X, last + 34), 16, theme.MUTED)
        if self.message:
            theme.draw_text(surf, self.message, (cx, 600), 20, theme.BAD, center=True)
        super().draw(surf)

"""Where a Puzzle is played. Clicks become Moves; the PuzzleSession judges them."""
from __future__ import annotations

import pygame

from ...models import Move
from ...puzzles.session import DEAD_END, PuzzleSession, reference_count
from .. import theme
from ..anim import StepPlayer
from ..app import SIZE, Scene
from ..code_panel import CodePanel
from ..fx import Effects, Shake
from ..renderers import make_renderer
from ..widgets import Row

VIZ = pygame.Rect(30, 110, 820, 400)
CODE = pygame.Rect(870, 110, 380, 400)
BRIEF_W, BRIEF_SIZE = 840, 17       # one line under the title; a second would hide behind the board
# Ops made with a button rather than on the board, and whether they take the next Tray value.
BUTTON_OPS = {"push": True, "pop": False, "enqueue": True, "dequeue": False}
# Ops made with a button on the one selected element.
ROTATIONS = {"rotate_left": "Rotate Left", "rotate_right": "Rotate Right"}
SELECTING = {"swap", "delete", *ROTATIONS}


class PuzzleScene(Scene):
    watching = False                     # True while the Reference Solution plays itself

    def __init__(self, app, zone, puzzle):
        super().__init__(app)
        self.zone, self.puzzle = zone, puzzle
        self.session = PuzzleSession(puzzle)
        self.renderer = make_renderer(puzzle.structure, VIZ, app.profile.speed)
        self.renderer.ops = set(puzzle.ops)
        self.player = StepPlayer(app.profile.speed)
        self.code_panel = CodePanel(CODE, app.profile.language)
        self.code_panel.show(puzzle.code)
        if table := self.session.goal.big_o_table():
            self.code_panel.show_table(table)
        self.selected: list[int] = []
        self.replacing: int | None = None    # key being deleted, awaiting its replacement
        self.hint_move: Move | None = None
        self.glitch_flash = 0.0
        self.fx = Effects()
        self.board_shake = Shake()
        self.message = puzzle.intro or puzzle.brief
        self.message_colour = theme.TEXT
        self.answering = self.session.goal.options is not None    # quiz and select Puzzles
        self._sync()

    # ---- state -> view ---------------------------------------------------
    def _sync(self):
        s = self.session
        self.renderer.show_slots = s.tray_next is not None and not s.done   # the renderer filters by ops
        self.renderer.sync(s.model)
        row = Row(30, SIZE[1] - 70)
        self.buttons = []
        if "swap" in self.puzzle.ops:
            self.buttons.append(row.add("Swap", self._swap, enabled=len(self.selected) == 2 and not s.done,
                                        accent=self.zone.color))
        if "delete" in self.puzzle.ops:
            ready = len(self.selected) == 1 and self.replacing is None
            self.buttons.append(row.add("Delete", self._delete, enabled=ready and not s.done, accent=theme.BAD))
        for op, label in ROTATIONS.items():
            if op in self.puzzle.ops:
                move = Move.of(op, self.selected[0]) if len(self.selected) == 1 else None
                ready = move is not None and not s.model.why_illegal(move)
                self.buttons.append(row.add(label, lambda m=move: self._attempt(m), enabled=ready and not s.done,
                                            accent=self.zone.color))
        for op, takes_tray in BUTTON_OPS.items():
            if op in self.puzzle.ops:
                move = Move.of(op, s.tray_next) if takes_tray else Move.of(op)
                ready = s.tray_next is not None if takes_tray else not s.model.why_illegal(move)
                self.buttons.append(row.add(op.capitalize(), lambda m=move: self._attempt(m),
                                            enabled=ready and not s.done, accent=self.zone.color))
        if self.answering:
            self.buttons += self._answer_buttons()
        self.buttons += [
            row.add("Undo", self._undo, enabled=bool(s.history) and not s.done),
            row.add("Hint", self._hint, enabled=not s.done, accent=theme.ACTIVE),
        ]
        right = Row(SIZE[0] - 360, SIZE[1] - 70)
        if s.done:
            right.x = SIZE[0] - 220
            self.buttons.append(right.add("See Results", self._results, width=190, accent=theme.GOOD))
        else:
            right.x = SIZE[0] - 200
            self.buttons.append(right.add("Leave Puzzle", lambda: self.app.open_zone(self.zone), width=170))

    def _answer_buttons(self):
        """One button per option, inside the board under the script."""
        s, goal = self.session, self.session.goal
        rows = [Row(VIZ.x + 30, VIZ.bottom - 130), Row(VIZ.x + 30, VIZ.bottom - 74)]
        out = []
        for i, option in enumerate(goal.options):
            row = rows[0] if i < 2 else rows[1]
            hinted = self.hint_move == Move.of("answer", i)
            out.append(row.add(option, lambda i=i: self._attempt(Move.of("answer", i)), width=360,
                               enabled=not s.done and not self.watching, selected=s.done and i == goal.correct,
                               accent=theme.ACTIVE if hinted else (theme.GOOD if s.done else self.zone.color)))
        return out

    def _say(self, text, colour=theme.TEXT):
        self.message, self.message_colour = text, colour

    # ---- actions -----------------------------------------------------------
    def _attempt(self, move: Move):
        out = self.session.try_move(move)
        self.selected, self.replacing = [], None
        if not out.ok:
            self.glitch_flash = 0.6
            cells = [a for a in move.args[:2] if isinstance(a, int)] if move.op in SELECTING | {"visit"} else []
            if cells:
                self.renderer.shake(cells)
            else:
                self.board_shake = Shake(0.35, amplitude=6)
            self._say(f"Glitch! {out.glitch}", theme.BAD)
            self._sync()
            return
        self.hint_move = None
        self.code_panel.show(self.puzzle.code) if self.puzzle.code else \
            self.code_panel.show_for(self.puzzle.structure, move.op)
        self.player.play(out.steps)
        if out.steps:
            self._say(out.steps[-1].text)
        self._sync()
        if move.op == "visit":
            self.fx.ripple(self.renderer.center_of(move.args[0]), theme.ACTIVE, radius=70)
        if out.disruption:
            self.player.play(out.disruption_steps)
            self._say(out.disruption, theme.BAD)
            self.board_shake = Shake(0.7, amplitude=16)
        if out.done:
            self._say(self.puzzle.outro or "Structure repaired!", theme.GOOD)
            self._celebrate()
        elif self.session.dead_end:
            self._say(f"{out.disruption} {DEAD_END}" if out.disruption else DEAD_END, theme.BAD)

    def _celebrate(self):
        self.renderer.celebrate()
        colours = [theme.GOOD, theme.STAR, theme.SELECT, self.zone.color, theme.TEXT]
        for k in range(5):
            self.fx.particles.burst((VIZ.x + VIZ.w * (k + 0.5) / 5, VIZ.centery), 26, colours)

    def _swap(self):
        if len(self.selected) == 2:
            self._attempt(Move.of("swap", *self.selected))

    def _delete(self):
        if len(self.selected) != 1:
            return
        (key,) = self.selected
        if not self.session.model.needs_replacement(key):
            self._attempt(self.session.model.delete_move(key))
            return
        self.replacing = key
        self._say(f"{key} has two children, so another node takes its place. "
                  f"Click the node that replaces {key}, or click {key} again to cancel.", theme.ACTIVE)
        self._sync()

    def _replace_with(self, key):
        deleting, self.replacing = self.replacing, None
        if key != deleting:
            self._attempt(self.session.model.delete_move(deleting, key))
            return
        self.selected = []
        self._say("Delete cancelled.", theme.MUTED)
        self._sync()

    def _undo(self):
        if self.session.undo():
            self.selected, self.hint_move, self.replacing = [], None, None
            self.player.clear()
            self._say("Undone. (The Move still counts toward your score.)", theme.MUTED)
            self._sync()

    def _hint(self):
        tier, text, move = self.session.hint()
        self.hint_move = move
        if move is not None and self.replacing is not None and move.args[:1] != (self.replacing,):
            self.replacing, self.selected = None, []
        self._say(text, theme.ACTIVE)
        self._sync()

    def _results(self):
        from .results import ResultsScene
        self.app.go(ResultsScene(self.app, self.zone, self.puzzle, self.session))

    def on_event(self, event):
        if event.type != pygame.MOUSEBUTTONUP or event.button != 1 or self.session.done:
            return
        for t in self.renderer.targets():
            if not t.rect.collidepoint(event.pos):
                continue
            if t.kind == "slot":
                self._attempt(self.renderer.slot_move(t.key, self.session.tray_next))
            elif self.replacing is not None:
                self._replace_with(t.key)
            elif "visit" in self.puzzle.ops:
                self._attempt(Move.of("visit", t.key))
            elif SELECTING & set(self.puzzle.ops):
                if t.key in self.selected:
                    self.selected.remove(t.key)
                else:
                    keep = 2 if "swap" in self.puzzle.ops else 1
                    self.selected = (self.selected + [t.key])[-keep:]
                self._sync()
            return

    # ---- frame -------------------------------------------------------------
    def update(self, dt):
        self.player.update(dt)
        self.renderer.on_step(self.player.current)
        self.renderer.update(dt)
        self.code_panel.update(dt)
        self.fx.update(dt)
        self.board_shake.update(dt)
        self.glitch_flash = max(0.0, self.glitch_flash - dt)

    def hinted(self) -> tuple:
        """Keys of the elements the third-tier Hint points at."""
        m = self.hint_move
        if m is None:
            return ()
        if m.op == "swap":
            return m.args
        if m.op == "delete" and self.replacing is not None and m.args[0] == self.replacing:
            return (m.args[1],)
        if m.op in ("visit", "delete", *ROTATIONS):
            return (m.args[0],)
        return ()

    def _draw_question(self, surf):
        """Quiz Puzzles: the operation script, worked in the player's head, not on the board.
        Select Puzzles: the job to choose a structure for."""
        ox, oy = self.board_shake.offset()
        script = self.session.goal.question()
        if not script:                                  # Select: the job stays in view after a Glitch replaces the message
            theme.draw_text(surf, "The job", (VIZ.x + 30 + ox, VIZ.y + 24 + oy), 18, theme.MUTED)
            theme.draw_text(surf, self.puzzle.brief, (VIZ.x + 30 + ox, VIZ.y + 56 + oy), 26, theme.TEXT,
                            width=VIZ.w - 60)
            return
        theme.draw_text(surf, "Operations", (VIZ.x + 30 + ox, VIZ.y + 24 + oy), 18, theme.MUTED)
        for k, line in enumerate(script):
            col, rowi = divmod(k, 4)
            theme.draw_text(surf, f"{k + 1}.  {line}", (VIZ.x + 40 + col * 260 + ox, VIZ.y + 56 + rowi * 34 + oy),
                            24, theme.TEXT)

    def draw(self, surf):
        s, p = self.session, self.puzzle
        theme.draw_text(surf, f"{self.zone.name}  ·  {theme.STAGE_LABEL[p.stage]}", (30, 14), 17, self.zone.color)
        theme.draw_text(surf, p.title, (30, 36), 30, bold=True)
        theme.draw_text(surf, f"Moves {s.moves}   Par {reference_count(p)}   Glitches {s.glitches}   "
                              f"Hints {s.hints_used}", (SIZE[0] - 30 - 420, 46), 18, theme.MUTED)
        theme.draw_text(surf, p.brief, (30, 78), BRIEF_SIZE, theme.MUTED, width=BRIEF_W)

        edge = theme.BAD if self.glitch_flash > 0 or self.board_shake.active else theme.PANEL_EDGE
        theme.panel(surf, VIZ.move(*self.board_shake.offset()), edge=edge)
        if s.state.tray:
            theme.draw_text(surf, "Tray  next:", (VIZ.x + 16, VIZ.y + 16), 18, theme.MUTED)
            theme.draw_text(surf, str(s.state.tray[0]), (VIZ.x + 120, VIZ.y + 8), 30, theme.GOOD, bold=True)
            if len(s.state.tray) > 1:
                rest = "  ".join(str(v) for v in s.state.tray[1:])
                theme.draw_text(surf, f"then  {rest}", (VIZ.x + 170, VIZ.y + 16), 18, theme.MUTED)
        hint_slot = self.renderer.slot_for(self.hint_move) if self.hint_move else None
        if self.answering:
            self._draw_question(surf)
        else:
            self.renderer.draw(surf, self.player.highlights(), self.selected, self.hinted(), hint_slot,
                               offset=self.board_shake.offset())
        step = self.player.current
        self.code_panel.draw(surf, step.kind if step else None)

        box = pygame.Rect(30, 525, SIZE[0] - 60, 100)
        theme.panel(surf, box)
        y = theme.draw_text(surf, self.message, (box.x + 18, box.y + 14), 21, self.message_colour, width=box.w - 36)
        if step and step.text and self.message_colour != theme.BAD:
            theme.draw_text(surf, step.text, (box.x + 18, y + 4), 17, theme.ACTIVE)
        super().draw(surf)
        self.fx.draw(surf)

"""The two robots. Pure game logic - drawing lives in animation.py."""
from . import settings as S
from .physics import KinematicBody


class Intent:
    """What the player wants this frame (decoupled from the keyboard)."""
    __slots__ = ("move", "jump_pressed", "jump_held")

    def __init__(self, move=0, jump_pressed=False, jump_held=False):
        self.move = move
        self.jump_pressed = jump_pressed
        self.jump_held = jump_held


# What each robot survives. Spikes and electric barriers hurt both.
ROBOT_DEFS = {
    "x": {"name": "ROBO-X", "immune": frozenset({"lava"})},
    "b": {"name": "ROBO-B", "immune": frozenset({"water"})},
}


class Player(KinematicBody):
    def __init__(self, kind, spawn_x, spawn_y):
        """`spawn_x`, `spawn_y` = top-left corner of the hitbox."""
        super().__init__(spawn_x, spawn_y)
        self.kind = kind                      # 'x' (red) or 'b' (blue)
        self.name = ROBOT_DEFS[kind]["name"]
        self.immune = ROBOT_DEFS[kind]["immune"]
        self.alive = True
        self.death_cause = None
        self.death_timer = 0.0
        self.at_door = False
        self.celebrating = False
        self.events = []                      # consumed by the scene each frame (sound, particles)

    # ------------------------------------------------------------------ state
    def can_survive(self, hazard_kind):
        return hazard_kind in self.immune

    def kill(self, cause):
        if not self.alive:
            return
        self.alive = False
        self.death_cause = cause
        self.death_timer = 0.0
        self.vx = 0.0
        self.vy = 0.0
        self.events.append("death")

    def celebrate(self):
        self.celebrating = True

    @property
    def anim_state(self):
        if not self.alive:
            return "death"
        if self.celebrating:
            return "victory"
        if not self.on_ground:
            return "jump" if self.vy < 0 else "fall"
        if self.land_timer > 0:
            return "land"
        if abs(self.vx) > 20:
            return "walk"
        return "idle"

    # ------------------------------------------------------------------ update
    def update(self, dt, intent, level):
        if not self.alive:
            self.death_timer += dt
            return
        if self.celebrating:
            intent = Intent()                 # frozen controls during the victory pose
        self.events.extend(self.step(dt, intent.move, intent.jump_pressed,
                                     intent.jump_held, level.solids_near))

"""Kinematic platformer body: gravity, acceleration, variable jump, coyote time, jump buffer."""
from . import settings as S
from .collision import Box, move_x, move_y


def approach(value, target, delta):
    """Move `value` toward `target` by at most `delta`."""
    if value < target:
        return min(value + delta, target)
    return max(value - delta, target)


class KinematicBody:
    """A box that falls, walks and jumps against a list of solids.

    The caller supplies `solids_fn(box) -> iterable of Box` so this class is
    independent from how the level stores its geometry.
    """

    def __init__(self, x, y, w=S.PLAYER_W, h=S.PLAYER_H):
        self.box = Box(x, y, w, h)
        self.vx = 0.0
        self.vy = 0.0
        self.on_ground = False
        self.ground_solid = None      # the Box we are standing on (identity matters for moving platforms)
        self.coyote = 0.0
        self.jump_buffer = 0.0
        self.jumping = False          # True while rising from a voluntary jump
        self.facing = 1
        self.land_timer = 0.0

    def step(self, dt, move, jump_pressed, jump_held, solids_fn):
        """Advance one frame. Returns a list of event names ('jump', 'land')."""
        events = []

        # --- horizontal velocity (acceleration / deceleration) ---------------
        if move != 0:
            accel = S.ACCEL_GROUND if self.on_ground else S.ACCEL_AIR
            if self.vx * move < 0:          # turning around is snappier
                accel *= 1.6
            self.vx = approach(self.vx, move * S.MOVE_SPEED, accel * dt)
            self.facing = 1 if move > 0 else -1
        else:
            fr = S.FRICTION_GROUND if self.on_ground else S.FRICTION_AIR
            self.vx = approach(self.vx, 0.0, fr * dt)

        # --- jump timers (coyote time + input buffer) --------------------------
        self.coyote = S.COYOTE_TIME if self.on_ground else self.coyote - dt
        self.jump_buffer = S.JUMP_BUFFER if jump_pressed else self.jump_buffer - dt
        self.land_timer = max(0.0, self.land_timer - dt)

        if self.jump_buffer > 0 and self.coyote > 0:
            self.vy = -S.JUMP_SPEED
            self.coyote = 0.0
            self.jump_buffer = 0.0
            self.on_ground = False
            self.ground_solid = None
            self.jumping = True
            events.append("jump")

        # variable jump height: letting go of the key cuts the ascent
        if self.jumping and not jump_held and self.vy < -S.JUMP_RELEASE_SPEED:
            self.vy = -S.JUMP_RELEASE_SPEED

        # --- gravity ---------------------------------------------------------
        self.vy = min(self.vy + S.GRAVITY * dt, S.MAX_FALL_SPEED)

        # --- integrate + resolve each axis separately --------------------------
        solids = list(solids_fn(self.box))
        hit_x, _ = move_x(self.box, self.vx * dt, solids)
        if hit_x:
            self.vx = 0.0

        fall_speed = self.vy
        hit_y, solid = move_y(self.box, self.vy * dt, solids)
        if hit_y == 1:
            if not self.on_ground and fall_speed > S.LAND_MIN_SPEED:
                self.land_timer = S.LAND_ANIM_TIME
                events.append("land")
            self.on_ground = True
            self.ground_solid = solid
            self.vy = 0.0
            self.jumping = False
        elif hit_y == -1:
            self.vy = 0.0
            self.on_ground = False
            self.ground_solid = None
        else:
            self.on_ground = False
            self.ground_solid = None
        return events

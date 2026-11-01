"""Axis-aligned boxes and swept, sub-stepped collision resolution.

Everything here works with plain floats and has no pygame dependency, so the
physics can be unit-tested headless.

Anti-tunnelling: a motion is split into sub-steps of at most MAX_STEP pixels
(smaller than the thinnest solid in the game), and each axis is resolved
separately. That is what keeps fast-falling robots from slipping through
platforms.
"""
import math

EPS = 1e-3
MAX_STEP = 8.0


class Box:
    """A float rectangle. Mutable on purpose: moving platforms update theirs in place
    so that a robot can remember *which* box it is standing on (identity check)."""
    __slots__ = ("x", "y", "w", "h")

    def __init__(self, x, y, w, h):
        self.x = float(x)
        self.y = float(y)
        self.w = float(w)
        self.h = float(h)

    # edges ----------------------------------------------------------------
    @property
    def left(self):
        return self.x

    @property
    def right(self):
        return self.x + self.w

    @property
    def top(self):
        return self.y

    @property
    def bottom(self):
        return self.y + self.h

    @property
    def centerx(self):
        return self.x + self.w / 2.0

    @property
    def centery(self):
        return self.y + self.h / 2.0

    # queries --------------------------------------------------------------
    def overlaps(self, other):
        """True when the interiors intersect (touching edges do NOT count)."""
        return (self.x < other.x + other.w - EPS and self.x + self.w > other.x + EPS and
                self.y < other.y + other.h - EPS and self.y + self.h > other.y + EPS)

    def contains_point(self, px, py):
        return self.x <= px <= self.x + self.w and self.y <= py <= self.y + self.h

    def copy(self):
        return Box(self.x, self.y, self.w, self.h)

    def inflated(self, dx, dy):
        return Box(self.x - dx, self.y - dy, self.w + 2 * dx, self.h + 2 * dy)

    def ints(self):
        """(x, y, w, h) as ints - handy for pygame.Rect(*box.ints())."""
        return (int(round(self.x)), int(round(self.y)), int(round(self.w)), int(round(self.h)))

    def __repr__(self):
        return "Box(%.1f, %.1f, %.1f, %.1f)" % (self.x, self.y, self.w, self.h)


def move_x(box, dx, solids):
    """Move `box` horizontally by dx. Returns (hit_direction, solid): +1 right wall, -1 left wall, 0 none."""
    if dx == 0:
        return 0, None
    steps = max(1, int(math.ceil(abs(dx) / MAX_STEP)))
    step = dx / steps
    hit, hit_solid = 0, None
    for _ in range(steps):
        box.x += step
        for s in solids:
            if box.overlaps(s):
                if step > 0:
                    box.x = s.x - box.w
                    hit = 1
                else:
                    box.x = s.x + s.w
                    hit = -1
                hit_solid = s
        if hit:
            break
    return hit, hit_solid


def move_y(box, dy, solids):
    """Move `box` vertically by dy. Returns (hit_direction, solid): +1 floor, -1 ceiling, 0 none."""
    if dy == 0:
        return 0, None
    steps = max(1, int(math.ceil(abs(dy) / MAX_STEP)))
    step = dy / steps
    hit, hit_solid = 0, None
    for _ in range(steps):
        box.y += step
        for s in solids:
            if box.overlaps(s):
                if step > 0:
                    box.y = s.y - box.h
                    hit = 1
                else:
                    box.y = s.y + s.h
                    hit = -1
                hit_solid = s
        if hit:
            break
    return hit, hit_solid


def push_out(box, solid):
    """Shove `box` out of `solid` along the axis of least penetration.
    Used when a moving platform ends up overlapping a robot that is not riding it.
    Returns 'up', 'down', 'left' or 'right' (the direction the box was moved)."""
    pen = {
        "up": box.bottom - solid.top,
        "down": solid.bottom - box.top,
        "left": box.right - solid.left,
        "right": solid.right - box.left,
    }
    side = min(pen, key=pen.get)
    if side == "up":
        box.y = solid.top - box.h
    elif side == "down":
        box.y = solid.bottom
    elif side == "left":
        box.x = solid.left - box.w
    else:
        box.x = solid.right
    return side

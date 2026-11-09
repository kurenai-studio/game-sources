"""Geometry: an oriented (rotated) rectangle and exact collision tests."""

from pygame.math import Vector2

from app.util.mathx import clamp


class RotatedRect:
    """A rectangle defined by its center, a unit 'forward' direction, a length
    (along forward) and a width (across forward)."""

    def __init__(self, center, direction, length: float, width: float) -> None:
        self.center = Vector2(center)
        direction = Vector2(direction)
        self.direction = direction.normalize() if direction.length_squared() > 0 else Vector2(1, 0)
        self.length = length
        self.width = width

    @property
    def normal(self) -> Vector2:
        """Unit vector perpendicular to the forward direction."""
        return Vector2(-self.direction.y, self.direction.x)

    def corners(self) -> list[Vector2]:
        """Front-left, front-right, back-right, back-left (corners 0 and 1 = leading edge)."""
        forward = self.direction * (self.length / 2)
        side = self.normal * (self.width / 2)
        c = self.center
        return [c + forward + side, c + forward - side, c - forward - side, c - forward + side]

    def collides_circle(self, point, radius: float) -> bool:
        """Exact circle vs rotated rectangle test.

        Express the circle's center in the rectangle's own frame, clamp it to the
        rectangle's half extents to find the closest point, and compare distances.
        """
        offset = Vector2(point) - self.center
        local_x = offset.dot(self.direction)
        local_y = offset.dot(self.normal)
        dx = local_x - clamp(local_x, -self.length / 2, self.length / 2)
        dy = local_y - clamp(local_y, -self.width / 2, self.width / 2)
        return dx * dx + dy * dy <= radius * radius

    def collides_rect(self, other: "RotatedRect") -> bool:
        """Exact rotated rectangle vs rotated rectangle test (Separating Axis Theorem).

        Two convex shapes are apart if some axis exists where their shadows don't
        overlap. For rectangles, only their four edge directions need checking.
        """
        mine, theirs = self.corners(), other.corners()
        for axis in (self.direction, self.normal, other.direction, other.normal):
            a = [p.dot(axis) for p in mine]
            b = [p.dot(axis) for p in theirs]
            if max(a) < min(b) or max(b) < min(a):
                return False                      # found a gap: no collision
        return True

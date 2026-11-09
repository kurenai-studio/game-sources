"""Math helpers: clamping and interpolation."""

Color = tuple[int, int, int]


def clamp(value: float, low: float, high: float) -> float:
    """Limit value to the range [low, high]."""
    return max(low, min(high, value))


def lerp_color(a: Color, b: Color, t: float) -> Color:
    """Blend two RGB colors: t = 0 -> a, t = 1 -> b (t is clamped)."""
    t = clamp(t, 0.0, 1.0)
    return (int(a[0] + (b[0] - a[0]) * t),
            int(a[1] + (b[1] - a[1]) * t),
            int(a[2] + (b[2] - a[2]) * t))

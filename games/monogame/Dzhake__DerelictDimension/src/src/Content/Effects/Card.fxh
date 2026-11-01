// SDF of a box, whose edges are beveled.
float sdBevelBox(float2 p, float2 b, float bevel)
{
    p = abs(p - 0.5);
    return max(p.x + p.y - bevel, max(p.x - b.x, p.y - b.y));
}
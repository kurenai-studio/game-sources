using Godot;

/// <summary>
/// A collection of geometric utility methods for calculating directions.
/// </summary>
public static class PathGeometry
{
    /// <summary>
    /// Calculates the intersection point of two offset line segments.
    /// Used to create clean continuous corners when offset lines change direction.
    /// </summary>
    public static Vector2 CalculateIntersection(Vector2 p1, Vector2 dir1, float offset1, Vector2 p2, Vector2 dir2, float offset2, Vector2 currentPos)
    {
        Vector2 perp1 = new Vector2(-dir1.Y, dir1.X);
        Vector2 perp2 = new Vector2(-dir2.Y, dir2.X);

        Vector2 line1Start = p1 + perp1 * offset1;
        Vector2 line2Start = p2 + perp2 * offset2;

        float det = dir1.Cross(dir2);

        // If lines are nearly parallel, fallback
        if (Mathf.Abs(det) < 0.001f)
        {
            return currentPos + perp1 * offset1;
        }

        Vector2 diff = line2Start - line1Start;
        float t = diff.Cross(dir2) / det;

        Vector2 intersection = line1Start + dir1 * t;

        // Clamp extreme corners
        if (intersection.DistanceTo(currentPos) > 30.0f)
        {
            // Fallback to non-intersecting point avoiding extreme spikes
            return currentPos + perp1 * offset1;
        }

        return intersection;
    }

    /// <summary>
    /// Determines the canonical direction of a segment between two nodes.
    /// This ensures we always calculate offsets based on a consistent direction,
    /// regardless of which way the bus line travels the segment.
    /// </summary>
    public static bool IsCanonicalDirection(RoadNode nodeA, RoadNode nodeB)
    {
        // First compare X, then Y as tie-breaker
        if (Mathf.Abs(nodeA.GlobalPosition.X - nodeB.GlobalPosition.X) > 0.001f)
        {
            return nodeA.GlobalPosition.X < nodeB.GlobalPosition.X;
        }
        return nodeA.GlobalPosition.Y < nodeB.GlobalPosition.Y;
    }
}

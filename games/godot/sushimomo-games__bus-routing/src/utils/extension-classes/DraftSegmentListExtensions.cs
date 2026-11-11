using Godot;
using System.Collections.Generic;

/// <summary>
/// Provides validation extension methods for lists of draft segments.
/// </summary>
public static class DraftSegmentListExtensions
{
    /// <summary>
    /// Checks if an edge between two road nodes already exists in the list of draft segments.
    /// </summary>
    public static bool DoesEdgeExistBetween(this List<DraftSegment> draftSegments, RoadNode nodeA, RoadNode nodeB)
    {
        foreach (var segment in draftSegments)
        {
            if (segment.Nodes.Count < 2) continue;

            for (int i = 0; i < segment.Nodes.Count - 1; i++)
            {
                var n1 = segment.Nodes[i];
                var n2 = segment.Nodes[i + 1];

                if ((n1 == nodeA && n2 == nodeB) || (n1 == nodeB && n2 == nodeA))
                {
                    return true;
                }
            }
        }
        return false;
    }

    /// <summary>
    /// Checks if a given road node is internal to any of the draft segments.
    /// </summary>
    public static bool IsNodeInternal(this List<DraftSegment> draftSegments, RoadNode node)
    {
        foreach (var segment in draftSegments)
        {
            if (segment.Nodes.Count > 2)
            {
                if (segment.Nodes.Contains(node) && node != segment.FirstNode && node != segment.LastNode)
                {
                    return true;
                }
            }
        }
        return false;
    }
}
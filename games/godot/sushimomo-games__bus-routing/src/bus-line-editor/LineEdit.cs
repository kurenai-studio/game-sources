using Godot;
using System.Collections.Generic;
using System.Linq;

/// <summary>
/// Represents an edit operation that handles the addition or removal of segments in a bus line.
/// </summary>
/// <remarks>
/// This class is used to manage the state of a bus line before and after an edit operation
/// is performed. It allows for the reversion of changes made to the bus line through draft segments,
/// enabling undo functionality in the bus line editor.
/// </remarks>
public partial class LineEdit : AbstractEdit
{
    /// <summary>
    /// Before snapshot of saved state of the bus line segments before the user's edit operation.
    /// </summary>
    private readonly List<List<RoadNode>> _before;
    /// <summary>
    /// After snapshot of saved state of the bus line segments after the user's edit operation.
    /// </summary>
    private readonly List<List<RoadNode>> _after; // does nothing for now, used to redo later

    public LineEdit(List<List<RoadNode>> before, List<List<RoadNode>> after)
    {
        _before = before;
        _after = after;
    }
    /// <summary>
    /// Undoes this edit by restoring the bus line segments to how they were before it.
    /// </summary>
    /// <remarks>
    /// Passes the "before" snapshot to <see cref="BusLineEditor.RestoreSegments"/>,
    /// which replaces the current draft segments with ones rebuilt from it.
    /// </remarks>
    public override void Revert() => BusLineEditor.RestoreSegments(_before);
    /// <summary>
    /// Redoes this edit by restoring the bus line segments to how they were after it.
    /// </summary>
    /// <remarks>
    /// Passes the "after" snapshot to <see cref="BusLineEditor.RestoreSegments"/>,
    /// which replaces the current draft segments with ones rebuilt from it.
    /// </remarks>
    public override void Apply() => BusLineEditor.RestoreSegments(_after);

    /// <summary>
    /// Takes a snapshot of the given draft segments as plain lists of road nodes.
    /// </summary>
    /// <param name="segments">The draft segments to capture.</param>
    /// <returns>
    /// One list of road nodes per segment, in the same order as <paramref name="segments"/>.
    /// </returns>
    /// <remarks>
    /// Each segment's node list is copied, so later changes to the segments do not
    /// affect the snapshot. The road nodes themselves are not copied.
    /// </remarks>
    public static List<List<RoadNode>> Snapshot(IEnumerable<DraftSegment> segments)
    {
        return segments.Select(s => new List<RoadNode>(s.Nodes)).ToList();
    }

}

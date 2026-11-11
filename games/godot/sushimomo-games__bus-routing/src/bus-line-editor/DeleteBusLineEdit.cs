using Godot;

/// <summary>
/// A state object for a finalized bus line deleted from the bus line list.
/// </summary>
/// <remarks>
/// The inverse of <see cref="FinalizeBusLineEdit"/>: reverting restores the
/// detached bus line (see <see cref="BusLine.Detach"/>) at its original position
/// and takes its color back out of the pool.
/// </remarks>
public partial class DeleteBusLineEdit : FinalizeBusLineEdit
{
    public DeleteBusLineEdit(BusLine line, int index)
    {
        AddToGroup(line);
        _indices[line] = index;
    }

    /// <summary>
    /// Re-adds the deleted bus line to the level, the bus line list, and the color pool.
    /// </summary>
    public override void Revert() => Restore();

    /// <summary>
    /// Frees the detached bus lines once the delete can no longer be undone.
    /// </summary>
    public override void OnDiscarded()
    {
        foreach (var line in _group)
        {
            if (GodotObject.IsInstanceValid(line) && !LevelState.AllBusLines.Contains(line))
                line.QueueFree();
        }
    }
}

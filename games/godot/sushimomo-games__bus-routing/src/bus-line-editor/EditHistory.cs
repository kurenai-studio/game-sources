using Godot;
using System.Collections.Generic;

/// <summary>
/// A tracking system for edits made via the bus line editor tool.
/// </summary>
/// <remarks>
/// The edit history tracks edits through a linked list with additions/removals at the tail and the head.
/// </remarks>
public partial class EditHistory
{
    /// <summary>
    /// The maximum amount of edits that will be tracked.
    /// </summary>
    private const int MaxHistory = 50;

    /// <summary>
    /// A read only stack for storing the descendants of the AbstractEdit class.
    /// </summary>
    private readonly LinkedList<AbstractEdit> _undo = new();

    /// <summary>
    /// Gets a value indicating whether there are any actions available in the history stack to undo.
    /// </summary>
    /// <value>
    /// <c>true</c> if the history stack contains at least one item; otherwise, <c>false</c>.
    /// </value>
    public bool CanUndo => _undo.Count > 0;

    /// <summary>
    /// Calls the Clear() method on the linked list
    /// <summary>
    public void Clear()
    {
        foreach (var edit in _undo) edit.OnDiscarded();
        _undo.Clear();
    }

    /// <summary>
    /// LogEdit adds an edit at the end of the linked list.
    /// </summary>
    /// <remarks>
    /// If the size of the linked list is greater than 50 after adding the most recent edit,
    /// it removes the oldest element in the list.
    /// </remarks>
    /// <param name="edit"></param>
    public void LogEdit(AbstractEdit edit)
    {
        _undo.AddLast(edit);

        if (_undo.Count > MaxHistory)
        {
            _undo.First.Value.OnDiscarded();
            _undo.RemoveFirst();

            foreach (var e in _undo)
            {
                GD.Print("[DEBUG - Editor] Edit in history: " + e.GetType().Name);
            }
            GD.Print("[DEBUG - Editor] number of edits in history: " + _undo.Count);
        }
    }
    
    /// <summary>
    /// Reverts the last player action in the undo history.
    /// </summary>
    /// <remarks>
    /// This method checks <see cref="CanUndo"/> before proceeding.
    /// If there are no changes to revert, the method returns.
    /// Takes the last value, removes it from the list,
    /// then calls its <see cref="AbstractEdit.Revert()"/> 
    /// </remarks>
    public void Undo()
    {
        if (!CanUndo) { return; }

        AbstractEdit edit = _undo.Last.Value;

        // Don't revert a stop while a line is being drawn: the draft segments may reference it.
        if (edit is BusStopEdit && BusLineEditor.BusLineInProgress != null) { return; }

        _undo.RemoveLast();
        edit.Revert();
        GD.Print("[DEBUG - Editor] Undoing edit: " + edit.GetType().Name);
        GD.Print("[DEBUG - Editor] number of edits in history: " + _undo.Count);
    }
}

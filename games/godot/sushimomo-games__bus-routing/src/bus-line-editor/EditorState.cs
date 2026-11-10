using Godot;
using System.Collections.Generic;

/// <summary>
/// Represents all possible states that the bus line editor can be in.
/// </summary>
public enum EditorTool
{
    None,
    NewBusLine
}

/// <summary>
/// Represents the steps involved in creating a new busLine.
/// </summary>
public enum BusLineCreationStep
{
    NotCreating,
    AddingFirstStop,
    AddingSubsequentStops,
    PausedCreation,
    BeginningEdit,
    ContinuingEdit
}

/// <summary>
/// Holds the current state of the bus line editor and routes.
/// </summary>
public partial class EditorState : Node
{
    private static BusLineCreationStep? _currentBusLineCreationStep = BusLineCreationStep.NotCreating;
    public static BusLineCreationStep? CurrentBusLineCreationStep 
    { 
        get => _currentBusLineCreationStep; 
        set => _currentBusLineCreationStep = value; 
    }

    private static EditorTool _activeTool = EditorTool.None;
    public static EditorTool ActiveTool
    {
        get => _activeTool;
        set
        {
            _activeTool = value;
            if (_activeTool == EditorTool.NewBusLine)
            {
                CurrentBusLineCreationStep = BusLineCreationStep.AddingFirstStop;
            }
            else
            {
                CurrentBusLineCreationStep = BusLineCreationStep.NotCreating;
            }
        }
    }

    /// <summary>
    /// The shared undo history for the bus line editor.
    /// Edits are added with <see cref="EditHistory.LogEdit"/>.
    /// Edits are reverted with <see cref="EditHistory.Undo"/>.
    /// </summary>
    public static EditHistory History { get; } = new();

    /// <summary>
    /// The undo history for the bus line currently being drawn or edited.
    /// Holds only <see cref="LineEdit"/>s and is emptied when the line is finished or canceled.
    /// </summary>
    public static EditHistory DraftHistory { get; } = new();

    /// <summary>
    /// The busLine currently selected in the editor for inspection.
    /// </summary>
    public static BusLine SelectedBusLine { get; set; }

    public static RoadNode HoveredNode { get; set; }
    public static bool IsEditingFromStart { get; set; }

    /// <summary>
    /// Keeps track of all open windows, keyed by their ID. Prevents multiple
    /// of the same window from being opened.
    /// </summary>
    public static Dictionary<uint, InfoWindow> OpenWindows { get; } = new();
}
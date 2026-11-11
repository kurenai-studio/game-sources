using Godot;
using System.Collections.Generic;
using System.Linq;
using static EditorState;
using static LevelState;
using static LineFactory;
using static Path;
using static BusLineCreationStep;

public partial class BusLineEditor : Node
{
    private static Line2D _mouseTrackingLine { get; set; }
    public static Line2D MouseTrackingLine => _mouseTrackingLine;

    /// <summary>
    /// The bus line that is currently being created or edited.
    /// </summary>
    private static BusLine _busLineInProgress;
    public static BusLine BusLineInProgress => _busLineInProgress;

    /// <summary>
    /// Tracks which disjointed segment the user is actively drawing from.
    /// </summary>
    private static DraftSegment _activeSegment;

    /// <summary>
    /// Tracks all the (disjointed) segments that make up the bus line currently
    /// being created or edited. Each segment is a temporary representation of
    /// a portion of the bus line, allowing for flexible editing and
    /// visualization before finalizing the route.
    /// </summary>
    public static List<DraftSegment> DraftLineSegments { get; set; } = [];
    private static bool _isEditingFromStart;
    public static bool IsEditingFromStart => _isEditingFromStart;
    private static Label _creatingNewLineLabel;

    public static bool IsInEditingMode { get; private set; }

    /// <summary>
    /// Obtains the road node to begin the the mouse tracking from, and what
    /// color the line should be drawn in.
    /// </summary>
    /// <param name="node">Starting node for the mouse tracking line</param>
    /// <param name="color">Color for the mouse tracking line</param>
    private static void BeginMouseTrackingLineAt(RoadNode node, Color color)
    {
        _mouseTrackingLine = CreateLineAt(node.GlobalPosition);
        _mouseTrackingLine.DefaultColor = color;
        CurrentLevel.AddChild(_mouseTrackingLine);
    }

    /// <summary>
    /// Draws a line that follows the user's cursor, providing visual feedback
    /// during the bus line creation process. This method is called every
    /// frame while the user is actively creating a bus line, allowing them to
    /// see where the next segment will be drawn as they move the mouse.
    /// <param name="mousePosition">The current position of the mouse in the game world.</param>
    public static void DrawMouseTrackingLine(Vector2 mousePosition)
    {
        if (CurrentBusLineCreationStep != AddingSubsequentStops && CurrentBusLineCreationStep != ContinuingEdit)
            return;

        if (MouseTrackingLine == null || _activeSegment == null)
            return;

        var activeNode = _isEditingFromStart ? _activeSegment.FirstNode : _activeSegment.LastNode;

        Color targetColor = _busLineInProgress.Color;

        if (HoveredNode != null && HoveredNode != activeNode)
        {
            if (DraftLineSegments.DoesEdgeExistBetween(activeNode, HoveredNode) || !activeNode.Neighbors.Contains(HoveredNode))
            {
                targetColor = new Color(1.0f, 0.0f, 0.0f, 0.5f); 
            }
        }

        MouseTrackingLine.DefaultColor = targetColor;

        if (MouseTrackingLine.GetPointCount() < 2)
            MouseTrackingLine.AddPoint(mousePosition);
        else
            MouseTrackingLine.SetPointPosition(MouseTrackingLine.GetPointCount() - 1, mousePosition);
    }

    /// <summary>
    /// Starts a new draft segment for the bus line creation process,
    /// beginning at the specified start node.This method is called when the
    /// user clicks on a road node.
    /// </summary>
    /// <param name="startNode">Node to begin the segment at</param>
    public static void StartNewSegment(RoadNode startNode)
    {
        if (startNode == null || _busLineInProgress == null) return;
        
        var newSegment = new DraftSegment(startNode, _busLineInProgress);
        _busLineInProgress.AddChild(newSegment); // Keeps it grouped visually under the bus line node
        
        DraftLineSegments.Add(newSegment);
        _activeSegment = newSegment;
    }

    /// <summary>
    /// Continues the bus line creation process by adding a new node to the
    /// currently active draft segment.
    /// </summary>
    /// <param name="nextNode">The next node to add to the active segment.</param>
    public static void ContinueBusLineCreation(RoadNode nextNode)
    {
        if (_activeSegment == null) return;

        var activeNode = _isEditingFromStart ? _activeSegment.FirstNode : _activeSegment.LastNode;
        if (activeNode == nextNode) return;

        // Prevents drawing over ANY existing segment, stopping K-turns entirely.
        if (DraftLineSegments.DoesEdgeExistBetween(activeNode, nextNode))
        {

            GD.Print("Invalid route: Cannot traverse the same road twice.");
            ErrorMessage errorMessage = CurrentLevel.GetNode<ErrorMessage>(ErrorMessageNode);
            errorMessage.DisplayMessage("Cannot route a bus over the same road twice.");
            return; 
        }

        if (!activeNode.Neighbors.Contains(nextNode))
        {
            // Cache whether we are Creating or Editing
            var previousStep = CurrentBusLineCreationStep;

            // This safely terminates the line visual, but overrides state to PausedCreation
            FinalizeDraftSegment(); 

            // Restore the correct active mode
            CurrentBusLineCreationStep = previousStep;

            Record(() => StartNewSegment(nextNode));
            _isEditingFromStart = false;
            BeginMouseTrackingLineAt(nextNode, _busLineInProgress.Color);
            return;
        }

        Record(() =>
        {
            if (_isEditingFromStart)
                _activeSegment.Prepend(nextNode);
            else
                _activeSegment.Append(nextNode);
            CheckAndMergeSegments();
        });

        var newActiveNode = _isEditingFromStart ? _activeSegment.FirstNode : _activeSegment.LastNode;
        
        _mouseTrackingLine?.QueueFree();
        BeginMouseTrackingLineAt(newActiveNode, _busLineInProgress.Color);
    }

    /// <summary>
    /// Finalizes the bus line creation process, performing validation checks,
    /// either committing the new bus line or cleaning up if validation fails.
    /// This method is called when the user clicks the "End Bus Line" button.
    /// </summary>
    public static void FinalizeBusLineCreation()
    {
        ErrorMessage errorMessage = CurrentLevel.GetNode<ErrorMessage>(ErrorMessageNode);

        if (DraftLineSegments.Count > 1)
        {
            errorMessage.DisplayMessage("Connect all route segments before finalizing.");
            return;
        }

        if (DraftLineSegments.Count == 0 || DraftLineSegments[0].Nodes.Count < 2)
        {
            errorMessage.DisplayMessage("BusLine must have at least 2 stops");
            CleanupFailedBusLine();
            return;
        }

        _busLineInProgress.SetPath(DraftLineSegments[0].Nodes);

        DraftLineSegments[0].QueueFree();
        DraftLineSegments.Clear();

        RoadNode firstNode = _busLineInProgress.Path[0];
        RoadNode lastNode = _busLineInProgress.Path[^1];

        if (firstNode is not BusStop || lastNode is not BusStop)
        {
            errorMessage.DisplayMessage("BusLine must start and end at a bus stop");
            CleanupFailedBusLine();
        }
        else
        {
            LevelState.AllBusLines.Add(_busLineInProgress);
            History.LogEdit(new FinalizeBusLineEdit(_busLineInProgress));
            RefreshAllBusLineVisuals();
            
            ResetState();
        }
    }

    /// <summary>
    /// Cleans up the current bus line in progress if the creation process
    /// fails due to validation errors (e.g., not enough stops, not
    /// starting/ending at bus stops). This method returns the bus line's color
    /// to the pool and frees the temporary bus line.
    /// </summary>
    private static void CleanupFailedBusLine()
    {
        var busLineInProgressColor = new KeyValuePair<string, Color>
        (
            _busLineInProgress.ColorName,
            _busLineInProgress.Color
        );
        foreach (var segment in DraftLineSegments)
            segment.QueueFree();
        DraftLineSegments.Clear();
        ReturnBusLineColor(busLineInProgressColor);
        _busLineInProgress.QueueFree();
        ResetState();
    }

    /// <summary>
    /// Finalizes the current draft segment, removing the mouse tracking line
    /// and pauses bus line creation until the user clicks on a node to resume.
    /// This method is called when the user completes a segment.
    /// </summary>
    public static void FinalizeDraftSegment()
    {
        if (_busLineInProgress == null) return;

        CurrentBusLineCreationStep = PausedCreation;
        _mouseTrackingLine?.QueueFree();
        _mouseTrackingLine = null;
    }

    public static bool CanResumeBusLineCreation(RoadNode clickedNode)
    {
        if (_busLineInProgress == null || CurrentBusLineCreationStep != PausedCreation)
            return false;

        // Loop through ALL draft segments to see if we clicked an endpoint
        foreach (var segment in DraftLineSegments)
        {
            if (clickedNode == segment.FirstNode)
            {
                _activeSegment = segment;
                _isEditingFromStart = true;
                CurrentBusLineCreationStep = AddingSubsequentStops;
                BeginMouseTrackingLineAt(clickedNode, _busLineInProgress.Color);
                return true;
            }
            else if (clickedNode == segment.LastNode)
            {
                _activeSegment = segment;
                _isEditingFromStart = false;
                CurrentBusLineCreationStep = AddingSubsequentStops;
                BeginMouseTrackingLineAt(clickedNode, _busLineInProgress.Color);
                return true;
            }
        }

        return false;
    }

    /// <summary>
    /// Starts a completely new disjointed segment while the editor is in a paused state.
    /// </summary>
    public static void BeginNewDisjointedSegment(RoadNode startNode)
    {
        if (_busLineInProgress == null) return;

        if (DraftLineSegments.IsNodeInternal(startNode))
        {
            GD.Print("Cannot branch off the middle of an existing route.");
            return; 
        }

        GD.Print($"[DEBUG - Editor] Jumping to start new segment at {startNode.Name}");
        
        CurrentBusLineCreationStep = AddingSubsequentStops;
        _isEditingFromStart = false; 

        Record(() => StartNewSegment(startNode));
        _activeSegment = DraftLineSegments.Last();

        BeginMouseTrackingLineAt(startNode, _busLineInProgress.Color);
    }

    public static void StartBusLineEdit(BusLine busLine, RoadNode clickedNode)
    {
        DraftHistory.Clear();
        IsInEditingMode = true;
        CurrentBusLineCreationStep = ContinuingEdit;
        GD.Print($"Starting to edit busLine: {busLine.ColorName}");

        _busLineInProgress = new BusLine
        {
            ColorName = busLine.ColorName,
            Color = busLine.Color
        };
        CurrentLevel.AddChild(_busLineInProgress);
        
        // Push the existing path into a draft segment so it can be edited
        StartNewSegment(busLine.Path[0]);
        for (int i = 1; i < busLine.Path.Count; i++)
        {
            DraftLineSegments[0].Append(busLine.Path[i]);
        }

        _activeSegment = DraftLineSegments[0];
        _isEditingFromStart = _activeSegment.FirstNode == clickedNode;

        BeginMouseTrackingLineAt(clickedNode, busLine.Color);
    }

    public static void FinalizeBusLineEdit()
    {
        var editedBusLine = SelectedBusLine;
        ErrorMessage errorMessage = CurrentLevel.GetNode<ErrorMessage>(ErrorMessageNode);

        if (DraftLineSegments.Count > 1)
        {
            errorMessage.DisplayMessage("Connect all route segments before finalizing edit.");
            return; 
        }

        // Apply the modified draft segment to the temporary bus line path
        _busLineInProgress.SetPath(DraftLineSegments[0].Nodes);

        var firstNode = _busLineInProgress.Path.First();
        var lastNode = _busLineInProgress.Path.Last();

        if (_busLineInProgress.Path.Count < 2)
        {
            errorMessage.DisplayMessage("BusLine must have at least 2 stops");
        }
        else if (firstNode is not BusStop || lastNode is not BusStop)
        {
            errorMessage.DisplayMessage("BusLine must start and end at a bus stop");
        }
        else
        {
            GD.Print($"BusLine edit successful. New path: {string.Join(", ", _busLineInProgress.Path.Select(node => node.Name))}.");
            SelectedBusLine.SetPath(_busLineInProgress.Path);
            UpdateAllHouseStatuses();
        }
        
        // Clean up the draft segments
        DraftLineSegments[0].QueueFree();
        DraftLineSegments.Clear();
        
        LevelState.RefreshAllBusLineVisuals();
        _busLineInProgress.QueueFree(); // Clean up the temporary editing duplicate
        _busLineInProgress = null;
        ResetState();
    }

    /// <summary>
    /// Resets the editor state to its default values, clearing any temporary
    /// data and hiding UI elements related to bus line creation or editing.
    /// This method is called after a bus line creation or edit process is
    /// completed or canceled.
    /// </summary>
    public static void ResetState()
    {
        IsInEditingMode = false;
        CurrentLevel.GetNode<Label>(LineEditorStatusLabelNode).Visible = false;
        CurrentLevel.GetNode<Button>(EndBusLineButtonNode).Visible = false;
        _busLineInProgress = null;
        _activeSegment = null;
        _mouseTrackingLine?.QueueFree();
        _mouseTrackingLine = null;
        EditorState.ActiveTool = EditorTool.None;
        _isEditingFromStart = false;
        DraftHistory.Clear();
    }

    /// <summary>
    /// Begins a new bus line creation process starting from the specified node.
    /// This method initializes the necessary state and visual elements for the user to start defining a new bus route.
    /// </summary>
    /// <param name="startNode">The node from which to start the bus line creation.</param>
    public static void StartBusLineCreation(RoadNode startNode)
    {
        DraftHistory.Clear();
        _creatingNewLineLabel = CurrentLevel.GetNode<Label>(LineEditorStatusLabelNode);
        CurrentBusLineCreationStep = AddingSubsequentStops;
        _isEditingFromStart = false; 
        _busLineInProgress = new BusLine();
        CurrentLevel.AddChild(_busLineInProgress);
        
        _creatingNewLineLabel.Text = $"● Creating {_busLineInProgress.ColorName} Line";

        StartNewSegment(startNode);
        _activeSegment = DraftLineSegments.Last();

        BeginMouseTrackingLineAt(startNode, _busLineInProgress.Color);
    }

    /// <summary>
    /// Checks all draft segments to see if any can be merged together.
    /// </summary>
    private static void CheckAndMergeSegments()
    {
        var segments = DraftLineSegments;
        
        for (int i = 0; i < segments.Count; i++)
        {
            for (int j = i + 1; j < segments.Count; j++)
            {
                if (segments[i].CanMergeWith(segments[j]))
                {
                    GD.Print($"[DEBUG - Editor] Collision detected between segment {i} and {j}!");
                    
                    var segmentToAbsorb = segments[j];
                    
                    // Check if EITHER the absorbed segment or the absorbing segment was active
                    bool wasActive = _activeSegment == segmentToAbsorb || _activeSegment == segments[i];
                    
                    segments[i].MergeWith(segmentToAbsorb);
                    
                    segmentToAbsorb.QueueFree();
                    segments.RemoveAt(j);
                    
                    if (wasActive) 
                    {
                        FinalizeDraftSegment();
                    }
                    
                    return; 
                }
            }
        }
    }

    /// <summary>
    /// Replaces the current draft segments with ones rebuilt from a snapshot,
    /// then repairs the editor's cursor state so drawing can continue.
    /// </summary>
    /// <param name="snapshot">
    /// The segments to restore, one list of road nodes per segment, as produced
    /// by <see cref="LineEdit.Snapshot"/>. Empty lists are skipped.
    /// </param>
    /// <remarks>
    /// Frees every existing draft segment and the mouse tracking line, then
    /// creates new <see cref="DraftSegment"/> instances as children of the bus
    /// line in progress. The last restored segment becomes the active segment,
    /// editing direction is reset to the end of the segment, and the creation
    /// step is set to <c>PausedCreation</c>. No mouse tracking line is started,
    /// so nothing follows the cursor until the user clicks a segment endpoint.
    /// </remarks>
    public static void RestoreSegments(List<List<RoadNode>> snapshot)
    {
        if (_busLineInProgress == null) return;

        foreach (var seg in DraftLineSegments)
            seg.QueueFree();
        DraftLineSegments.Clear();
        _mouseTrackingLine?.QueueFree();
        _mouseTrackingLine = null;

        foreach (var nodes in snapshot)
        {
            if (nodes.Count == 0) continue;

            var seg = new DraftSegment(nodes[0], _busLineInProgress);
            _busLineInProgress.AddChild(seg);
            for (int i = 1; i < nodes.Count; i++)
                seg.Append(nodes[i]);
            DraftLineSegments.Add(seg);
        }

        _activeSegment = DraftLineSegments.LastOrDefault();
        _isEditingFromStart = false;
        
        if (_activeSegment != null)
            CurrentBusLineCreationStep = PausedCreation;
    }
    
    /// <summary>
    /// Runs a change to the draft segments and logs it to the undo history as
    /// a before and after snapshot.
    /// </summary>
    /// <param name="mutate">
    /// The action that modifies <see cref="DraftLineSegments"/>. It runs exactly
    /// once between the two snapshots.
    /// </param>
    /// <remarks>
    /// All user-driven changes to the draft segments should go through this
    /// method so that they can be undone. Setup code that creates the initial
    /// segment, such as <see cref="StartBusLineCreation"/> and
    /// <see cref="StartBusLineEdit"/>, deliberately does not, so the first
    /// segment of a session is not undoable.
    /// </remarks>
    private static void Record(System.Action mutate)
    {
        var before = LineEdit.Snapshot(DraftLineSegments);
        GD.Print("[DEBUG - Editor] Recording edit: " + before.Count + " segments before, " + DraftLineSegments.Sum(s => s.Nodes.Count) + " nodes total.");
        mutate();
        var after = LineEdit.Snapshot(DraftLineSegments);
        GD.Print("[DEBUG - Editor] Recording edit: " + after.Count + " segments after, " + DraftLineSegments.Sum(s => s.Nodes.Count) + " nodes total.");
        DraftHistory.LogEdit(new LineEdit(before, after));
    }

}
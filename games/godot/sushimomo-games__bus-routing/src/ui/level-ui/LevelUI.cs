using Godot;
using System;
using System.Linq;
using static LevelState;
using static Path;
using static EditorTool;

/// <summary>
/// The LevelUI class is responsible for managing the user interface elements related to the level, 
/// including bus stop placement and bus line creation. Err maybe it has too much responsbility.
/// Note: _Process() is not always running.
/// </summary>
public partial class LevelUI : Control
{
    private PackedScene _previewBusStopScene;
    private PackedScene _busStopScene;
    private PackedScene _roadEdgeScene;

    private PreviewBusStop _previewBusStop;
    private Area2D _previewPlacementArea;
    private bool _isValidPlacement = false;
    public bool IsValidPlacement => _isValidPlacement;
    private Camera2D _camera;
    private ErrorMessage _errorMessage;

    private System.Collections.Generic.List<BusStop> _highlightedStops = new();

    public override void _Ready()
    {
        LevelState.LevelUI = this;
        _previewBusStopScene = GD.Load<PackedScene>(PreviewBusStopScene);
        _busStopScene = GD.Load<PackedScene>(BusStopScene);
        _roadEdgeScene = GD.Load<PackedScene>(RoadEdgeScene);
        _camera = GetViewport().GetCamera2D();
        _errorMessage = GetTree().CurrentScene.GetNode<ErrorMessage>
        (
            ErrorMessageNode
        );
    }

    public override void _Process(double delta)
    {
        if (_previewBusStop != null)
        {
            if (!Input.IsMouseButtonPressed(MouseButton.Left))
            {
                GetViewport().GuiCancelDrag();
                CleanupPreview();
                return;
            }

            _previewBusStop.GlobalPosition = _camera.GetGlobalMousePosition();
            _isValidPlacement = _previewPlacementArea.HasOverlappingAreas()
            && !_previewBusStop.IntersectionDetector.HasOverlappingAreas();

            var color = _isValidPlacement ? Colors.LightGreen : Colors.Red;
            _previewBusStop.Modulate = color;

            UpdateHighlightedBusStops();
        }
    }

    /// <summary>
    /// Highlights bus stops within the walk radius of the preview bus stop.
    /// This gives visual feedback to the player about if their bus stop placement
    /// is able to be used for transfers (i.e. are people willing to walk from
    /// one stop to another?).
    /// </summary>
    private void UpdateHighlightedBusStops()
    {
        foreach (var stop in _highlightedStops)
        {
            if (IsInstanceValid(stop))
            {
                stop.Modulate = Colors.White;
            }
        }
        _highlightedStops.Clear();

        var walkRadius = _previewBusStop.WalkRadius;
        foreach (var area in walkRadius.GetOverlappingAreas())
        {
            if (area.GetParent() is BusStop busStop)
            {
                busStop.Modulate = Colors.LightGreen;
                _highlightedStops.Add(busStop);
            }
        }
    }

    /// <summary>
    /// Determines if the dragged data can be dropped here.
    /// </summary>
    public override bool _CanDropData(Vector2 atPosition, Variant data)
    {
        if (data.AsString() == "BusStop")
        {
            if (_previewBusStop == null)
            {
                _previewBusStop = _previewBusStopScene.Instantiate<PreviewBusStop>();
                CurrentLevel.AddChild(_previewBusStop);
                _previewPlacementArea = _previewBusStop.GetChild<Area2D>(1);
                SetProcess(true);
            }
            return true;
        }
        return false;
    }

    /// <summary>
    /// Handles the drop of the bus stop onto a valid road edge.
    /// </summary>
    public override void _DropData(Vector2 atPosition, Variant data)
    {
        if (_isValidPlacement)
        {
            var busStopInstance = _busStopScene.Instantiate<BusStop>();
            var overlappingArea = _previewPlacementArea.GetOverlappingAreas().FirstOrDefault();
            if (overlappingArea is RoadEdge roadEdge)
            {
                CreateBusStopOnEdge(roadEdge, busStopInstance);
            }
        }
        CleanupPreview();
    }

    /// <summary>
    /// Cleans up the preview bus stop and resets the state after a drop operation.
    /// This includes removing the preview bus stop, clearing highlighted stops, and stopping _Process().
    /// </summary>
    private void CleanupPreview()
    {
        if (_previewBusStop != null)
        {
            foreach (var stop in _highlightedStops)
            {
                if (IsInstanceValid(stop))
                {
                    stop.Modulate = Colors.White;
                }
            }
            _highlightedStops.Clear();

            _previewBusStop.QueueFree();
            _previewBusStop = null;
            _previewPlacementArea = null;
            _isValidPlacement = false;
            SetProcess(false);
        }
    }

    /// <summary>
    /// Splits the given road edge into two edges at the bus stop's position.
    /// Used when creating a bus stop on an existing road edge.
    /// </summary>
    private void SplitEdge(RoadEdge roadEdge, BusStop busStop)
    {
        var edge1 = _roadEdgeScene.Instantiate<RoadEdge>();
        var edge2 = _roadEdgeScene.Instantiate<RoadEdge>();
        CurrentLevel.AddChild(edge1);
        CurrentLevel.AddChild(edge2);
        edge1.SetEndpoints(roadEdge.NodeA, busStop);
        edge2.SetEndpoints(busStop, roadEdge.NodeB);
        roadEdge.QueueFree();
    }

    /// <summary>
    /// Creates a bus stop on the specified road edge at the mouse position.
    /// </summary>
    private void CreateBusStopOnEdge(RoadEdge roadEdge, BusStop busStop)
    {
        if (Budget < Cost.BusStopPlacement)
        {
            _errorMessage.DisplayMessage("Insufficient budget to place bus stop.");
            return;
        }

        var budgetBefore = Budget;

        Budget -= Cost.BusStopPlacement;

        Vector2 p1 = roadEdge.NodeA.GlobalPosition;
        Vector2 p2 = roadEdge.NodeB.GlobalPosition;
        Vector2 mousePosition = _camera.GetGlobalMousePosition();
        Vector2 projectedPoint = Geometry2D.GetClosestPointToSegment(mousePosition, p1, p2);

        CurrentLevel.AddChild(busStop);
        LevelState.AllBusStops.Add(busStop);
        busStop.GlobalPosition = projectedPoint;


        var nodeA = roadEdge.NodeA;
        var nodeB = roadEdge.NodeB;

        SplitEdge(roadEdge, busStop);

        nodeA.RemoveNeighbor(nodeB);
        nodeB.RemoveNeighbor(nodeA);

        nodeA.AddNeighbor(busStop);
        busStop.AddNeighbor(nodeA);
        nodeB.AddNeighbor(busStop);
        busStop.AddNeighbor(nodeB);

        EditorState.History.LogEdit(new BusStopEdit(true, budgetBefore, projectedPoint, nodeA, nodeB, busStop));
    }

}

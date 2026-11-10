using Godot;
using System.Linq;

public partial class MouseTracker : Node
{
    private Line2D _mouseTrackingLine;

    public void StartTracking(RoadNode startNode, Color color)
    {
        _mouseTrackingLine = LineFactory.CreateLineAt(startNode.GlobalPosition);
        _mouseTrackingLine.DefaultColor = color;
        AddChild(_mouseTrackingLine); // Keeps it grouped cleanly under this node
        SetProcess(true);
    }

    public void StopTracking()
    {
        SetProcess(false);
        _mouseTrackingLine?.QueueFree();
        _mouseTrackingLine = null;
    }

    public override void _Process(double delta)
    {
        if (_mouseTrackingLine == null) return;

        // Pull active state from your static editor safely
        var activeSegment = BusLineEditor.DraftLineSegments.LastOrDefault();
        if (activeSegment == null || BusLineEditor.BusLineInProgress == null) return;

        var activeNode = BusLineEditor.IsEditingFromStart ? activeSegment.FirstNode : activeSegment.LastNode;
        Color targetColor = BusLineEditor.BusLineInProgress.Color;

        // Handle error coloring
        if (EditorState.HoveredNode != null && EditorState.HoveredNode != activeNode)
        {
            if (BusLineEditor.DraftLineSegments.DoesEdgeExistBetween(activeNode, EditorState.HoveredNode) ||
                !activeNode.Neighbors.Contains(EditorState.HoveredNode))
            {
                targetColor = new Color(1.0f, 0.0f, 0.0f, 0.5f);
            }
        }

        _mouseTrackingLine.DefaultColor = targetColor;

        // Update position dynamically
        Vector2 mousePosition = GetViewport().GetMousePosition();
        if (_mouseTrackingLine.GetPointCount() < 2)
            _mouseTrackingLine.AddPoint(mousePosition);
        else
            _mouseTrackingLine.SetPointPosition(_mouseTrackingLine.GetPointCount() - 1, mousePosition);
    }
}
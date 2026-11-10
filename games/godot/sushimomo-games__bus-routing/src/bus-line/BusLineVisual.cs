using Godot;
using System.Collections.Generic;
using System.Linq;
using static PathGeometry;

public partial class BusLineVisual : Node2D
{
    private BusLine _busLine;
    private Line2D _line;
    private Line2D _highlightLine;
    private Tween _highlightTween;

    public float LineWidth { get; set; } = 8.0f;
    public float LineSpacing { get; set; } = 8.0f;

    public BusLineVisual(BusLine busLine)
    {
        _busLine = busLine;
        _line = new Line2D
        {
            Width = LineWidth,
            DefaultColor = busLine.Color,
            BeginCapMode = Line2D.LineCapMode.Round,
            EndCapMode = Line2D.LineCapMode.Round,
            JointMode = Line2D.LineJointMode.Round
        };
        AddChild(_line);

        _highlightLine = new Line2D
        {
            Width = LineWidth + 4.0f,
            DefaultColor = busLine.Color.Lightened(0.4f),
            ZIndex = 0,
            Modulate = new Color(1, 1, 1, 0),
            BeginCapMode = Line2D.LineCapMode.Round,
            EndCapMode = Line2D.LineCapMode.Round,
            JointMode = Line2D.LineJointMode.Round
        };
        AddChild(_highlightLine);
    }

    public override void _Ready()
    {
        UpdateVisual();
    }

    /// <summary>
    /// Rebuilds the visual from the default bus line path.
    /// </summary>
    public void UpdateVisual()
    {
        UpdateVisualFromPath(_busLine.Path);
    }

    /// <summary>
    /// NEW: Rebuilds the visual from an explicit, custom path (Perfect for DraftSegments!)
    /// </summary>
    public void UpdateVisualFromPath(List<RoadNode> path)
    {
        _line.ClearPoints();

        if (path == null || path.Count == 0) return;
        if (path.Count == 1)
        {
            _line.AddPoint(path[0].GlobalPosition);
            return;
        }

        for (int i = 0; i < path.Count; i++)
        {
            Vector2 currentPos = path[i].GlobalPosition;

            if (i == 0)
            {
                Vector2 dir = (path[1].GlobalPosition - currentPos).Normalized();
                Vector2 perp = new Vector2(-dir.Y, dir.X);
                float offset = LevelState.CalculateSegmentOffsetAmount(_busLine, path[0], path[1], LineSpacing);
                _line.AddPoint(currentPos + perp * offset);
            }
            else if (i == path.Count - 1)
            {
                Vector2 dir = (currentPos - path[i - 1].GlobalPosition).Normalized();
                Vector2 perp = new Vector2(-dir.Y, dir.X);
                float offset = LevelState.CalculateSegmentOffsetAmount(_busLine, path[i - 1], path[i], LineSpacing);
                _line.AddPoint(currentPos + perp * offset);
            }
            else
            {
                AddPointsAtIntersection(i, path);
            }
        }
    }

    private void AddPointsAtIntersection(int nodeIndex, List<RoadNode> path)
    {
        Vector2 currentPos = path[nodeIndex].GlobalPosition;
        Vector2 prevPos = path[nodeIndex - 1].GlobalPosition;
        Vector2 nextPos = path[nodeIndex + 1].GlobalPosition;

        Vector2 dirBefore = (currentPos - prevPos).Normalized();
        Vector2 dirAfter = (nextPos - currentPos).Normalized();

        Vector2 perpBefore = new Vector2(-dirBefore.Y, dirBefore.X);
        Vector2 perpAfter = new Vector2(-dirAfter.Y, dirAfter.X);

        float offsetBefore = LevelState.CalculateSegmentOffsetAmount(_busLine, path[nodeIndex - 1], path[nodeIndex], LineSpacing);
        float offsetAfter = LevelState.CalculateSegmentOffsetAmount(_busLine, path[nodeIndex], path[nodeIndex + 1], LineSpacing);

        bool isCollinear = Mathf.Abs(dirBefore.Cross(dirAfter)) < 0.001f;
        bool sameOffset = Mathf.Abs(offsetBefore - offsetAfter) < 0.001f;

        if (isCollinear)
        {
            if (sameOffset)
            {
                _line.AddPoint(currentPos + perpBefore * offsetBefore);
            }
            else
            {
                _line.AddPoint(currentPos + perpBefore * offsetBefore);
                _line.AddPoint(currentPos + perpAfter * offsetAfter);
            }
        }
        else
        {
            Vector2 intersection = CalculateIntersection(prevPos, dirBefore, offsetBefore, currentPos, dirAfter, offsetAfter, currentPos);
            _line.AddPoint(intersection);
        }
    }

    public void AppendPoint(Vector2 position) => UpdateVisual();
    public void PrependPoint(Vector2 position) => UpdateVisual();
    public void ClearPoints() => _line.ClearPoints();
    public Line2D GetLine2D() => _line;

    /// <summary>
    /// Highlights a specific segment of the bus line with a glow overlay.
    /// </summary>
    public void HighlightSegment(RoadNode nodeA, RoadNode nodeB)
    {
        _highlightLine.ClearPoints();

        Vector2 posA = nodeA.GlobalPosition;
        Vector2 posB = nodeB.GlobalPosition;

        Vector2 dir = (posB - posA).Normalized();
        Vector2 perp = new Vector2(-dir.Y, dir.X);
        float offset = LevelState.CalculateSegmentOffsetAmount(_busLine, nodeA, nodeB, LineSpacing);

        _highlightLine.AddPoint(posA + perp * offset);
        _highlightLine.AddPoint(posB + perp * offset);

        _highlightTween?.Kill();
        _highlightTween = CreateTween();
        // Fade in alpha
        _highlightTween.TweenProperty(_highlightLine, "modulate", new Color(1, 1, 1, 1), 0.2f)
                       .SetTrans(Tween.TransitionType.Sine)
                       .SetEase(Tween.EaseType.Out);
    }

    /// <summary>
    /// Highlights a sequence of nodes on the bus line.
    /// </summary>
    public void HighlightPath(List<RoadNode> pathNodes)
    {
        if (pathNodes == null || pathNodes.Count < 2) return;

        _highlightLine.ClearPoints();

        for (int i = 0; i < pathNodes.Count; i++)
        {
            Vector2 currentPos = pathNodes[i].GlobalPosition;

            if (i == 0)
            {
                Vector2 dir = (pathNodes[1].GlobalPosition - currentPos).Normalized();
                Vector2 perp = new Vector2(-dir.Y, dir.X);
                float offset = LevelState.CalculateSegmentOffsetAmount(_busLine, pathNodes[0], pathNodes[1], LineSpacing);
                _highlightLine.AddPoint(currentPos + perp * offset);
            }
            else if (i == pathNodes.Count - 1)
            {
                Vector2 dir = (currentPos - pathNodes[i - 1].GlobalPosition).Normalized();
                Vector2 perp = new Vector2(-dir.Y, dir.X);
                float offset = LevelState.CalculateSegmentOffsetAmount(_busLine, pathNodes[i - 1], pathNodes[i], LineSpacing);
                _highlightLine.AddPoint(currentPos + perp * offset);
            }
            else
            {
                AddPointsAtIntersectionForHighlight(i, pathNodes);
            }
        }

        _highlightTween?.Kill();
        _highlightTween = CreateTween();
        _highlightTween.TweenProperty(_highlightLine, "modulate", new Color(1, 1, 1, 1), 0.2f)
                       .SetTrans(Tween.TransitionType.Sine)
                       .SetEase(Tween.EaseType.Out);
    }

    private void AddPointsAtIntersectionForHighlight(int nodeIndex, List<RoadNode> path)
    {
        Vector2 currentPos = path[nodeIndex].GlobalPosition;

        Vector2 prevPos = path[nodeIndex - 1].GlobalPosition;
        Vector2 nextPos = path[nodeIndex + 1].GlobalPosition;

        Vector2 dirBefore = (currentPos - prevPos).Normalized();
        Vector2 dirAfter = (nextPos - currentPos).Normalized();

        Vector2 perpBefore = new Vector2(-dirBefore.Y, dirBefore.X);
        Vector2 perpAfter = new Vector2(-dirAfter.Y, dirAfter.X);

        float offsetBefore = LevelState.CalculateSegmentOffsetAmount(_busLine, path[nodeIndex - 1], path[nodeIndex], LineSpacing);
        float offsetAfter = LevelState.CalculateSegmentOffsetAmount(_busLine, path[nodeIndex], path[nodeIndex + 1], LineSpacing);

        bool isCollinear = Mathf.Abs(dirBefore.Cross(dirAfter)) < 0.001f;
        bool sameOffset = Mathf.Abs(offsetBefore - offsetAfter) < 0.001f;

        if (isCollinear)
        {
            if (sameOffset)
            {
                _highlightLine.AddPoint(currentPos + perpBefore * offsetBefore);
            }
            else
            {
                _highlightLine.AddPoint(currentPos + perpBefore * offsetBefore);
                _highlightLine.AddPoint(currentPos + perpAfter * offsetAfter);
            }
        }
        else
        {
            Vector2 intersection = CalculateIntersection(prevPos, dirBefore, offsetBefore, currentPos, dirAfter, offsetAfter, currentPos);
            _highlightLine.AddPoint(intersection);
        }
    }

    /// <summary>
    /// Fades out the currently glowing highlight overlay segment.
    /// </summary>
    public void ClearHighlight()
    {
        if (_highlightLine.Points.Length == 0) return;

        _highlightTween?.Kill();
        _highlightTween = CreateTween();
        _highlightTween.TweenProperty(_highlightLine, "modulate", new Color(1, 1, 1, 0), 0.2f)
                       .SetTrans(Tween.TransitionType.Sine)
                       .SetEase(Tween.EaseType.Out);
        _highlightTween.TweenCallback(Callable.From(_highlightLine.ClearPoints));
    }
    /* public override void _UnhandledInput(InputEvent @event)
 {
     if (@event is InputEventMouseButton mouse &&
         mouse.Pressed &&
         mouse.ButtonIndex == MouseButton.Left)
     {
         Vector2 mousePos = GetGlobalMousePosition();

         foreach (Vector2 point in _line.Points)
         {
             if (mousePos.DistanceTo(point) < 15)
             {
                 GD.Print($"Bus line {_busLine.ColorName} clicked!");
                 break;
             }
         }
     }
 }*/
    /// This is what makes the buslines actually clickable 
    public override void _UnhandledInput(InputEvent @event)
    {
        if (@event is InputEventMouseButton mouse &&
            mouse.Pressed &&
            mouse.ButtonIndex == MouseButton.Left)
        {
            Vector2 mousePos = GetGlobalMousePosition();

            for (int i = 0; i < _line.Points.Length - 1; i++)
            {
                Vector2 closest =
                    Geometry2D.GetClosestPointToSegment(
                        mousePos,
                        _line.Points[i],
                        _line.Points[i + 1]);

                if (mousePos.DistanceTo(closest) < 10) /// This measures the distance between the segment of the bus lines and the user's mouse click. 
                                                       /// if it is less than 10 pixels away then this function will send the information to the InformationPanel and update the information
                {
                    GD.Print($"Clicked {_busLine.ColorName}");
                    LevelState.InformationPanel.ShowBusLine(_busLine);
                    House.DeselectHouses();
                    return;
                }
            }
        }
    }
}

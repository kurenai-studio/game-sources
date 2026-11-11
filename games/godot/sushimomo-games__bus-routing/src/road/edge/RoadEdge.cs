using Godot;
using System.Collections.Generic;

public partial class RoadEdge : Area2D
{
    private CollisionShape2D _collisionShape;
    public CollisionShape2D CollisionShape => _collisionShape;
    private SegmentShape2D _segmentShape;

    private Line2D _lineVisual;

    public RoadNode NodeA { get; private set; }
    public RoadNode NodeB { get; private set; }

    public Vector2 A
    {
        get => _segmentShape?.A ?? Vector2.Zero;
        set
        {
            if (_segmentShape != null)
            {
                _segmentShape.A = value;
                UpdateLinePoints();
            }
        }
    }

    public Vector2 B
    {
        get => _segmentShape?.B ?? Vector2.Zero;
        set
        {
            if (_segmentShape != null)
            {
                _segmentShape.B = value;
                UpdateLinePoints();
            }
        }
    }

    public float Weight => A.DistanceTo(B);

    public void SetEndpoints(RoadNode nodeA, RoadNode nodeB)
    {
        NodeA = nodeA;
        NodeB = nodeB;

        if (NodeA is BusStop busStopA) { busStopA.ConnectedEdges.Add(this); }
        if (NodeB is BusStop busStopB) { busStopB.ConnectedEdges.Add(this); }

        A = nodeA.GlobalPosition;
        B = nodeB.GlobalPosition;
    }

    public override void _Ready()
    {
        _collisionShape = GetNode<CollisionShape2D>("CollisionShape2D");
        _segmentShape = _collisionShape.Shape as SegmentShape2D;

        _lineVisual = new Line2D
        {
            Width = 10.0f,
            DefaultColor = Colors.SlateGray
        };
        AddChild(_lineVisual);

        LevelState.AllRoadEdges.Add(this);
    }

    /// <summary>
    /// Updates the visual representation of the road edge based on its
    /// endpoints A and B. If the line visual has fewer than 2 points, it
    /// initializes them; otherwise, it updates the existing points to match
    /// the current positions of A and B.
    /// </summary>
    private void UpdateLinePoints()
    {
        if (_lineVisual == null) return;

        if (_lineVisual.Points.Length < 2)
        {
            _lineVisual.ClearPoints();
            _lineVisual.AddPoint(A);
            _lineVisual.AddPoint(B);
        }
        else
        {
            _lineVisual.SetPointPosition(0, A);
            _lineVisual.SetPointPosition(1, B);
        }
    }

    public override void _ExitTree()
    {
        LevelState.AllRoadEdges.Remove(this);
    }
}
using Godot;
using System;

public partial class RoadNode : Node2D
{
    [Export] public Godot.Collections.Array<RoadNode> Neighbors = [];

    public void AddNeighbor(RoadNode neighbor)
    {
        if (!Neighbors.Contains(neighbor))
        {
            Neighbors.Add(neighbor);
        }
    }

    public void RemoveNeighbor(RoadNode neighbor)
    {
        Neighbors.Remove(neighbor);
    }

    public override void _Ready()
    {
        LevelState.AllRoadNodes.Add(this);
    }
}

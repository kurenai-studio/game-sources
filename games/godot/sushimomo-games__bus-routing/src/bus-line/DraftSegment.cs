using System.Collections.Generic;
using System.Linq;
using Godot;

public partial class DraftSegment : Node2D
{
    public List<RoadNode> Nodes { get; private set; }
    private BusLineVisual _visual; // Swap Line2D for BusLineVisual

    public RoadNode FirstNode => Nodes.FirstOrDefault();
    public RoadNode LastNode => Nodes.LastOrDefault();

    public DraftSegment(RoadNode startNode, BusLine associatedBusLine)
    {
        Nodes = [startNode];

        _visual = new BusLineVisual(associatedBusLine);

        AddChild(_visual);
        UpdateVisuals();
    }

    private void UpdateVisuals()
    {
        _visual.UpdateVisualFromPath(Nodes);
    }

    public void Append(RoadNode node)
    {
        Nodes.Add(node);
        UpdateVisuals();
    }

    public void Prepend(RoadNode node)
    {
        Nodes.Insert(0, node);
        UpdateVisuals();
    }

    public new void QueueFree()
    {
        _visual?.QueueFree();
        base.QueueFree();
    }

    public bool CanMergeWith(DraftSegment other)
    {
        // A segment can only merge with another segment if their endpoints touch.
        // This physically prevents T-junctions while allowing self-crossings.
        return FirstNode == other.FirstNode ||
            FirstNode == other.LastNode ||
            LastNode == other.FirstNode ||
            LastNode == other.LastNode;
    }

    public void MergeWith(DraftSegment other)
    {
        if (LastNode == other.FirstNode)
        {
            other.Nodes.RemoveAt(0);
            Nodes.AddRange(other.Nodes);
        }
        else if (FirstNode == other.LastNode)
        {
            other.Nodes.RemoveAt(other.Nodes.Count - 1);
            Nodes.InsertRange(0, other.Nodes);
        }
        else if (LastNode == other.LastNode)
        {
            other.Nodes.RemoveAt(other.Nodes.Count - 1);
            other.Nodes.Reverse();
            Nodes.AddRange(other.Nodes);
        }
        else if (FirstNode == other.FirstNode)
        {
            other.Nodes.RemoveAt(0);
            other.Nodes.Reverse();
            Nodes.InsertRange(0, other.Nodes);
        }

        UpdateVisuals();
    }
}
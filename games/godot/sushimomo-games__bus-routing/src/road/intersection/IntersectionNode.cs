using Godot;

/// <summary>
/// Represents a junction or intersection in the road network.
/// Inherits neighbor management from RoadNode.
/// </summary>


[Tool]
public partial class IntersectionNode : RoadNode
{
    public override void _Process(double delta)
    {
        if (Engine.IsEditorHint())
        {
            QueueRedraw();
        }
    }

    public override void _Draw()
    {
        if (!Engine.IsEditorHint()) return;
        foreach (var neighbor in Neighbors)
        {
            if (neighbor == null) continue;
            Vector2 targetPos = ToLocal(neighbor.GlobalPosition);
            //Replace the 10f with the a constant road width 
            DrawLine(Vector2.Zero, targetPos, new Color("8d7b96"), 10f);
        }
    }
}
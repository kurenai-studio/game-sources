using Godot;
using System;
using static LevelState;
using static BusLineEditor;
using static BusLineCreationStep;
using static EditorState;

/// <summary>
/// This script is to be attached to the root of each level.
/// Handles level initialization and general level management tasks.
/// See also <seealso cref="LevelState"/> for level state management.
/// </summary>
public partial class Level : Node2D
{
    public override void _Ready()
    {
        _ = new LevelState();
        LevelState.CurrentLevel = this;

        DrawRoadEdges();

        Budget = Cost.InitialBudget;
        History.Clear();
        DraftHistory.Clear();
    }

    public override void _Process(double delta)
    {
        if (CurrentBusLineCreationStep == AddingSubsequentStops
         || CurrentBusLineCreationStep == ContinuingEdit)
        {
            DrawMouseTrackingLine(GetGlobalMousePosition());
        }
    }


    private void DrawRoadEdges()
    {
        var intersectionNodes = GetNode("IntersectionNodes").GetChildren();
        if (intersectionNodes == null)
        {
            GD.PrintErr("No RoadNodes found. Check if RoadNodes Node exists.");
            return;
        }

        var roadEdgeScene = GD.Load<PackedScene>(Path.RoadEdgeScene);

        foreach (Node node in intersectionNodes)
        {
            if (node is IntersectionNode intersectionNode)
            {
                foreach (IntersectionNode neighbor in intersectionNode.Neighbors)
                {
                    if (intersectionNode.GetInstanceId() < neighbor.GetInstanceId()) // Only draw edge once per pair (avoid duplicates)
                    {
                        var edge = roadEdgeScene.Instantiate<RoadEdge>();
                        AddChild(edge);
                        edge.SetEndpoints(intersectionNode, neighbor);
                    }
                }
            }
        }
    }

}

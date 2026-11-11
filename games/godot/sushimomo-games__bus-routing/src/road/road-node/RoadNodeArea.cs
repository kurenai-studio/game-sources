using Godot;
using System.Collections.Generic;
using System.Linq;
using static EditorState;
using static LevelState;
using static BusLineCreationStep;
using static Path;

public partial class RoadNodeArea : Area2D
{
    private ErrorMessage errorMessage;

    public override void _Ready()
    {
        errorMessage = GetTree().CurrentScene.GetNode<ErrorMessage>
        (
            ErrorMessageNode
        );
    }

    public override void _UnhandledInput(InputEvent @event)
    {
        if (@event.IsLeftMouseRelease())
        {
            // Both creation AND editing should merely pause the segment on mouse release
            if (CurrentBusLineCreationStep == AddingSubsequentStops || CurrentBusLineCreationStep == ContinuingEdit)
            {
                BusLineEditor.FinalizeDraftSegment();
            }
        }
    }

    private void _on_mouse_entered()
    {
        EditorState.HoveredNode = this.GetParent<RoadNode>();
        GD.Print($"Hovered over node: {EditorState.HoveredNode.Name}");
    }

    private void _on_mouse_exited()
    {
        if (EditorState.HoveredNode == this.GetParent<RoadNode>())
        {
            EditorState.HoveredNode = null;
            GD.Print($"No longer hovering over node: {this.GetParent<RoadNode>().Name}");
        }
    }

    private void _on_input_event(Node viewport, InputEvent @event, long shapeIdx)
    {
        var selectedRoadNode = GetParent<RoadNode>();

        if (@event.IsLeftMouseClick())
        {
            if (CurrentBusLineCreationStep == PausedCreation)
            {
                // Try to resume an existing segment first
                if (BusLineEditor.CanResumeBusLineCreation(selectedRoadNode))
                    return;

                // If it wasn't an endpoint, jump to the new node and start a disjointed segment
                BusLineEditor.BeginNewDisjointedSegment(selectedRoadNode);
                return;
            }

            if (selectedRoadNode is BusStop && CurrentBusLineCreationStep == AddingFirstStop)
            {
                BusLineEditor.StartBusLineCreation(selectedRoadNode);
            }
            else if (CurrentBusLineCreationStep == BeginningEdit)
            {
                GD.Print($"Clicked on node: {selectedRoadNode.Name} during busLine edit. {SelectedBusLine.ColorName}");
                if (SelectedBusLine.Path.First() == selectedRoadNode
                 || SelectedBusLine.Path.Last() == selectedRoadNode)
                {
                    IsEditingFromStart = SelectedBusLine.Path.First() == selectedRoadNode;
                    BusLineEditor.StartBusLineEdit(SelectedBusLine, selectedRoadNode);
                    GD.Print($"Starting edit for: {SelectedBusLine.ColorName}");
                    CurrentBusLineCreationStep = ContinuingEdit;
                    return;
                }
            }
        }
        else if (@event is InputEventMouseMotion)
        {
            if (CurrentBusLineCreationStep == AddingSubsequentStops || CurrentBusLineCreationStep == ContinuingEdit)
            {
                BusLineEditor.ContinueBusLineCreation(selectedRoadNode);
            }
        }
    }
}
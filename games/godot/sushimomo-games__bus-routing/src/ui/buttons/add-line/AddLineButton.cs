using Godot;
using System;
using static EditorTool;
using static Path;
using static BusLineEditor;
using static EditorState;

public partial class AddLineButton : TextureButton
{
    /// <summary>
    /// The label that indicates to the player that they are currently creating a new bus line.
    /// </summary>
    private Label _creatingNewLineLabel;
    private Button _endBusLineButton;

    public override void _Ready()
    {
        _creatingNewLineLabel = GetTree().CurrentScene.GetNode<Label>(LineEditorStatusLabelNode);
        _endBusLineButton = GetTree().CurrentScene.GetNode<Button>(EndBusLineButtonNode);
    }

    private void _on_pressed()
    {
        EditorState.ActiveTool = NewBusLine;
        _creatingNewLineLabel.Text = "● Select a starting stop...";
        _creatingNewLineLabel.Visible = true;
        _endBusLineButton.Visible = true;
    }
}

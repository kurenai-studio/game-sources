using Godot;
using System;
using static EditorState;
using static LevelState;

public partial class InfoWindow : Control
{
    /// <summary>
    /// The busLine that this info window is displaying information about.
    /// </summary>
    public BusLine BusLine { get; set; }

    /// <summary>
    /// Whether or not this info window is currently being dragged by the user.
    /// </summary>
    private bool _isDragging = false;

    /// <summary>
    /// The offset from the mouse position to the top-left corner of the info
    /// window.
    /// </summary>
    private Vector2 _dragOffset = Vector2.Zero;

    private ColorRect _topBarRect;
    private Button _deleteButton;
    private ItemList _busLineList;
    private Label _infoText;
    private Button _closeButton;
    private Label _lineEditorStatusLabel;
    private Button _endBusLineButton;

    public override void _Ready()
    {
        Position = new Vector2(100, 100);

        _busLineList = GetTree().CurrentScene.GetNode<ItemList>(Path.BusLineListNode);
        _lineEditorStatusLabel = GetTree().CurrentScene.GetNode<Label>(Path.LineEditorStatusLabelNode);
        _endBusLineButton = GetTree().CurrentScene.GetNode<Button>(Path.EndBusLineButtonNode);
        _topBarRect = GetNode<ColorRect>("VBoxContainer/TopBarRect");
        _deleteButton = GetNode<Button>("VBoxContainer/ButtonsRect/DeleteButton");
        _infoText = GetNode<Label>("VBoxContainer/PanelContainer/InfoText");

        _closeButton = _topBarRect.GetNode<Button>("CloseButton");

        if (BusLine != null)
        {
            BusLine.OnPathChanged += UpdateInfoText;
            BusLine.OnDeleted += QueueFree; // Destroys this window when BusLine triggers OnDeleted
        }
        UpdateInfoText();
    }

    private void UpdateInfoText()
    {
        _infoText.Text = $"Time to complete: {BusLine.TimeToComplete:F2} minutes";
    }

    public override void _Input(InputEvent @event)
    {
        // Handle dragging the info window around the screen.
        if (@event is InputEventMouseButton mouseButton && mouseButton.ButtonIndex == MouseButton.Left)
        {
            if (mouseButton.Pressed && _topBarRect.GetGlobalRect().HasPoint(GetGlobalMousePosition()))
            {
                // Prevent dragging and swallowing the input if we are clicking the close button
                if (_closeButton != null && _closeButton.GetGlobalRect().HasPoint(GetGlobalMousePosition()))
                {
                    return;
                }

                _isDragging = true;
                _dragOffset = GetGlobalMousePosition() - GlobalPosition;
                GetViewport().SetInputAsHandled(); // Prevent the click from interacting with other UI elements.
            }
            else
            {
                _isDragging = false;
            }
        }
        else if (@event is InputEventMouseMotion && _isDragging)
        {
            GlobalPosition = GetGlobalMousePosition() - _dragOffset;
        }
    }

    private void _on_delete_button_pressed()
    {
        GetTree().CurrentScene.GetNode<BusLineList>(Path.BusLineListNode).DeleteBusLine(BusLine, undoable: true);
        QueueFree();
    }

    private void _on_edit_button_pressed()
    {
        CurrentBusLineCreationStep = BusLineCreationStep.BeginningEdit;
        _lineEditorStatusLabel.Text = $"● Editing bus line: {BusLine.ColorName}";
        _lineEditorStatusLabel.Visible = true;
        _endBusLineButton.Visible = true;
    }

    private void _on_close_button_pressed()
    {
        GD.Print("Close button pressed, closing info window. i am stupid. my suffering is endless.");
        QueueFree();
    }

    public override void _ExitTree()
    {
        OpenWindows.Remove(BusLine.ID);

        if (BusLine != null)
        {
            BusLine.OnPathChanged -= UpdateInfoText;
            BusLine.OnDeleted -= QueueFree;
        }
    }
}
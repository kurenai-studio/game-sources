using Godot;
using System;
using System.Collections.Generic;
using static EditorState;

public partial class BusLineList : ItemList
{
    private PackedScene InfoWindowScene = GD.Load<PackedScene>(Path.InfoWindowScene);

    public override void _UnhandledInput(InputEvent @event)
    {
        if (SelectedBusLine != null && @event.IsActionPressed("ui_text_delete")) // "ui_cancel" is usually the Escape or Delete key
        {
            DeleteBusLine(SelectedBusLine, undoable: true);
            AcceptEvent();
        }
    }

    /// <summary>
    /// Removes a bus line from the level and the list.
    /// </summary>
    /// <param name="undoable">
    /// If true the line is only detached and a <see cref="DeleteBusLineEdit"/> is logged so the
    /// delete can be undone. If false (e.g. the line was invalidated by deleting a bus stop) the
    /// line is freed immediately.
    /// </param>
    public void DeleteBusLine(BusLine busLine, bool undoable = false)
    {
        GD.Print($"Deleting busLine: {busLine.ColorName}");

        int itemIndex = LevelState.AllBusLines.IndexOf(busLine);
        if (itemIndex != -1)
        {
            RemoveItem(itemIndex);
        }

        if (undoable)
        {
            busLine.Detach();
            History.LogEdit(new DeleteBusLineEdit(busLine, itemIndex));
        }
        else
        {
            busLine.Delete();
        }

        SelectedBusLine = null;
        LevelState.UpdateAllHouseStatuses();
    }

    private void _on_item_selected(int index)
    {
        if (index >= 0 && index < LevelState.AllBusLines.Count)
        {
            SelectedBusLine = LevelState.AllBusLines[index];

            LevelState.InformationPanel.ShowBusLine(SelectedBusLine);

            if (OpenWindows.ContainsKey(SelectedBusLine.ID))
                return;

            var window = InfoWindowScene.Instantiate<InfoWindow>();
            window.BusLine = SelectedBusLine;
            var canvasLayer = GetTree().CurrentScene.GetNode<CanvasLayer>("CanvasLayer");
            canvasLayer.AddChild(window);
            OpenWindows[SelectedBusLine.ID] = window;
        }
    }

    public override void _Input(InputEvent @event)
    {
        // if (@event.IsLeftMouseClick())
        // {
        //     // Check if the click was outside the item list to deselect the current busLine
        //     var mouseEvent = (InputEventMouseButton)@event;
        //     Rect2 itemListRect = GetGlobalRect();
        //     if (!itemListRect.HasPoint(mouseEvent.GlobalPosition))
        //     {
        //         DeselectAll();
        //         if (SelectedBusLine != null)
        //         {
        //             SelectedBusLine = null;
        //         }
        //     }
        // }
    }
}

using Godot;
using System;

/// <summary>
/// Extension methods for Godot's InputEvent.
/// </summary>
public static class InputEventExtensions
{
    public static bool IsLeftMouseClick(this InputEvent @event)
    {
        return @event is InputEventMouseButton mouseEvent
              && mouseEvent.Pressed
              && mouseEvent.ButtonIndex == MouseButton.Left;
    }

    public static bool IsRightMouseClick(this InputEvent @event)
    {
        return @event is InputEventMouseButton mouseEvent
              && mouseEvent.Pressed
              && mouseEvent.ButtonIndex == MouseButton.Right;
    }

    public static bool IsLeftMouseRelease(this InputEvent @event)
    {
        return @event is InputEventMouseButton mouseEvent
              && !mouseEvent.Pressed
              && mouseEvent.ButtonIndex == MouseButton.Left;
    }

    public static bool IsMiddleMouseClick(this InputEvent @event)
    {
        return @event is InputEventMouseButton mouseEvent
              && mouseEvent.Pressed
              && mouseEvent.ButtonIndex == MouseButton.Middle;
    }

    public static bool IsMiddleMouseRelease(this InputEvent @event)
    {
        return @event is InputEventMouseButton mouseEvent
              && !mouseEvent.Pressed
              && mouseEvent.ButtonIndex == MouseButton.Middle;
    }

    public static bool IsMouseWheelUp(this InputEvent @event)
    {
        return @event is InputEventMouseButton mouseEvent
                && mouseEvent.Pressed
                && mouseEvent.ButtonIndex == MouseButton.WheelUp;
    }

    public static bool IsMouseWheelDown(this InputEvent @event)
    {
        return @event is InputEventMouseButton mouseEvent
                && mouseEvent.Pressed
                && mouseEvent.ButtonIndex == MouseButton.WheelDown;
    }
}
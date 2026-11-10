using Godot;
using System;

public partial class Camera : Camera2D
{
    /// <summary>
    /// Indicates whether the camera is currently being dragged with the middle mouse button.
    /// </summary>
    private bool isDragging = false;

    /// <summary>
    /// Stores the position of the mouse when the middle mouse button was
    /// pressed, used to calculate drag movement.
    /// </summary>
    private Vector2 dragStartPosition;

    /// <summary>
    /// Multiplies the current zoom by the factor, keeping the world point
    /// under the mouse cursor stationary on screen.
    /// </summary>
    private void ZoomAtCursor(float factor)
    {
        Vector2 oldZoom = Zoom;
        float z = Math.Clamp(oldZoom.X * factor, 0.2f, 5f);
        Vector2 newZoom = new Vector2(z, z);

        if (newZoom == oldZoom)
            return;

        Vector2 offsetFromCenter = GetViewport().GetMousePosition() - GetViewportRect().Size / 2f;

        Position += offsetFromCenter / oldZoom - offsetFromCenter / newZoom;
        Zoom = newZoom;
    }

    public override void _Input(InputEvent @event)
    {
        if (@event.IsMiddleMouseClick())
        {
            isDragging = true;
            dragStartPosition = GetGlobalMousePosition();
        }
        else if (@event.IsMiddleMouseRelease())
        {
            isDragging = false;
        }

        if (@event is InputEventMouseMotion mouseMotionEvent && isDragging)
        {
            Position -= mouseMotionEvent.Relative / Zoom;
        }

        if (@event.IsMouseWheelDown())
        {
            ZoomAtCursor(0.95f);
        }
        else if (@event.IsMouseWheelUp())
        {
            ZoomAtCursor(1.05f);
        }
    }
}
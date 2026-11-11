using Godot;
using System;

public partial class AddStop : Control
{
    public override Variant _GetDragData(Vector2 position)
    {
        return "BusStop";
    }
}
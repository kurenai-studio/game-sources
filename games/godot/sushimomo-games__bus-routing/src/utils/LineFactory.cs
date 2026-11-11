using Godot;
using System;

public static class LineFactory
{
    public static Line2D CreateLineAt(Vector2 position)
    {
        var line = new Line2D();
        line.AddPoint(position);
        return line;
    }
}
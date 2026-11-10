using Godot;
using System;

public partial class PreviewBusStop : Node2D
{
    public Area2D IntersectionDetector;
    public Area2D WalkRadius => GetNode<Area2D>("WalkRadius");

    public override void _Ready()
    {
        IntersectionDetector = GetNode<Area2D>("IntersectionDetector");
    }
}

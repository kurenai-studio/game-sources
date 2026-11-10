using Godot;
using System;
using static EditorState;

public partial class BusLineName : Label
{
    public override void _Ready()
    {
        Text = $"{SelectedBusLine.ColorName} Line";
    }
}

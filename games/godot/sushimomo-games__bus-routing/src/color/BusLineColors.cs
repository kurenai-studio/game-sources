using Godot;
using System.Collections.Generic;

/// <summary>
/// A collection of key-value pairs to associate color names with their
/// values.
/// </summary>
public static class BusLineColors
{
    public static readonly List<KeyValuePair<string, Color>> ColorList =
    [
        new("Orange", new Color("E28554")),
        new("Blue", new Color("486AF5")),
        new("Green", new Color("18905C")),
        new("Purple", new Color("A958FF"))
    ];
}
using Godot;
using System.Collections.Generic;

/// <summary>
/// An edit representing a slice: deleting a segment from a bus line while editing it. 
/// Stores draft segments before and after slice so it can be undone.
/// </summary>
public partial class SliceEdit : AbstractEdit
{
    /// <remarks>
    /// Godot script classes require a parameterless contructor.
    /// </remarks>
    public SliceEdit() {}

    public override void Revert()
    {
        
    }
    public override void Apply(){}
}

using Godot;
using System;
using System.Collections.Generic;

/// <summary>
/// A state object class which groups individual line segments of a bus line into groups.
/// </summary>
/// <remarks>
/// This class handles the case in which undoing a segment in a bus line, removes the whole
/// bus line, and does not leave disjointed segments.
/// </remarks>
public partial class FinalizeBusLineEdit : AbstractEdit {

    protected readonly List<BusLine> _group = [];
    /// <summary>
    /// The position each line held in <see cref="LevelState.AllBusLines"/> when it was removed,
    /// so <see cref="Restore"/> can put it back in the same place.
    /// </summary>
    protected readonly Dictionary<BusLine, int> _indices = [];
    public FinalizeBusLineEdit () { }

    public FinalizeBusLineEdit (BusLine line) {
        AddToGroup(line);
    }

    /// <summary>
    ///  Reverts the finalized grouped bus line by removing the entire line
    ///  from the level and detaching it from the scene tree.
    /// </summary>
    /// <remarks>
    /// <p>
    ///  Every valid bus line in the group is treated as a part of the
    ///  same finalized line. Removing it from <see cref="LevelState.AllBusLines"/>
    ///  removes all of the line's segments at once instead of leaving disjointed
    ///  segments behind.
    /// </p>
    /// <p>
    ///  If the line is selected <see cref="EditorState.SelectedBusLine"/> is cleared.
    ///  The bus line node is detached from its parent instead of
    ///  freeing with <c>QueueFree()</c>, which allows redo to reinstantiate the
    ///  undone line.
    /// </p>
    /// </remarks>
    public override void Revert () => Remove();
    /// <summary>
    /// Redoes the finalize: puts the detached bus line back in the level.
    /// </summary>
    public override void Apply() => Restore();

    /// <summary>
    /// Removes every line in the group from the level (the body of <see cref="Revert"/>).
    /// </summary>
    protected void Remove () {
      foreach (var line in _group) {
        if (line == null || !GodotObject.IsInstanceValid(line)) continue; 

        int index = LevelState.AllBusLines.IndexOf(line); 
        if (index < 0) {
          line.GetParent()?.RemoveChild(line); 
          continue; 
        }

        if (EditorState.SelectedBusLine == line) EditorState.SelectedBusLine = null; 
        LevelState.AllBusLines.RemoveAt(index); 
        _indices[line] = index; 

        LevelState.ReturnBusLineColor (
          new KeyValuePair<string, Color>(line.ColorName, line.Color)
        );
        line.GetParent()?.RemoveChild(line); 
      }

      if (EditorState.SelectedBusLine != null &&
      (!GodotObject.IsInstanceValid(EditorState.SelectedBusLine) ||
      !LevelState.AllBusLines.Contains(EditorState.SelectedBusLine))) {
        EditorState.SelectedBusLine = null; 
      }
        
      LevelState.UpdateAllHouseStatuses();
      LevelState.RefreshAllBusLineVisuals();
    }

    /// <summary>
    /// Puts every removed line in the group back into the level, the bus line list,
    /// and takes its color out of the pool again. The inverse of <see cref="Remove"/>.
    /// </summary>
    protected void Restore () {

        foreach (var line in _group) {
            if (line == null || !GodotObject.IsInstanceValid(line)) continue;
            if (LevelState.AllBusLines.Contains(line)) continue;

            LevelState.ReserveBusLineColor(
                new KeyValuePair<string, Color>(line.ColorName, line.Color));

            int index = Math.Min(_indices.GetValueOrDefault(line, LevelState.AllBusLines.Count), LevelState.AllBusLines.Count);
            LevelState.AllBusLines.Insert(index, line);
            if (line.GetParent() == null) LevelState.CurrentLevel.AddChild(line);
        }

        LevelState.UpdateAllHouseStatuses();
        LevelState.RefreshAllBusLineVisuals();
    }

    /// <summary>
    /// Adds a finalized bus line to the group.
    /// </summary>
    /// <param name="line">
    /// The whole bus line added.
    /// </param>
    public void AddToGroup (BusLine line) { // take segment
        if (line == null || !GodotObject.IsInstanceValid(line)) return;
        if (_group.Contains(line)) return;
        _group.Add(line);
    }
}

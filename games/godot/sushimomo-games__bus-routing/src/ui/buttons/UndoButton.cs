using Godot;

public partial class UndoButton : TextureButton
{
    private void _on_pressed()
    {
        // If a line is being drawn or edited, undo its segments (pieces) only.
        // Else, undo bus stops and finished bus lines lines.
        if (BusLineEditor.BusLineInProgress != null)
        {
            GD.Print($"[DEBUG - Undo] Undo pressed (draft). CanUndo = {EditorState.DraftHistory.CanUndo}");
            EditorState.DraftHistory.Undo();
        }
        else
        {
            GD.Print($"[DEBUG - Undo] Undo pressed (main). CanUndo = {EditorState.History.CanUndo}");
            EditorState.History.Undo();
        }
    }
}
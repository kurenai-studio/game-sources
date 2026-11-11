using Godot;
using static EditorState;
using static BusLineCreationStep;
using static BusLineEditor;

public partial class EndBusLineButton : Button
{
    private void _on_pressed()
    {
        if (CurrentBusLineCreationStep == AddingFirstStop)
        {
            BusLineEditor.ResetState();
            return;
        }

        if (BusLineEditor.IsInEditingMode)
        {
            FinalizeBusLineEdit();
        }
        else
        {
            FinalizeBusLineCreation();
        }
    }
}

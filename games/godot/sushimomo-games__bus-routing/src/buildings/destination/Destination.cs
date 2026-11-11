using Godot;

[Tool]
public partial class Destination : Building
{
    [Export]
    public uint ResidentQuota { get; set; } = 0;

    /// <summary>
    /// Checks if the resident quota has not been preset in the Godot editor
    /// (i.e., is still 0).
    /// </summary>
    private bool _quotaIsNotPreset
    {
        get => ResidentQuota == 0;
    }

    public override void _Ready()
    {
        base._Ready();

        if (!Engine.IsEditorHint())
        {
            if (_quotaIsNotPreset)
            {
                ResidentQuota = (uint)GD.RandRange(1, 5);
            }

            LevelState.AllDestinations.Add(this);
        }
    }
}
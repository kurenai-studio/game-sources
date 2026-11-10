using Godot;
using System;


public partial class SettingsMenu : PanelContainer
{
    private Button _closeMenuButton, _exitGameButton, _saveButton, _resetButton;
    private Slider _audioAdjust;


    public override void _Ready()
    {
        Visible = false;

        _audioAdjust = GetNode<Slider>("SettingsVBox/VolumeContainer/VolumeSlider");
        _exitGameButton = GetNode<Button>("SettingsVBox/ExitGameButton");
        _saveButton = GetNode<Button>("SettingsVBox/SaveButton");
        _resetButton = GetNode<Button>("SettingsVBox/ResetButton");
        _closeMenuButton = GetNode<Button>("SettingsVBox/CloseMenuButton");

        _audioAdjust.ValueChanged += _onAudioLevelChanged;
        _exitGameButton.Pressed += _onExitGameButtonPressed;
        _saveButton.Pressed += _onSaveButtonPressed;
        _resetButton.Pressed += _onResetButtonPressed;
        _closeMenuButton.Pressed += _onCloseMenuButtonPressed;
    }


    public override void _Input(InputEvent @event)
    {
        if (@event is InputEventKey keyEvent && keyEvent.Pressed && !keyEvent.Echo)
        {
            if (keyEvent.Keycode == Key.Escape)
            {
                if (Visible) hideMenu();
                else showMenu();

            }
        }
    }


    private void _onAudioLevelChanged(double audioLevel)
    {
        GD.Print(audioLevel);
    }


    private void _onExitGameButtonPressed()
    {
        GetTree().Quit();
    }


    private void _onCloseMenuButtonPressed()
    {
        hideMenu();
    }


    private void showMenu()
    {
        Show();
        GetTree().Paused = true;
    }


    private void hideMenu()
    {
        Hide();
        GetTree().Paused = false;
    }

    public void _onSaveButtonPressed()
    {
        GD.Print("Save clicked!");
    }

    public void _onResetButtonPressed()
    {
        GD.Print("Reset clicked!");
    }

}

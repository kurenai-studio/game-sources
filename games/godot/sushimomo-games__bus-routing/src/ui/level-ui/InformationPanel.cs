using Godot;
using System;
using System.Linq;
using static EditorState;
public partial class InformationPanel : Control
{
    private Label _titleLabel;
    private Label _infoText;
    private Label TitleLabel => _titleLabel ??= GetNode<Label>("VBoxContainer/TitleLabel");
    private Label InfoText => _infoText ??= GetNode<Label>("VBoxContainer/InfoText");
    private Button _deleteLineBtn, _editLineBtn;
    private Button _endBusLineButton;
    private Label _lineEditorStatusLabel;
    private BusLine _currentLine;


    public override void _Ready()
    {
        LevelState.InformationPanel = this;
        this.Visible = false;

        _titleLabel = GetNode<Label>("VBoxContainer/TitleLabel");
        _infoText = GetNode<Label>("VBoxContainer/InfoText");
        _editLineBtn = GetNode<Button>("VBoxContainer/EditBtn");
        _deleteLineBtn = GetNode<Button>("VBoxContainer/DeleteBtn");
        _endBusLineButton = GetTree().CurrentScene.GetNode<Button>(Path.EndBusLineButtonNode);
        _lineEditorStatusLabel = GetTree().CurrentScene.GetNode<Label>(Path.LineEditorStatusLabelNode);

        _editLineBtn.Pressed += _onEditLineBtnPressed;
        _deleteLineBtn.Pressed += _onDeleteLineBtnPressed;

    }

    public void ShowBusLine(BusLine line)
    {
        _currentLine = line;

        this.Visible = true; //makes the bus line information visible when the user clicks the line
        _editLineBtn.Visible = true;
        _deleteLineBtn.Visible = true;

        TitleLabel.Text = line.ColorName + " " + "busline"; //changes the color of the busline name
        TitleLabel.AddThemeColorOverride("font_color", line.Color);
        int stopCount = line.Path.OfType<BusStop>().Count();

        int totalResidents = 0;
        foreach (BusStop stop in line.Path.OfType<BusStop>())
        {
            totalResidents += stop.GetHouseCount();
        }
        InfoText.Text =
        $"Number of stops: {stopCount}\n\n" +
        $"Residents served: {totalResidents}\n\n" +
        $"Time to complete: {line.TimeToComplete:F2} minutes";
    }

    /// <summary>
    /// Allows user to edit bus line from the information panel. Indicates to user
    /// which bus line is currently being edited.
    /// </summary>
    public void _onEditLineBtnPressed()
    {
        SelectedBusLine = _currentLine;
        CurrentBusLineCreationStep = BusLineCreationStep.BeginningEdit;
        _lineEditorStatusLabel.Text = $"● Editing bus line: {_currentLine.ColorName}";

        _endBusLineButton.Visible = true;
        _lineEditorStatusLabel.Visible = true;
        this.Visible = false;
    }

    /// <summary>
    /// Removes bus line from list of existing bus lines using Delete() of
    /// BusLine class.
    /// </summary>
    public void _onDeleteLineBtnPressed()
    {
        this.Visible = false;
        _currentLine.Delete();
    }

    public void ShowHouse(House house, String displayInfo)
    {
        this.Visible = true;
        _hideButtons();

        TitleLabel.Text = house.BuildingColor + " House";
        InfoText.Text = displayInfo;
    }

    public void ShowBusStop(BusStop stop, int count)
    {
        this.Visible = true;
        _hideButtons();

        TitleLabel.Text = "Bus Stop";
        InfoText.Text = count + " residents have access to this stop";
    }

    private void _hideButtons()
    {
        _editLineBtn.Visible = false;
        _deleteLineBtn.Visible = false;
    }

}

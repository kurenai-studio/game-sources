using Godot;
using Microsoft.CodeAnalysis.Text;
using System;
using System.Collections.Generic;
using System.Linq;

[Tool]
public partial class House : Building
{
    private Sprite2D _checkSprite;
    public Sprite2D _houseSprite;
    private bool _isChecked;
    private static House _houseSelected;
    public Color _outlineColor;
    private float _newOutlineWeight = 7.0f;
    // private PackedScene _infoPopupScene = GD.Load<PackedScene>(Path.InfoPopupScene);   //Info Pop-Up no longer in use
    // private Control _infoPopup;

    public Commute CurrentItinerary { get; private set; }

    public bool IsChecked
    {
        get => _isChecked;
        private set
        {
            _isChecked = value;
            if (_checkSprite != null)
            {
                _checkSprite.Visible = value;

            }
        }
    }

    private float _busUsageProbability = 0.0f;

    public float BusUsageProbability
    {
        get => _busUsageProbability;
        set => _busUsageProbability = Mathf.Clamp(value, 0.0f, 1.0f);
    }

    public override void _Ready()
    {
        base._Ready(); // Calls _Ready() of the base class, Building. Yes, we need this.
        _checkSprite = GetNode<Sprite2D>("Check");
        _checkSprite.Visible = _isChecked;

        _houseSprite = GetNodeOrNull<Sprite2D>("Sprite2D");

        ///Each house has ShaderMaterial so as to manipulate its independent outline
        if (_houseSprite?.Material is ShaderMaterial material)
        {
            _houseSprite.Material = material.Duplicate() as ShaderMaterial;
            _houseSprite.SetInstanceShaderParameter("line_thickness", 4.0f);
        }

        // _infoPopup = GetNode<Control>("InfoPopup");  //Info Pop-up no longer in use

        LevelState.AllHouses.Add(this);
    }

    public override void _Process(double delta)
    {
        base._Process(delta); // Yes, we need this too.

        ///If this house is selected...change line color and weight to indicate selection
        if (_houseSelected == this && _houseSprite?.Material is ShaderMaterial shaderMat)
        {
            shaderMat.SetShaderParameter("line_thickness", _newOutlineWeight);
            shaderMat.SetShaderParameter("line_color", _outlineColor);
        }

        // if (_infoPopup != null)  //Info Pop-up no longer in use
        // {
        //     _infoPopup.GlobalPosition = GetViewport().GetMousePosition() + new Vector2(15, 15);
        // }
    }

    /// <summary>
    /// Recalculates the resident's commute, whether the house is connected,
    /// and the probability that the resident uses the bus.
    /// </summary>
    public void UpdateCheckStatus()
    {
        CurrentItinerary = FindCommute();
        IsChecked = CurrentItinerary != null;
        BusUsageProbability = BusUsageModel.CalculateProbability(CurrentItinerary);
    }

    /// <summary>
    /// Finds the best bus commute from this house to a destination of the
    /// same color.
    /// </summary>
    /// <returns>The commute, or null if no destination can be reached by bus.</returns>
    private Commute FindCommute()
    {
        if (ReachableBusStop is not BusStop startStop)
        {
            return null;
        }

        var validDestinations = LevelState.AllDestinations
            .Where(destination => destination.Modulate == Modulate
            && destination.ReachableBusStop is BusStop)
            .ToHashSet();

        if (validDestinations.Count == 0)
        {
            return null;
        }

        var transitSegments = Pathfinder.CalculateBestRoute(startStop, validDestinations);

        if (transitSegments == null)
        {
            return null;
        }

        transitSegments.Insert(0, new WalkSegment(this, startStop));
        return new Commute(transitSegments);
    }

    /* ORIGINAL CODE FOR POP-UP WINDOW: No longer visible to user, replaced with information panel (InformationPanel.cs)
        private void _on_area_2d_mouse_entered()
        {
            if (_infoPopup == null)
            {
                _infoPopup = _infoPopupScene.Instantiate<Control>();
                var canvasLayer = GetTree().CurrentScene.GetNode<CanvasLayer>("CanvasLayer"); 
                canvasLayer.AddChild(_infoPopup);
                string commuteDetails = CurrentItinerary != null 
                ? $"Total Time: {CurrentItinerary.TotalTimeMinutes:F1} min\n{string.Join("\n", CurrentItinerary.GetDirections())}" 
                : "No commute available";
                _infoPopup.GetNode<Label>("Label").Text = $"Bus Usage Probability: {BusUsageProbability:P1}\n\n{commuteDetails}";
                _infoPopup.Modulate = Modulate;
            }

            if (CurrentItinerary != null)
            {
                foreach (var segment in CurrentItinerary.Itinerary.OfType<RideSegment>())
                {
                    segment.Line.Visual.HighlightPath(segment.GetPathNodes());
                }
            }
        }

        private void _on_area_2d_mouse_exited()
        {
            _infoPopup?.QueueFree();
            _infoPopup = null;

            if (CurrentItinerary != null)
            {
                foreach (var segment in CurrentItinerary.Itinerary.OfType<RideSegment>())
                {
                    segment.Line.Visual.ClearHighlight();
                }
            }
        }
    */

    private void _on_house_clicked(
        Node viewport,
        InputEvent @event,
        long shapeIdx)
    {

        if (@event is InputEventMouseButton mouseEvent && mouseEvent.Pressed && mouseEvent.ButtonIndex == MouseButton.Left)
        {
            UpdateCheckStatus();
            UpdateOutlineColor(Colors.Red);

            string commuteDetails = CurrentItinerary != null
            ? $"Bus Usage Probability: {BusUsageProbability:P1}\n\nItinerary:\nTotal Time: {CurrentItinerary.TotalTimeMinutes:F1} min\n{string.Join("\n", CurrentItinerary.GetDirections())}"
            : "No commute available";   //Will add commute difference between car vs bus once data is available

            LevelState.InformationPanel.ShowHouse(this, commuteDetails);
        }

    }

    /// <summary>
    /// Updates house outline. Removes colored outlines from houses that are not clicked.
    /// Sets new outline color (SetOutlineColor()) based on house color.
    /// </summary>
    private void UpdateOutlineColor(Color color)
    {
        //Resets outline when another house is selected (removes color and added line weight)
        if (_houseSelected != null && _houseSelected != this && _houseSelected._houseSprite?.Material is ShaderMaterial prevMat)
        {
            ResetHouseOutline(prevMat);
        }

        _houseSelected = this;
        _outlineColor = SetOutlineColor(this);

    }

    /// <summary>
    /// New outline color based on house color. Outline is a darker/more transparent
    /// variant of original house color for better visibility.
    /// </summary>
    private Color SetOutlineColor(House currentHouse)
    {
        Color houseColor = Building.BuildingColorPalette[currentHouse.BuildingColor];
        float _darkenVal = 0.2f;
        return _outlineColor = new Color(houseColor.R - _darkenVal, houseColor.G - _darkenVal, houseColor.B - _darkenVal, 0.5f);
    }

    /// <summary>
    /// Resets house outline to original 4.0f weight and black color. Won't be visible
    /// unless bus stop is placed/already exists close enough to house
    /// </summary>
    public static void ResetHouseOutline(ShaderMaterial prevMat)
    {
        prevMat.SetShaderParameter("line_thickness", 4.0f);
        prevMat.SetShaderParameter("line_color", Colors.Black);
    }

    /// <summary>
    /// Called by BusStop.cs, BusLine.cs when a bus stop or bus line is selected.
    /// Deselects houses so as to remove outlines, now that it is no longer selected.
    /// </summary>
    public static void DeselectHouses()
    {
        if (_houseSelected == null) { return; }
        else
        {
            if (_houseSelected._houseSprite?.Material is ShaderMaterial deselectMat)
            {
                ResetHouseOutline(deselectMat);
            }
            _houseSelected = null;
        }
    }

}

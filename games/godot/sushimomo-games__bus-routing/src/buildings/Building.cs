using Godot;
using System.Collections.Generic;

/// <summary>
/// Base class for buildings (houses and workplaces) that can be serviced by bus stops.
/// Handles visual highlighting.
/// </summary>

[Tool]
public abstract partial class Building : Node2D
{
    public static readonly Dictionary<string, Color> BuildingColorPalette = new()
    {
        { "Red", Colors.IndianRed },
        { "Blue", Colors.DeepSkyBlue },
        { "Green", Colors.ForestGreen },
        { "Yellow", Colors.Gold },
        { "White", Colors.AntiqueWhite }
    };
    private string _selectedColorName = "White";
    private BusStopDetector _busStopDetector;
    private Sprite2D _buildingSprite;
    private float _targetThickness;
    private float _currentThickness;
    private float _lerpSpeed = 15f;

    [Export(PropertyHint.Enum, "Red,Blue,Green,Yellow,White")]
    public string BuildingColor
    {
        get => _selectedColorName;
        set
        {
            _selectedColorName = value;
            UpdateSpriteColor();
        }
    }

    /// <summary>
    /// Gets the bus stop node that this building can reach.
    /// Returns null if no bus stop is currently in range.
    /// </summary>
    public virtual Node ReachableBusStop => _busStopDetector?.ReachableBusStop;

    public override void _Ready()
    {
        UpdateSpriteColor();

        if (!Engine.IsEditorHint())
        {
            _busStopDetector = GetNodeOrNull<BusStopDetector>("BusStopDetector");
            _buildingSprite = GetNodeOrNull<Sprite2D>("Sprite2D");
            if (_buildingSprite?.Material != null)
            {
                _buildingSprite.Material = (Material)_buildingSprite.Material.Duplicate();
            }
        }
    }

    public override void _Process(double delta)
    {
        if (Engine.IsEditorHint()) return;
        bool shouldHighlight = false;

        if (ReachableBusStop != null)
        {
            if (ReachableBusStop is BusStop)
            {
                shouldHighlight = true;
            }
            else if (ReachableBusStop is PreviewBusStop)
            {
                shouldHighlight = LevelState.LevelUI?.IsValidPlacement == true;
            }
        }

        if (shouldHighlight)
        {
            _targetThickness = 4.0f;
        }
        else
        {
            _targetThickness = 0.0f;
        }

        _currentThickness = Mathf.Lerp(_currentThickness, _targetThickness, (float)(delta * _lerpSpeed));

        if (_buildingSprite?.Material is ShaderMaterial shaderMat)
        {
            shaderMat.SetShaderParameter("line_thickness", _currentThickness);
            shaderMat.SetShaderParameter("sprite_scale", _buildingSprite.GlobalScale);
        }
    }

    private void UpdateSpriteColor()
    {
        if (BuildingColorPalette.TryGetValue(_selectedColorName, out Color newColor))
        {
            this.Modulate = newColor;
            if (IsInsideTree())
            {
                if (_buildingSprite == null)
                {
                    _buildingSprite = GetNodeOrNull<Sprite2D>("Sprite2D");
                }
                QueueRedraw();
            }
        }
    }
}
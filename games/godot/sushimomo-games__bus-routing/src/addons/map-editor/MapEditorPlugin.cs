#if TOOLS
using Godot;
using System;
using System.Collections.Generic;
using System.Linq;
using static Path;

[Tool]
public partial class MapEditorPlugin : EditorPlugin
{
    private Dictionary<ToolMode, PackedScene> _scenes = new();
    private OptionButton _modeSelector;
    private OptionButton _colorSelector;
    private Button _toggleBtn;
    private bool _toolActive = false;
    private Node2D _currentPlacingInstance = null;
    private Vector2 _placementPosition = Vector2.Zero;
    private RoadNode _connectionSource = null;
    private enum ToolMode { PlaceRoad, ConnectRoad, PlaceHouse, PlaceDestination }

    public override bool _Handles(GodotObject @object)
    {
        return _toolActive;
    }
    public override void _EnterTree()
    {
        _scenes[ToolMode.PlaceRoad] = GD.Load<PackedScene>(IntersectionScene);
        _scenes[ToolMode.PlaceHouse] = GD.Load<PackedScene>(HouseScene);
        _scenes[ToolMode.PlaceDestination] = GD.Load<PackedScene>(DestinationScene);

        var container = new HBoxContainer();
        _toggleBtn = new Button { Text = "Road Tool", ToggleMode = true };
        _toggleBtn.Toggled += OnToolToggled;

        _modeSelector = new OptionButton();
        _modeSelector.ItemSelected += OnModeSelected;
        _modeSelector.AddItem("Road: Place Nodes", (int)ToolMode.PlaceRoad);
        _modeSelector.AddItem("Road: Connect Nodes", (int)ToolMode.ConnectRoad);
        _modeSelector.AddItem("Building: Place House", (int)ToolMode.PlaceHouse);
        _modeSelector.AddItem("Building: Place Destination", (int)ToolMode.PlaceDestination);
        _modeSelector.Visible = false;


        _colorSelector = new OptionButton();
        foreach (var color in Building.BuildingColorPalette)
        {
            _colorSelector.AddItem(color.Key);
        }
        _colorSelector.Visible = false;



        container.AddChild(_toggleBtn);
        container.AddChild(_modeSelector);
        container.AddChild(_colorSelector);

        AddControlToContainer(CustomControlContainer.CanvasEditorMenu, container);
    }
    public override void _ExitTree()
    {
        if (IsInstanceValid(_toggleBtn))
        {
            if (_toggleBtn.IsConnected(Button.SignalName.Toggled, Callable.From<bool>(OnToolToggled)))
            {
                _toggleBtn.Toggled -= OnToolToggled;
            }
        }

        var parent = _modeSelector?.GetParent();
        if (IsInstanceValid(parent))
        {
            parent.QueueFree();
        }
        if (IsInstanceValid(_modeSelector))
        {
            _modeSelector.ItemSelected -= OnModeSelected;
        }
    }
    private void OnToolToggled(bool toggled)
    {
        _toolActive = toggled;
        _connectionSource = null;
        if (toggled)
        {
            EditorInterface.Singleton.SetMainScreenEditor("2D");
            EditorInterface.Singleton.GetSelection().Clear();

            var root = EditorInterface.Singleton.GetEditedSceneRoot();
            if (root != null)
            {
                EditorInterface.Singleton.GetSelection().AddNode(root);
            }
        }

        if (_modeSelector != null)
        {
            _modeSelector.Visible = toggled;
        }
        UpdateColorSelectorVisibility();
        GD.Print(_toolActive ? "Road Mode: ON" : "Road Mode: OFF");
    }

    private void OnModeSelected(long index)
    {
        UpdateColorSelectorVisibility();
    }

    private void UpdateColorSelectorVisibility()
    {
        if (!_toolActive || _modeSelector == null || _colorSelector == null)
        {
            _colorSelector.Visible = false;
            return;
        }

        ToolMode currentMode = (ToolMode)_modeSelector.Selected;
        bool isBuildingMode = currentMode == ToolMode.PlaceHouse ||
                              currentMode == ToolMode.PlaceDestination;

        _colorSelector.Visible = isBuildingMode;
    }
    public override bool _ForwardCanvasGuiInput(InputEvent @event)
    {
        if (!_toolActive) return false;
        if (@event is InputEventMouseButton mb)
        {
            if (mb.ButtonIndex == MouseButton.Left && mb.CtrlPressed && mb.Pressed) HandleMousePress(mb);
            if (mb.IsReleased()) _currentPlacingInstance = null;
            return true;
        }
        if (@event is InputEventMouseMotion mm && _currentPlacingInstance != null)
        {
            HandleMouseMotion(mm);
            return true;
        }
        return false;
    }


    private void HandleMousePress(InputEventMouseButton input)
    {
        ToolMode currentMode = (ToolMode)_modeSelector.Selected;
        var sceneRoot = EditorInterface.Singleton.GetEditedSceneRoot();
        if (sceneRoot == null)
        {
            GD.PrintErr("Scene Root is not found. Exiting Input Event");
            return;
        }
        Vector2 eventPos = EditorInterface.Singleton.GetEditorViewport2D().GetFinalTransform().AffineInverse() * input.Position;
        _placementPosition = eventPos;

        switch (currentMode)
        {
            case ToolMode.ConnectRoad:
                HandleConnection(sceneRoot, eventPos);
                break;
            case ToolMode.PlaceRoad:
                PlaceScene(sceneRoot, eventPos, currentMode);
                break;
            case ToolMode.PlaceHouse:
                _currentPlacingInstance = PlaceScene(sceneRoot, eventPos, currentMode);
                break;
            case ToolMode.PlaceDestination:
                _currentPlacingInstance = PlaceScene(sceneRoot, eventPos, currentMode);
                break;
        }

    }

    private void HandleMouseMotion(InputEventMouseMotion input)
    {
        Vector2 eventPos = EditorInterface.Singleton.GetEditorViewport2D().GetFinalTransform().AffineInverse() * input.Position;
        float angle = _placementPosition.AngleToPoint(eventPos);
        _currentPlacingInstance.Rotation = angle - Mathf.Pi / 2;
    }

    private Node2D PlaceScene(Node sceneRoot, Vector2 worldPos, ToolMode mode)
    {
        if (!_scenes.ContainsKey(mode) || _scenes[mode] == null) return null;
        string containerName = (mode == ToolMode.PlaceRoad) ? "IntersectionNodes" : "Buildings";
        Node container = GetOrCreateContainer(sceneRoot, containerName);

        var instance = _scenes[mode].Instantiate<Node2D>();
        container.AddChild(instance);
        instance.Owner = sceneRoot;
        instance.GlobalPosition = worldPos;

        if (instance is Building building)
        {
            string selectedColor = _colorSelector.GetItemText(_colorSelector.Selected);
            building.BuildingColor = selectedColor;
        }

        return instance;
    }

    private Node GetOrCreateContainer(Node sceneRoot, string name)
    {
        Node container = sceneRoot.FindChild(name, true, false);
        if (container == null)
        {
            container = new Node2D { Name = name };
            sceneRoot.AddChild(container);
            container.Owner = sceneRoot;
        }
        return container;
    }

    private void HandleConnection(Node sceneRoot, Vector2 worldPos)
    {
        var clickedNode = FindNodeAtPosition(sceneRoot, worldPos);
        if (clickedNode == null) return;
        if (_connectionSource == null)
        {
            _connectionSource = clickedNode;
            GD.Print($"Selected Start: {clickedNode.Name}. Ctrl+Click another to Toggle Connection.");
        }
        else if (_connectionSource == clickedNode)
        {
            _connectionSource = null;
            GD.Print("Selection cleared.");
        }
        else
        {
            if (_connectionSource.Neighbors.Contains(clickedNode))
            {
                _connectionSource.Neighbors.Remove(clickedNode);
                clickedNode.Neighbors.Remove(_connectionSource);
                GD.Print($"Removed connection between {_connectionSource.Name} and {clickedNode.Name}");
            }
            else
            {
                _connectionSource.Neighbors.Add(clickedNode);
                clickedNode.Neighbors.Add(_connectionSource);
                GD.Print($"Connected {_connectionSource.Name} and {clickedNode.Name}");
            }

            _connectionSource.QueueRedraw();
            clickedNode.QueueRedraw();

            _connectionSource = null;
        }
    }

    private RoadNode FindNodeAtPosition(Node root, Vector2 pos)
    {
        return root.FindChildren("*", "Node2D", true, false)
            .OfType<RoadNode>()
            .FirstOrDefault(n => n.GlobalPosition.DistanceTo(pos) < 20f);
    }
}
#endif
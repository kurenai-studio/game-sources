using Godot;

public partial class HoverScaler : Node
{
    /// <summary>
    /// The node that will be scaled when the mouse hovers over it.
    /// </summary>
    private Control _targetNode;

    /// <summary>
    /// How large the target node will scale when hovered over.
    /// </summary>
    [Export] private float _scaleFactor = 1.25f;

    /// <summary>
    /// How quickly the target node scales to size. Higher values result in faster scaling.
    /// </summary>
    [Export] private float _lerpSpeed = 15.0f;

    /// <summary>
    /// The current target scale of the node. This is used to smoothly
    /// interpolate the scale when the mouse enters or exits. Initialized at
    /// the default scale of Vector2.One.
    /// </summary>
    private Vector2 _targetScale = Vector2.One;

    public override void _Ready()
    {
        _targetNode ??= GetParent<Control>();

        if (_targetNode == null)
        {
            GD.PushWarning($"HoverScaler on {Name} has no valid Control target.");
            SetProcess(false);
            return;
        }

        _targetNode.Resized += UpdatePivotPoint;
        UpdatePivotPoint();

        _targetNode.MouseEntered += OnMouseEntered;
        _targetNode.MouseExited += OnMouseExited;
    }

    public override void _Process(double delta)
    {
        if (_targetNode == null) return;

        _targetNode.Scale = _targetNode.Scale.Lerp(_targetScale, (float)delta * _lerpSpeed);
    }

    /// <summary>
    /// Updates the pivot point of the target node such that the scaling occurs
    /// around its center.
    /// </summary>
    private void UpdatePivotPoint()
    {
        _targetNode.PivotOffset = _targetNode.Size / 2.0f;
    }

    private void OnMouseEntered()
    {
        _targetScale = new Vector2(_scaleFactor, _scaleFactor);
    }

    private void OnMouseExited()
    {
        _targetScale = Vector2.One;
    }

    public override void _ExitTree()
    {
        if (_targetNode == null) return;

        _targetNode.Resized -= UpdatePivotPoint;
        _targetNode.MouseEntered -= OnMouseEntered;
        _targetNode.MouseExited -= OnMouseExited;
    }
}
using Godot;
using System;

public partial class ErrorMessage : Control
{
    public Label ErrorMessageTextLabel => GetChild<Label>(1);

    private Timer _messageTimeout;
    private float duration = 3.0f;
    private Color _targetColor;
    private float _lerpSpeed = 10f;
    private Color _transparent = new(1, 1, 1, 0);
    private Color _opaque = new(1, 1, 1, 1);

    public override void _Ready()
    {
        _messageTimeout = GetChild<Timer>(2);
        _messageTimeout.Timeout += () => _targetColor = _transparent; // this is what happens when the timer ends
        Modulate = _transparent;
        _targetColor = Modulate;
    }

    public override void _Process(double delta)
    {
        Modulate = Modulate.Lerp(_targetColor, (float)(delta * _lerpSpeed));
    }

    /// <summary>
    /// Displays an error message for a set duration.
    /// </summary>
    /// <param name="message"></param>
    public void DisplayMessage(string message)
    {
        ErrorMessageTextLabel.Text = message;
        _targetColor = _opaque;
        _messageTimeout.Start(duration);
    }
}

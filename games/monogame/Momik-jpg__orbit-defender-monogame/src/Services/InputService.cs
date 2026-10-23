using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Input;

namespace OrbitDefender.Services;

public sealed class InputService : IInputService
{
    private KeyboardState _currentKeyboard;
    private KeyboardState _previousKeyboard;

    public Vector2 MovementDirection
    {
        get
        {
            var direction = Vector2.Zero;

            if (IsKeyDown(Keys.A, Keys.Left))
            {
                direction.X -= 1f;
            }

            if (IsKeyDown(Keys.D, Keys.Right))
            {
                direction.X += 1f;
            }

            if (IsKeyDown(Keys.W, Keys.Up))
            {
                direction.Y -= 1f;
            }

            if (IsKeyDown(Keys.S, Keys.Down))
            {
                direction.Y += 1f;
            }

            return direction;
        }
    }

    public bool IsShootPressed => IsKeyPressed(Keys.Space);
    public bool IsPausePressed => IsKeyPressed(Keys.P, Keys.Escape);
    public bool IsStartPressed => IsKeyPressed(Keys.Enter);
    public bool IsRestartPressed => IsKeyPressed(Keys.Enter, Keys.R);
    public bool IsBackPressed => IsKeyPressed(Keys.Escape);

    public void Update()
    {
        _previousKeyboard = _currentKeyboard;
        _currentKeyboard = Keyboard.GetState();
    }

    private bool IsKeyDown(params Keys[] keys)
    {
        foreach (var key in keys)
        {
            if (_currentKeyboard.IsKeyDown(key))
            {
                return true;
            }
        }

        return false;
    }

    private bool IsKeyPressed(params Keys[] keys)
    {
        foreach (var key in keys)
        {
            if (_currentKeyboard.IsKeyDown(key) && _previousKeyboard.IsKeyUp(key))
            {
                return true;
            }
        }

        return false;
    }
}

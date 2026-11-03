using System;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Input;
using TowerProtect.App.Client.Interfaces;
using TowerProtect.Domain.Model.Vectors;

namespace TowerProtect.Framework.Other;

internal class InputComponent(Game game) : GameComponent(game), IInputSystem
{
    private KeyboardState _currentKeyboard;
    private KeyboardState _previousKeyboard;

    private MouseState _currentMouse;
    private MouseState _previousMouse;

    public override void Initialize()
    {
        _currentKeyboard = Keyboard.GetState();
        _currentMouse = Mouse.GetState();

        base.Initialize();
    }

    public override void Update(GameTime gameTime)
    {
        _previousKeyboard = _currentKeyboard;
        _currentKeyboard = Keyboard.GetState();

        _previousMouse = _currentMouse;
        _currentMouse = Mouse.GetState();

        base.Update(gameTime);
    }

    public Vec2Int ArrowsVector =>
        (IsKeyPressed("W") || IsKeyPressed("Up") ? Vec2Int.Up : Vec2Int.Zero) +
        (IsKeyPressed("S") || IsKeyPressed("Down") ? Vec2Int.Down : Vec2Int.Zero) +
        (IsKeyPressed("A") || IsKeyPressed("Left") ? Vec2Int.Left : Vec2Int.Zero) +
        (IsKeyPressed("D") || IsKeyPressed("Right") ? Vec2Int.Right : Vec2Int.Zero);

    public Vec2 MouseVector => new Vec2(
        _currentMouse.X - MainGame.Viewport.Width / 2f,
        _currentMouse.Y - MainGame.Viewport.Height / 2f
    ).Normalized;

    public int ScrollSign => Math.Sign(_currentMouse.ScrollWheelValue - _previousMouse.ScrollWheelValue);

    public bool IsKeyDown(string key)
        => TryParseKey(key, out Keys parsedKey) && _currentKeyboard.IsKeyDown(parsedKey) && _previousKeyboard.IsKeyUp(parsedKey);

    public bool IsKeyPressed(string key)
        => TryParseKey(key, out Keys parsedKey) && _currentKeyboard.IsKeyDown(parsedKey);

    public bool IsKeyUp(string key)
        => TryParseKey(key, out Keys parsedKey) && _currentKeyboard.IsKeyUp(parsedKey) && _previousKeyboard.IsKeyDown(parsedKey);

    public bool IsMouseDown(int button)
        => GetButtonState(button, _currentMouse) == ButtonState.Pressed &&
           GetButtonState(button, _previousMouse) == ButtonState.Released;

    public bool IsMousePressed(int button)
        => GetButtonState(button, _currentMouse) == ButtonState.Pressed;

    public bool IsMouseUp(int button)
        => GetButtonState(button, _currentMouse) == ButtonState.Released &&
           GetButtonState(button, _previousMouse) == ButtonState.Pressed;

    private static bool TryParseKey(string key, out Keys result)
        => Enum.TryParse(key, true, out result);

    private static ButtonState GetButtonState(int button, MouseState state)
    {
        return button switch
        {
            0 => state.LeftButton,
            1 => state.RightButton,
            2 => state.MiddleButton,
            _ => ButtonState.Released
        };
    }
}
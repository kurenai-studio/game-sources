using Microsoft.Xna.Framework.Input;

namespace Core;

public static class KeyboardInfo
{
    private static KeyboardState _current;
    private static KeyboardState _previous;

    public static void Update()
    {
        _previous = _current;
        _current = Keyboard.GetState();
    }

    public static bool IsKeyDown(Keys key) => _current.IsKeyDown(key);
    public static bool IsKeyPressed(Keys key) => _current.IsKeyDown(key) && !_previous.IsKeyDown(key);
    public static bool IsKeyReleased(Keys key) => !_current.IsKeyDown(key) && _previous.IsKeyDown(key);
    public static bool WasKeyJustPressed(Keys key)
    {
        return _current.IsKeyDown(key) && _previous.IsKeyUp(key);
    }
    public static bool WasKeyJustReleased(Keys key)
    {
        return _current.IsKeyUp(key) && _previous.IsKeyDown(key);
    }
}
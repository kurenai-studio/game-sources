using Clong.Core.Domain.Enum;

namespace Clong.Core.Domain.Input;

public class InputState
{
    public required Key[] PressedKeys { get; init; }
    public required Key[] PreviouslyPressedKeys { get; init; }
    internal bool IsKeyDown(Key key) => PressedKeys.Contains(key);
    internal bool WasKeyPressedInThisFrame(Key key) => PressedKeys.Contains(key) && !PreviouslyPressedKeys.Contains(key);
}
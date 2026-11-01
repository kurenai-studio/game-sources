namespace Clong.Core.Domain.Input;

/// <summary>
/// Translates input state into in-game control input for the paddles.
/// </summary>
internal class InGameControlInput
{
    internal required float Y { get; init; }

    internal static InGameControlInput FromInputState(InputState inputState, InputConfiguration configuration)
    {
        var up = inputState.IsKeyDown(configuration.KeyUp);
        var down = inputState.IsKeyDown(configuration.KeyDown);

        var controlInputY = 0f;
        if (up) {
            controlInputY += -1f;
        }
        if (down) {
            controlInputY += 1f;
        }

        return new InGameControlInput { Y = controlInputY };
    }
}
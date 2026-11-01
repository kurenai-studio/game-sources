using Clong.Core.Domain.Enum;

namespace Clong.Core.Domain.Input;

/// <summary>
/// Maps logical up and down keys to physical keys or buttons.
/// </summary>
internal class InputConfiguration
{
    internal Key KeyUp { get; init; } = Key.Up;
    internal Key KeyDown { get; init; } = Key.Down;
}
using Clong.Core.Domain.Input;
using Clong.Core.Ports.Driven;
using Microsoft.Xna.Framework.Input;
using DomainKey = Clong.Core.Domain.Enum.Key;
using MonoGameKey = Microsoft.Xna.Framework.Input.Keys;

namespace Clong.Kni.Adapter.Driven.Input;

public class InputReader : IForReadingInput
{
    private static readonly KeyMap KeyMap = new();
    private DomainKey[] _pressedDomainKeys = [];
    private DomainKey[] _previouslyPressedDomainKeys = [];

    public InputState ReadInput()
    {
        var pressedMonoGameKeys = Keyboard.GetState().GetPressedKeys();

        _previouslyPressedDomainKeys = _pressedDomainKeys;
        _pressedDomainKeys = MapToDomainKeys(pressedMonoGameKeys);

        return new InputState {
            PressedKeys = _pressedDomainKeys,
            PreviouslyPressedKeys = _previouslyPressedDomainKeys
        };
    }

    private static DomainKey[] MapToDomainKeys(MonoGameKey[] keys)
    {
        var pressedDomainKeys = new DomainKey[keys.Length];
        for (var i = 0; i < keys.Length; i++) {
            pressedDomainKeys[i] = KeyMap[keys[i]];
        }

        return pressedDomainKeys;
    }
}
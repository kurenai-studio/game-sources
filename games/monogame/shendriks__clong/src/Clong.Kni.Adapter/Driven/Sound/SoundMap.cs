using Clong.Core.Domain.Enum;
using Microsoft.Xna.Framework.Audio;

namespace Clong.Kni.Adapter.Driven.Sound;

public class SoundMap
{
    private readonly Dictionary<SoundId, SoundEffect> _sounds = new();

    public SoundEffect this[SoundId t] {
        get => _sounds[t];
        init => _sounds[t] = value;
    }
}
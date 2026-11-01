using Clong.Core.Domain.Enum;
using Clong.Core.Ports.Driven;

namespace Clong.Kni.Adapter.Driven.Sound;

public class SoundEffectPlayer(SoundMap soundMap) : IForPlayingSound
{
    public void PlaySound(SoundId soundId)
    {
        var soundEffect = soundMap[soundId];
        soundEffect.Play();
    }
}
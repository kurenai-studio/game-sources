using Clong.Core.Domain.Enum;

namespace Clong.Core.Ports.Driven;

public interface IForPlayingSound
{
    public void PlaySound(SoundId soundId);
}
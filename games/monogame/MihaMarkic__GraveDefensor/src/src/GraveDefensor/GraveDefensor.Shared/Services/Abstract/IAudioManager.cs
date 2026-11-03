using System.Threading;
using System.Threading.Tasks;

namespace GraveDefensor.Shared.Services.Abstract
{
    public interface IAudioManager
    {
        Task PlaySoundEffectAsync(string soundName, CancellationToken ct);
    }
}

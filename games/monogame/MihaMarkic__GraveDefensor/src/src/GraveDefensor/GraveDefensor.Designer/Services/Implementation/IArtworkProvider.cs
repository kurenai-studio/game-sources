using Avalonia.Media.Imaging;
using System.Threading;
using System.Threading.Tasks;

namespace GraveDefensor.Designer.Services.Implementation
{
    public interface IArtworkProvider
    {
        Task<IBitmap?> GetEnemyThumbprintAsync(string name, CancellationToken ct = default);
        Task<IBitmap?> GetWeaponThumbprintAsync(string name, CancellationToken ct = default);
    }
}

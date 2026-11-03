using Avalonia.Media.Imaging;
using GraveDefensor.Engine.Designer.ViewModels;
using System.IO;
using System.Threading;
using System.Threading.Tasks;

namespace GraveDefensor.Designer.Services.Implementation
{
    public class ArtworkProvider : IArtworkProvider
    {
        readonly SettingsViewModel settings;
        public ArtworkProvider(SettingsViewModel settings)
        {
            this.settings = settings;
        }
        public Task<IBitmap?> GetEnemyThumbprintAsync(string name, CancellationToken ct = default) => GetThumbprintAsync(name, "Enemies", ct);
        public Task<IBitmap?> GetWeaponThumbprintAsync(string name, CancellationToken ct = default) => GetThumbprintAsync(name, "Weapons", ct);

        Task<IBitmap?> GetThumbprintAsync(string name, string type, CancellationToken ct = default)
        {
            if (!string.IsNullOrWhiteSpace(settings.AssetsPath))
            {
                string path = Path.Combine(settings.AssetsPath, type, $"{name}_thumbprint.png");
                return Task.FromResult<IBitmap?>(new Bitmap(path));
            }
            return Task.FromResult<IBitmap?>(null);
        }
    }
}

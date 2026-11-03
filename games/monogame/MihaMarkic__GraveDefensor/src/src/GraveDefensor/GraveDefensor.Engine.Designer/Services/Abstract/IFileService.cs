using GraveDefensor.Engine.Designer.Models;
using System;
using System.Threading;
using System.Threading.Tasks;

namespace GraveDefensor.Engine.Designer.Services.Abstract
{
    public interface IFileService
    {
        Task<Configuration> LoadConfigurationAsync(CancellationToken ct = default);
        Task SaveConfigurationAsync(Configuration config, CancellationToken ct = default);
        Task<Settings.Master> LoadGameSettingsAsync(string path, CancellationToken ct = default);
        Task SaveGameSettingsAsync(Settings.Master master, string path, CancellationToken ct = default);
    }
}

using GraveDefensor.Engine.Designer.Models;
using GraveDefensor.Engine.Designer.Services.Abstract;
using System;
using System.Diagnostics;
using System.IO;
using System.Threading;
using System.Threading.Tasks;
using System.Xml.Linq;
using System.Xml.Serialization;

namespace GraveDefensor.Engine.Designer.Services.Implementation
{
    public class FileService : IFileService
    {
        readonly string configurationFile;
        public FileService()
        {
            configurationFile = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "GraveDefensor.Designer", "config.xml");
        }
        public async Task<Configuration> LoadConfigurationAsync(CancellationToken ct = default)
        {
            if (File.Exists(configurationFile))
            {
                try
                {
                    using (var stream = File.OpenRead(configurationFile))
                    {
                        var doc = await XDocument.LoadAsync(stream, LoadOptions.None, ct);
                        return new Configuration
                        {
                            AssetsPath = (string)doc.Root.Attribute(nameof(Configuration.AssetsPath))
                        };
                    }
                }
                catch (Exception ex)
                {
                    Debug.WriteLine($"Failed to load configuration: {ex.Message}");
                }
            }
            return new Configuration();
        }
        public Task SaveConfigurationAsync(Configuration config, CancellationToken ct = default)
        {
            var doc = new XDocument(
                new XElement(nameof(Configuration), new XAttribute(nameof(Configuration.AssetsPath), config.AssetsPath))
            );
            try
            {
                if (File.Exists(configurationFile))
                {
                    File.Delete(configurationFile);
                }
                else
                {
                    Directory.CreateDirectory(Path.GetDirectoryName(configurationFile));
                }
                using (var stream = File.OpenWrite(configurationFile))
                {
                    return doc.SaveAsync(stream, SaveOptions.None, ct);
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"Failed to save configuration: {ex.Message}");
                return Task.FromException(ex);
            }
        }

        public Task<Settings.Master> LoadGameSettingsAsync(string path, CancellationToken ct = default)
        {
            var serializer = new XmlSerializer(typeof(Settings.Master));
            using (var stream = File.OpenRead(path))
            {
                var master = (Settings.Master)serializer.Deserialize(stream);
                return Task.FromResult(master);
            }
        }

        public Task SaveGameSettingsAsync(Settings.Master master, string path, CancellationToken ct = default)
        {
            var serializer = new XmlSerializer(typeof(Settings.Master));
            using (var stream = File.OpenWrite(path))
            {
                serializer.Serialize(stream, master);
                return Task.CompletedTask;
            }
        }
    }
}

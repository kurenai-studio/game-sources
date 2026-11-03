using System;

namespace Snake.Core.Storages
{
    /// <summary>
    /// Settings storage implementation for desktop platforms (Windows, macOS, Linux).
    /// Stores settings in the ApplicationData folder.
    /// </summary>
    public class DesktopSettingsStorage : BaseSettingsStorage
    {
        protected override Environment.SpecialFolder SpecialFolderPath => Environment.SpecialFolder.ApplicationData;
    }
}

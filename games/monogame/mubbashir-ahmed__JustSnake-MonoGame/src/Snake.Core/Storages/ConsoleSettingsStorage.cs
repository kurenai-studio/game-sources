using System;

namespace Snake.Core.Storages
{
    /// <summary>
    /// Settings storage implementation for console platforms.
    /// Stores settings in the ApplicationData folder.
    /// </summary>
    public class ConsoleSettingsStorage : BaseSettingsStorage
    {
        protected override Environment.SpecialFolder SpecialFolderPath => Environment.SpecialFolder.ApplicationData;
    }
}

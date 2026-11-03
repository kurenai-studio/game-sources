using System;

namespace Snake.Core.Storages
{
    /// <summary>
    /// Settings storage implementation for mobile platforms (Android, iOS).
    /// Stores settings in the Personal folder.
    /// </summary>
    public class MobileSettingsStorage : BaseSettingsStorage
    {
        protected override Environment.SpecialFolder SpecialFolderPath => Environment.SpecialFolder.Personal;
    }
}

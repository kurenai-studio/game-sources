using Settings = GraveDefensor.Engine.Settings;
using System;

namespace GraveDefensor.Shared
{
    public static class Assets
    {
        public static class Weapons
        {
            public static string MiniGun = GetAbsolute(nameof(MiniGun));
            public static string Vulcan = GetAbsolute(nameof(Vulcan));
            public static string GetAbsolute(string name) => $"{nameof(Weapons)}/{name}";

            public static string FromSettings(Settings.Weapon weapon)
            {
                switch (weapon)
                {
                    case Settings.MiniGun _: return MiniGun;
                    case Settings.Vulcan _: return Vulcan;
                    default:
                        throw new ArgumentOutOfRangeException(nameof(weapon));
                }
            }
        }
        public static class Fonts
        {
            public static string WeaponDescriptionFont = $"{nameof(Fonts)}/Hud";
        }
        public static class Scenes
        {
            public static string Battle1 = GetAbsolute(nameof(Battle1));
            public static string GetAbsolute(string name) => $"{nameof(Scenes)}/{name}";
        }
    }
}

using System;

namespace GraveDefensor.Engine.Settings
{
    public class Weapons
    {
        public MiniGun MiniGun { get; set; }
        public Vulcan Vulcan { get; set; }
        public Cannon Cannon { get; set; }
        public Weapon[] FromNames(string[] names)
        {
            var result = new Weapon[names.Length];
            for (int i = 0; i < result.Length; i++)
            {
                result[i] = FromName(names[i]);
            }
            return result;
        }

        public Weapon FromName(string name)
        {
            switch (name)
            {
                case nameof(MiniGun): return MiniGun;
                case nameof(Vulcan): return Vulcan;
                case nameof(Cannon): return Cannon;
                default:
                    throw new ArgumentOutOfRangeException(nameof(name));
            }
        }
    }
}

using GraveDefensor.Shared.Service.Abstract;
using Microsoft.Xna.Framework;
using System;
using Settings = GraveDefensor.Engine.Settings;

namespace GraveDefensor.Shared.Drawable.Weapons
{
    public static class WeaponFactory
    {
        public static IWeapon GetWeaponFromPool<TSettings>(IInitContext context, TSettings settings, Vector2 center)
            where TSettings : Settings.Weapon
        {
            IWeapon weapon;
            switch (settings)
            {
                case Settings.MiniGun miniGunSettings:
                    var miniGun = context.ObjectPool.GetObject<MiniGun>();
                    miniGun.Init(context, miniGunSettings, center);
                    weapon = miniGun;
                    break;
                //case Settings.Vulcan vulcan:
                //    weapon = pool.GetObject<Vulcan>();
                //    break;
                default:
                    throw new ArgumentException($"No matching weapon for {typeof(TSettings)}", nameof(settings));
            }
            return weapon;
        }
    }
}

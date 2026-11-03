using GraveDefensor.Shared.Service.Abstract;
using GraveDefensor.Shared.Services.Implementation;
using Microsoft.Xna.Framework;
using System;
using Settings = GraveDefensor.Engine.Settings;

namespace GraveDefensor.Shared.Drawable.Weapons
{
    public class MiniGun : RotationalWeapon<Settings.MiniGun>
    {
        internal override string WeaponAssetName => Assets.Weapons.MiniGun;
        public override void Init(IInitContext context, Settings.MiniGun settings, Vector2 center)
        {
            base.Init(context, settings, center);
        }
        public override void Update(UpdateContext context, IEnemyWave waves)
        {
            base.Update(context, waves);
        }
    }
}

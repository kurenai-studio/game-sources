using GraveDefensor.Shared.Core;
using GraveDefensor.Shared.Service.Abstract;
using GraveDefensor.Shared.Services.Implementation;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using System;
using Settings = GraveDefensor.Engine.Settings;

namespace GraveDefensor.Shared.Drawable.Weapons
{
    public abstract class RotationalWeapon<T> : Weapon<T>
        where T : Settings.RotationalWeapon
    {
        Texture2D weapon;
        public Vector2 CenterOffset { get; private set; }
        public double Rotation { get; private set; }
        internal abstract string WeaponAssetName { get; }
        public override void Init(IInitContext context, T settings, Vector2 center)
        {
            base.Init(context, settings, center);
        }
        public override void InitContent(IInitContentContext context)
        {
            base.InitContent(context);
            weapon = context.Load<Texture2D>(WeaponAssetName);
            CenterOffset = new Vector2(Settings.CenterOffsetX ?? weapon.Width / 2, Settings.CenterOffsetY ?? weapon.Height / 2);
            Size = weapon.Bounds.Size;
        }
        public override void Update(UpdateContext context, IEnemyWave wave)
        {
            base.Update(context, wave);
            var result = GetEnemyMostNearTheEndAndInTrackingRange(Center, wave.Sets, Settings.TrackingRange, Settings.FiringRange);
            if (result.HasValue)
            {
                (var enemy, bool inFiringRange) = result.Value;
                var angle = Path.GetAngleBetweenVectors(Center, enemy.Center);
                Rotation = MathOps.CalculateRotation(angle, Rotation, MathOps.CalculateMaxRotation(context.GameTime.ElapsedGameTime, Settings.RotationalSpeed));
                switch (FiringState)
                {
                    case FiringState.Idle:
                        if (Math.Abs(MathOps.CalculateMinAngleDifference(Rotation, angle)) < 0.1)
                        {
                            TransitionToFiring();
                            enemy.Hit(Settings.Power);
                            FireColorTransition.Start(Color.Red, Color.White, context.GameTime.TotalGameTime, TimeToNextFiringState);
                        }
                        break;
                    case FiringState.Firing:
                        FireColorTransition.Update(context.GameTime.TotalGameTime);
                        break;
                }
            }
            
        }

        public override void DrawContent(IDrawContext context)
        {
            Color color;
            switch (FiringState)
            {
                case FiringState.Firing:
                    color = FireColorTransition.Current;
                    break;
                default:
                    color = Color.White;
                    break;
            }
            context.Draw(weapon, Center, sourceRectangle: null, color, (float)Rotation, CenterOffset, Vector2.One, SpriteEffects.None, 0);
        }
        internal override void DrawHud(IDrawContext context)
        {
            DrawReloadTime(context, CenterOffset, (float)Rotation);
        }
    }
}

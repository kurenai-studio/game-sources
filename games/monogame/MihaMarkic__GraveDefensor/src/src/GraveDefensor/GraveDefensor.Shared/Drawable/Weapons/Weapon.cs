using GraveDefensor.Shared.Drawable.Enemies;
using GraveDefensor.Shared.Service.Abstract;
using GraveDefensor.Shared.Services.Implementation;
using GraveDefensor.Windows.Actions;
using Microsoft.Xna.Framework;
using System;
using System.Collections.Generic;
using Settings = GraveDefensor.Engine.Settings;

namespace GraveDefensor.Shared.Drawable.Weapons
{
    public abstract class Weapon<T> : ClickableDrawable, IWeapon
        where T : Settings.Weapon
    {
        public Vector2 Center { get; private set; }
        public Point Size { get; protected set; }
        protected T Settings { get; private set; }
        public FiringState FiringState { get; private set; }
        public TimeSpan TimeToNextFiringState { get; private set; }
        public ColorTransitionAction FireColorTransition { get; private set; }
        public virtual void Init(IInitContext context, T settings, Vector2 center)
        {
            base.Init();
            Settings = settings;
            Center = center;
            IsEnabled = true;
            FiringState = FiringState.Idle;
            FireColorTransition = Globals.ObjectPool.GetObject<ColorTransitionAction>().WithStartColor(Color.Red);
        }
        internal void TransitionToFiring()
        {
            TimeToNextFiringState = TimeSpan.FromMilliseconds(Settings.FiringTime);
            FiringState = FiringState.Firing;
        }
        internal void TransitionToIdle()
        {
            TimeToNextFiringState = TimeSpan.Zero;
            FiringState = FiringState.Idle;
        }
        internal void TransitionToReloading()
        {
            TimeToNextFiringState = TimeSpan.FromMilliseconds(Settings.ReloadTime);
            FiringState = FiringState.Reloading;
        }
        public virtual void Update(UpdateContext context, IEnemyWave waves)
        {
            switch (FiringState)
            {
                case FiringState.Reloading:
                    TimeToNextFiringState -= context.GameTime.ElapsedGameTime;
                    if (TimeToNextFiringState < TimeSpan.Zero)
                    {
                        TransitionToIdle();
                    }
                    break;
                case FiringState.Firing:
                    TimeToNextFiringState -= context.GameTime.ElapsedGameTime;
                    if (TimeToNextFiringState < TimeSpan.Zero)
                    {
                        TransitionToReloading();
                    }
                    break;
            }
            base.Update(context);
        }
        public override void Draw(IDrawContext context)
        {
            DrawContent(context);
            DrawHud(context);
            base.Draw(context);
        }
        public abstract void DrawContent(IDrawContext context);
        internal abstract void DrawHud(IDrawContext context);
        internal void DrawReloadTime(IDrawContext context, Vector2 offset, float angle)
        {
            const float width = 40;
            const float height = 10;
            var rotationMatrix = Matrix.CreateRotationZ(angle);
            Vector2 Rotate(float w) => Center + Vector2.Transform(new Vector2(Size.X - (width-w) - offset.X, Size.Y - height - offset.Y), rotationMatrix);
            switch (FiringState)
            {
                case FiringState.Idle:
                    context.FillRectangle(Rotate(0),new Vector2(width, height),Color.Green, angle);
                    break;
                case FiringState.Firing:
                    context.FillRectangle(Rotate(0), new Vector2(width, height), Color.Black, angle);
                    break;
                case FiringState.Reloading:
                    float loadedPercent = 1 - (float)TimeToNextFiringState.TotalMilliseconds / Settings.ReloadTime;
                    float loadedWidth = width * loadedPercent;
                    context.FillRectangle(Rotate(0), new Vector2(loadedWidth, height), Color.Green, angle);
                    context.FillRectangle(Rotate(loadedWidth), new Vector2(width - loadedWidth, height), Color.Green, angle);
                    break;
            }
        }
        internal static void GetEnemiesInRange(Vector2 center, IEnemySet[] waves, double trackingRange, double firingRange,
            IList<Enemy> enemiesInTrackingRange, IList<Enemy> enemiesInFiringRange)
        {
            foreach (var wave in waves)
            {
                if (wave.Status == EnemySetStatus.Spawning || wave.Status == EnemySetStatus.WaitingForFinish)
                {
                    foreach (var enemy in wave.Enemies)
                    {
                        float distance = Math.Abs(Vector2.Distance(center, enemy.Center));
                        if (distance < trackingRange)
                        {
                            enemiesInTrackingRange.Add(enemy);
                            if (distance < firingRange)
                            {
                                enemiesInFiringRange.Add(enemy);
                            }
                        }
                    }
                }
            }
        }

        internal static (Enemy Enemy, bool IsInFiringRange)? GetEnemyMostNearTheEndAndInTrackingRange(Vector2 center, IEnemySet[] enemySets, double trackingRange, double firingRange)
        {
            (Enemy Enemy, bool IsInFiringRange)? result = null;
            foreach (var enemySet in enemySets)
            {
                if (enemySet.Status == EnemySetStatus.Spawning || enemySet.Status == EnemySetStatus.WaitingForFinish)
                {
                    foreach (var enemy in enemySet.Enemies)
                    {
                        if (enemy.IsTarget)
                        {
                            float distance = Math.Abs(Vector2.Distance(center, enemy.Center));
                            if (distance < trackingRange)
                            {
                                if (enemy.DistanceToEnd < (result?.Enemy.DistanceToEnd ?? double.MaxValue))
                                {
                                    result = (enemy, distance < firingRange);
                                }
                            }
                        }
                    }
                }
            }
            return result;
        }
    }
}

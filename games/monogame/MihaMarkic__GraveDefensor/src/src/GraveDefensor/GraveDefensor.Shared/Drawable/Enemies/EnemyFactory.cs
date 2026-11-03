using GraveDefensor.Engine.Services.Abstract;
using System;
using Settings = GraveDefensor.Engine.Settings;

namespace GraveDefensor.Shared.Drawable.Enemies
{
    public static class EnemyFactory
    {
        public static Enemy GetEnemyFromPool<TSettings>(IObjectPool pool, TSettings settings)
            where TSettings: Settings.Enemy
        {
            Enemy enemy;
            switch (settings)
            {
                case Settings.CreepyWorm creepyWorm:
                    enemy = pool.GetObject<CreepyWorm>();
                    break;
                case Settings.Skeleton skeleton:
                    enemy = pool.GetObject<Skeleton>();
                    break;
                default:
                    throw new ArgumentException($"No matching enemy for {typeof(TSettings)}", nameof(settings));
            }
            return enemy;
        }
    }
}

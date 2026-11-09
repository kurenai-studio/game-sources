using JGM.Gameplay.Creeps;
using JGM.Gameplay.Turrets.Projectiles;
using UnityEngine;

namespace JGM.Gameplay.Turrets
{
    public interface ITurret
    {
        GameObject GameObject { get; }

        void Initialize(CreepSpawner creepSpawner, ProjectilePool projectilePool);
    }
}

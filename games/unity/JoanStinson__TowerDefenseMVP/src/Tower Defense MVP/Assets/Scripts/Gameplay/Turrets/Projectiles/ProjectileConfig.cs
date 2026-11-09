using JGM.Gameplay.Combat;
using System.Collections.Generic;
using UnityEngine;

namespace JGM.Gameplay.Turrets.Projectiles
{
    [CreateAssetMenu(fileName = "New Projectile Config", menuName = "Turrets/Projectiles/Projectile Config")]
    public class ProjectileConfig : ScriptableObject
    {
        public float MoveSpeed = 10f;
        public float DurationToDestroy = 7f;
        public List<CombatEffectConfig> Effects;
    }
}

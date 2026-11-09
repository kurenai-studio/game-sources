using AYellowpaper;
using JGM.Gameplay.Turrets.Projectiles;
using UnityEngine;

namespace JGM.Gameplay.Turrets
{
    [CreateAssetMenu(fileName = "New Turret Config", menuName = "Turrets/Turret Config")]
    public class TurretConfig : ScriptableObject
    {
        public InterfaceReference<IProjectile, MonoBehaviour> ProjectilePrefab;
        public float ShootSpeed = 2f;
    }
}

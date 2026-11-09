using UnityEngine;
using UnityEngine.Pool;

namespace JGM.Gameplay.Turrets.Projectiles
{
    public interface IProjectile
    {
        GameObject GameObject { get; }

        void SetPool(ObjectPool<IProjectile> pool);
        void Initialize(Vector3 position, Transform target);
        void Release();
    }
}

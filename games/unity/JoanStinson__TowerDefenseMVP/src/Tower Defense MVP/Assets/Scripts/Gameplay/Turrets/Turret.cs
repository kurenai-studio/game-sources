using JGM.Gameplay.Creeps;
using JGM.Gameplay.Turrets.Projectiles;
using System.Collections;
using UnityEngine;

namespace JGM.Gameplay.Turrets
{
    public class Turret : MonoBehaviour, ITurret
    {
        public GameObject GameObject => gameObject;

        [SerializeField]
        private TurretConfig config;

        private CreepSpawner creepSpawner;
        private ProjectilePool projectilePool;
        private bool turnedOn;

        public void Initialize(CreepSpawner creepSpawner, ProjectilePool projectilePool)
        {
            this.creepSpawner = creepSpawner;
            this.projectilePool = projectilePool;
            turnedOn = true;
            StartCoroutine(Shoot());
        }

        private IEnumerator Shoot()
        {
            while (turnedOn)
            {
                yield return new WaitForSeconds(config.ShootSpeed);
                SpawnProjectile(GetClosestTarget());
            }
        }

        private void SpawnProjectile(Transform target)
        {
            if (target != null)
            {
                var projectile = projectilePool.Get(config.ProjectilePrefab.Value.GameObject);
                projectile.Initialize(transform.position, target);
            }
        }

        private Transform GetClosestTarget()
        {
            Transform closestTarget = null;
            float closestSqrDistance = float.MaxValue;
            Vector3 myPos = transform.position;

            foreach (var target in creepSpawner.GetActiveCreeps())
            {
                Vector3 targetPos = target.GameObject.transform.position;
                float sqrDistance = (targetPos - myPos).sqrMagnitude;

                if (sqrDistance < closestSqrDistance)
                {
                    closestSqrDistance = sqrDistance;
                    closestTarget = target.GameObject.transform;
                }
            }

            return closestTarget;
        }
    }
}

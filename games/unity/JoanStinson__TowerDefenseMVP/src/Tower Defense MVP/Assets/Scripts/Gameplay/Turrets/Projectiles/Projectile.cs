using JGM.Gameplay.Combat;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Pool;

namespace JGM.Gameplay.Turrets.Projectiles
{
    public class Projectile : MonoBehaviour, IProjectile
    {
        public GameObject GameObject => gameObject;

        [SerializeField]
        private ProjectileConfig config;

        private ObjectPool<IProjectile> pool;
        private List<ICombatEffect> effects = new();
        private Transform target;
        private Vector3 targetDirection;

        public void SetPool(ObjectPool<IProjectile> pool)
        {
            this.pool = pool;

            foreach (var effectConfig in config.Effects)
            {
                effects.Add(effectConfig.CreateEffect());
            }
        }

        public void Initialize(Vector3 position, Transform target)
        {
            transform.position = position;
            this.target = target;
            targetDirection = Vector3.zero;
            StartCoroutine(DestroyAfterDuration());
        }

        private IEnumerator DestroyAfterDuration()
        {
            yield return new WaitForSeconds(config.DurationToDestroy);
            if (gameObject.activeSelf)
            {
                pool.Release(this);
            }
        }

        private void Update()
        {
            Move();
        }

        private void Move()
        {
            var speed = config.MoveSpeed * Time.deltaTime;

            if (target != null)
            {
                transform.position = Vector3.MoveTowards(transform.position, target.position, speed);
                targetDirection = (target.position - transform.position).normalized;
            }
            else
            {
                transform.position += targetDirection * speed;
            }
        }

        private void OnTriggerEnter(Collider other)
        {
            if (other.CompareTag("Creep"))
            {
                foreach (var effect in effects)
                {
                    effect.Apply(other.gameObject);
                }

                pool.Release(this);
            }
        }

        public void Release()
        {
            pool.Release(this);
        }
    }
}

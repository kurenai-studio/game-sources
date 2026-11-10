using UnityEngine;

namespace LD55
{
    public class Ghost : MonoBehaviour
    {
        #region Inspector

        [SerializeField] Transform _Visual;

        [SerializeField] float _Cooldown = 1;

        [SerializeField] float _AttackRadius = 10f;

        #endregion

        static readonly Collider[] s_Buffer = new Collider[64];

        EnemyZone _enemyZone;

        float _cooldownTimer = 0;

        public static Ghost Create(Vector3 position)
        {
            var ghost = Instantiate(GameConfig.Instance.ghostPrefab, position, Quaternion.identity);
            return ghost;
        }

        void OnTriggerEnter(Collider other)
        {
            if (other.GetComponentInParent<EnemyZone>() is EnemyZone enemyZone) {
                _enemyZone = enemyZone;
            }
        }

        void OnDrawGizmosSelected()
        {
            Gizmos.color = Color.blue;
            Gizmos.DrawWireSphere(transform.position, _AttackRadius);
        }

        void Update()
        {
            ProcessEnemies();
        }

        void ProcessEnemies()
        {
            _cooldownTimer += Time.deltaTime;
            if (_cooldownTimer < _Cooldown)
                return;

            _cooldownTimer = 0;

            void shoot(Transform target)
            {
                var direction = target.position - transform.position;
                direction.Normalize();
                _Visual.rotation = Quaternion.LookRotation(direction, Vector3.up);
                Projectile.Create(transform.position, direction);
            }

            if (_enemyZone != null)
            {
                foreach (var enemy in _enemyZone.Enemies)
                {
                    if (enemy == null)
                        continue;

                    shoot(enemy.transform);
                    return;
                }
            }

            var count = Physics.OverlapSphereNonAlloc(transform.position, _AttackRadius, s_Buffer);
            if (count > 0)
            {
                for (int i = 0; i < count; i++)
                {
                    if (s_Buffer[i].GetComponentInParent<Enemy>() is Enemy enemy)
                    {
                        shoot(enemy.transform);
                        return;
                    }
                }
            }
        }
    }
}

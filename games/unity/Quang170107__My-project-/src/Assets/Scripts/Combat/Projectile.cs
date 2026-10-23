using UnityEngine;

namespace SimpleRPG
{
    public class Projectile : MonoBehaviour
    {
        public bool isPlayerProjectile = false;
        public float damage = 20f;
        public float speed = 12f;
        public float lifeTime = 3f;
        public float knockback = 5f;

        private Vector2 _direction;
        private Rigidbody2D _rb;

        public void Initialize(Vector2 direction, float projSpeed, float projDamage, bool fromPlayer, float knock = 4f)
        {
            _direction = direction.normalized;
            speed = projSpeed;
            damage = projDamage;
            isPlayerProjectile = fromPlayer;
            knockback = knock;

            _rb = GetComponent<Rigidbody2D>();
            if (_rb != null)
            {
                _rb.linearVelocity = _direction * speed;
            }

            // Rotate towards flight direction
            float angle = Mathf.Atan2(_direction.y, _direction.x) * Mathf.Rad2Deg;
            transform.rotation = Quaternion.Euler(0, 0, angle);

            Destroy(gameObject, lifeTime);
        }

        private void FixedUpdate()
        {
            if (_rb == null)
            {
                transform.position += (Vector3)(_direction * speed * Time.fixedDeltaTime);
            }
        }

        private void OnTriggerEnter2D(Collider2D other)
        {
            if (isPlayerProjectile)
            {
                // Can hit enemies
                var enemy = other.GetComponent<EnemyBase>();
                if (enemy != null && enemy.IsAlive)
                {
                    enemy.TakeDamage(damage, _direction, knockback);
                    AudioManager.Instance?.PlaySound("hit");
                    Destroy(gameObject);
                    return;
                }
            }
            else
            {
                // Can hit player
                if (other.CompareTag("Player"))
                {
                    var player = other.GetComponent<PlayerController>();
                    if (player != null)
                    {
                        player.TakeDamage(damage, _direction, knockback);
                        AudioManager.Instance?.PlaySound("hurt");
                        Destroy(gameObject);
                        return;
                    }
                }
            }

            // Hit dungeon wall or pillar
            if (other.GetComponent<DungeonObstacle>() != null || other.name.StartsWith("Wall") || other.name.StartsWith("Pillar"))
            {
                Destroy(gameObject);
            }
        }
    }
}

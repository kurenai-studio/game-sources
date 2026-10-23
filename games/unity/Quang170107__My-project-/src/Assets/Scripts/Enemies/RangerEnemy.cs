using System.Collections;
using UnityEngine;

namespace SimpleRPG
{
    public class RangerEnemy : EnemyBase
    {
        private float _shootTimer = 0f;
        private const float ShootInterval = 2.2f;
        private const float PreferredDist = 5.2f;

        protected override void Awake()
        {
            base.Awake();
            enemyName = "Crimson Spitter";
            maxHealth = 28f;
            currentHealth = maxHealth;
            moveSpeed = 3.2f;
            contactDamage = 8f;
            xpDrop = 20;

            spriteRenderer.sprite = SpriteFactory.GetSprite("ranger");
            var col = GetComponent<CircleCollider2D>();
            col.radius = 0.4f;
        }

        protected override void UpdateAI()
        {
            _shootTimer += Time.deltaTime;

            float dist = Vector2.Distance(transform.position, playerTransform.position);
            Vector2 dirToPlayer = ((Vector2)playerTransform.position - (Vector2)transform.position).normalized;

            // Kite movement
            Vector2 moveDir = Vector2.zero;
            if (dist < PreferredDist - 1.2f)
            {
                moveDir = -dirToPlayer;
            }
            else if (dist > PreferredDist + 1.2f)
            {
                moveDir = dirToPlayer;
            }
            else
            {
                moveDir = new Vector2(-dirToPlayer.y, dirToPlayer.x);
            }

            float finalSpeed = moveSpeed * CurrentSpeedModifier;
#if UNITY_6000_0_OR_NEWER
            rb.linearVelocity = Vector2.Lerp(rb.linearVelocity, moveDir * finalSpeed, 10f * Time.deltaTime);
#else
            rb.velocity = Vector2.Lerp(rb.velocity, moveDir * finalSpeed, 10f * Time.deltaTime);
#endif

            if (Mathf.Abs(dirToPlayer.x) > 0.05f)
                spriteRenderer.flipX = dirToPlayer.x < 0f;

            // Aim and shoot
            if (_shootTimer >= ShootInterval)
            {
                _shootTimer = 0f;
                StartCoroutine(ShootRoutine(dirToPlayer));
            }
        }

        private IEnumerator ShootRoutine(Vector2 dir)
        {
            isAttacking = true;
#if UNITY_6000_0_OR_NEWER
            rb.linearVelocity = Vector2.zero;
#else
            rb.velocity = Vector2.zero;
#endif

            Color orig = spriteRenderer.color;
            spriteRenderer.color = new Color(1f, 0.9f, 0.2f, 1f);
            yield return new WaitForSeconds(0.35f);
            spriteRenderer.color = orig;

            SpawnProjectile(dir);
            AudioManager.Instance?.PlaySound("shoot");

            yield return new WaitForSeconds(0.15f);
            isAttacking = false;
        }

        private void SpawnProjectile(Vector2 dir)
        {
            var projGo = new GameObject("EnemyProjectile");
            projGo.transform.position = transform.position + (Vector3)(dir * 0.5f);

            var sr = projGo.AddComponent<SpriteRenderer>();
            sr.sprite = SpriteFactory.GetSprite("projectile_enemy");
            sr.sortingOrder = 14;

            var col = projGo.AddComponent<CircleCollider2D>();
            col.isTrigger = true;
            col.radius = 0.25f;

            var pRb = projGo.AddComponent<Rigidbody2D>();
            pRb.gravityScale = 0f;

            var proj = projGo.AddComponent<Projectile>();
            proj.Initialize(dir, 7.5f, contactDamage * 0.8f, false, 3.5f);
        }
    }
}

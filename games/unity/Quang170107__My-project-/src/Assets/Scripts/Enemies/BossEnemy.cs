using System.Collections;
using UnityEngine;

namespace SimpleRPG
{
    public class BossEnemy : EnemyBase
    {
        private float _attackCycleTimer = 0f;
        private int _attackPattern = 0;
        private bool _enraged = false;

        protected override void Awake()
        {
            base.Awake();
            enemyName = "The Void Sovereign";
            maxHealth = 260f;
            currentHealth = maxHealth;
            moveSpeed = 2.4f;
            contactDamage = 20f;
            xpDrop = 150;
            coinDropChance = 100;
            potionDropChance = 100;

            spriteRenderer.sprite = SpriteFactory.GetSprite("boss");
            var col = GetComponent<CircleCollider2D>();
            col.radius = 0.75f;
            transform.localScale = Vector3.one * 1.35f;
        }

        protected override void UpdateAI()
        {
            _attackCycleTimer += Time.deltaTime;

            // Phase 2: dưới 50% máu boss nổi giận - nhanh hơn, tấn công dày hơn
            if (!_enraged && currentHealth <= maxHealth * 0.5f)
            {
                _enraged = true;
                moveSpeed *= 1.3f;
                CameraFollow.Instance?.Shake(0.4f, 0.4f);
                AudioManager.Instance?.PlaySound("special");
                GameUI.Instance?.ShowBanner("THE VOID SOVEREIGN ENRAGES!", 2f);
            }

            Vector2 dir = ((Vector2)playerTransform.position - (Vector2)transform.position).normalized;

            // Slowly pursue with status effect modifier
            float finalSpeed = moveSpeed * CurrentSpeedModifier;
#if UNITY_6000_0_OR_NEWER
            rb.linearVelocity = Vector2.Lerp(rb.linearVelocity, dir * finalSpeed, 6f * Time.deltaTime);
#else
            rb.velocity = Vector2.Lerp(rb.velocity, dir * finalSpeed, 6f * Time.deltaTime);
#endif

            if (Mathf.Abs(dir.x) > 0.05f)
                spriteRenderer.flipX = dir.x < 0f;

            if (_attackCycleTimer >= (_enraged ? 2.0f : 3.0f) && !isAttacking)
            {
                _attackCycleTimer = 0f;
                _attackPattern = (_attackPattern + 1) % 2;

                if (_attackPattern == 0)
                {
                    StartCoroutine(RadialBulletRingRoutine());
                }
                else
                {
                    StartCoroutine(ChargeDashRoutine(dir));
                }
            }
        }

        private IEnumerator RadialBulletRingRoutine()
        {
            isAttacking = true;
#if UNITY_6000_0_OR_NEWER
            rb.linearVelocity = Vector2.zero;
#else
            rb.velocity = Vector2.zero;
#endif

            AudioManager.Instance?.PlaySound("special");
            CameraFollow.Instance?.Shake(0.3f, 0.3f);
            Color orig = spriteRenderer.color;
            spriteRenderer.color = new Color(1f, 0.4f, 0.1f, 1f);
            yield return new WaitForSeconds(0.45f);
            spriteRenderer.color = orig;

            int count = _enraged ? 16 : 10;
            float angleStep = 360f / count;
            for (int i = 0; i < count; i++)
            {
                float angle = i * angleStep * Mathf.Deg2Rad;
                Vector2 shotDir = new Vector2(Mathf.Cos(angle), Mathf.Sin(angle));
                SpawnBossBullet(shotDir);
            }
            AudioManager.Instance?.PlaySound("shoot");

            yield return new WaitForSeconds(0.3f);
            isAttacking = false;
        }

        private void SpawnBossBullet(Vector2 dir)
        {
            var projGo = new GameObject("BossBullet");
            projGo.transform.position = transform.position + (Vector3)(dir * 0.8f);

            var sr = projGo.AddComponent<SpriteRenderer>();
            sr.sprite = SpriteFactory.GetSprite("projectile_enemy");
            sr.color = new Color(1f, 0.85f, 0.2f);
            sr.sortingOrder = 14;

            var col = projGo.AddComponent<CircleCollider2D>();
            col.isTrigger = true;
            col.radius = 0.3f;

            var projRb = projGo.AddComponent<Rigidbody2D>();
            projRb.gravityScale = 0f;

            var proj = projGo.AddComponent<Projectile>();
            proj.Initialize(dir, 6.5f, 16f, false, 5f);
        }

        private IEnumerator ChargeDashRoutine(Vector2 dir)
        {
            isAttacking = true;
#if UNITY_6000_0_OR_NEWER
            rb.linearVelocity = Vector2.zero;
#else
            rb.velocity = Vector2.zero;
#endif

            Color orig = spriteRenderer.color;
            spriteRenderer.color = Color.red;
            yield return new WaitForSeconds(0.5f);
            spriteRenderer.color = orig;

            AudioManager.Instance?.PlaySound("dash");
#if UNITY_6000_0_OR_NEWER
            rb.linearVelocity = dir * (moveSpeed * 3.5f * CurrentSpeedModifier);
#else
            rb.velocity = dir * (moveSpeed * 3.5f * CurrentSpeedModifier);
#endif
            yield return new WaitForSeconds(0.55f);

#if UNITY_6000_0_OR_NEWER
            rb.linearVelocity = Vector2.zero;
#else
            rb.velocity = Vector2.zero;
#endif
            yield return new WaitForSeconds(0.25f);
            isAttacking = false;
        }

        protected override void Die()
        {
            LootManager.Instance?.SpawnCoin(transform.position + Vector3.left * 0.7f, 10);
            LootManager.Instance?.SpawnCoin(transform.position + Vector3.right * 0.7f, 10);
            LootManager.Instance?.SpawnPotion(transform.position + Vector3.up * 0.7f, 50f);
            LootManager.Instance?.SpawnChest(transform.position);

            base.Die();
        }
    }
}

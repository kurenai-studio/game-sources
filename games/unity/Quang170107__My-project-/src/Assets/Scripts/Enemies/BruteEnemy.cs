using System.Collections;
using UnityEngine;

namespace SimpleRPG
{
    public class BruteEnemy : EnemyBase
    {
        private float _slamCooldown = 0f;
        private const float SlamCooldownTime = 3.5f;

        protected override void Awake()
        {
            base.Awake();
            enemyName = "Armored Slime";
            maxHealth = 85f;
            currentHealth = maxHealth;
            moveSpeed = 2.1f;
            contactDamage = 16f;
            xpDrop = 35;
            coinDropChance = 80;
            potionDropChance = 35;

            spriteRenderer.sprite = SpriteFactory.GetSprite("brute");
            var col = GetComponent<CircleCollider2D>();
            col.radius = 0.55f;
        }

        protected override void UpdateAI()
        {
            if (_slamCooldown > 0f) _slamCooldown -= Time.deltaTime;

            float dist = Vector2.Distance(transform.position, playerTransform.position);
            Vector2 dir = ((Vector2)playerTransform.position - (Vector2)transform.position).normalized;

            if (dist < 2.4f && _slamCooldown <= 0f)
            {
                StartCoroutine(SlamRoutine());
                return;
            }

            // Steady march towards player with status effect speed modifier
            float finalSpeed = moveSpeed * CurrentSpeedModifier;
#if UNITY_6000_0_OR_NEWER
            rb.linearVelocity = Vector2.Lerp(rb.linearVelocity, dir * finalSpeed, 8f * Time.deltaTime);
#else
            rb.velocity = Vector2.Lerp(rb.velocity, dir * finalSpeed, 8f * Time.deltaTime);
#endif
            if (Mathf.Abs(dir.x) > 0.05f)
                spriteRenderer.flipX = dir.x < 0f;
        }

        private IEnumerator SlamRoutine()
        {
            isAttacking = true;
            _slamCooldown = SlamCooldownTime;
#if UNITY_6000_0_OR_NEWER
            rb.linearVelocity = Vector2.zero;
#else
            rb.velocity = Vector2.zero;
#endif

            Vector3 initScale = transform.localScale;
            Color origColor = spriteRenderer.color;

            float telegraphTime = 0.6f;
            float elapsed = 0f;
            while (elapsed < telegraphTime)
            {
                elapsed += Time.deltaTime;
                float t = elapsed / telegraphTime;
                transform.localScale = Vector3.Lerp(initScale, initScale * 1.3f, t);
                spriteRenderer.color = Color.Lerp(origColor, Color.red, t);
                yield return null;
            }

            AudioManager.Instance?.PlaySound("special");
            CameraFollow.Instance?.Shake(0.25f, 0.35f);

            var ringGo = new GameObject("BruteSlamWave");
            ringGo.transform.position = transform.position;
            var sr = ringGo.AddComponent<SpriteRenderer>();
            sr.sprite = SpriteFactory.CreateCircle(64, Color.clear, new Color(0.8f, 0.2f, 0.9f, 0.85f), 4);
            sr.sortingOrder = 8;
            var expand = ringGo.AddComponent<NovaExpandAnimation>();
            expand.maxRadius = 2.8f;
            expand.duration = 0.3f;

            Collider2D[] hits = Physics2D.OverlapCircleAll(transform.position, 2.8f);
            foreach (var hit in hits)
            {
                if (hit.CompareTag("Player"))
                {
                    var player = hit.GetComponent<PlayerController>();
                    if (player != null)
                    {
                        Vector2 pushDir = ((Vector2)player.transform.position - (Vector2)transform.position).normalized;
                        player.TakeDamage(24f, pushDir, 10f);
                    }
                }
            }

            yield return new WaitForSeconds(0.2f);
            transform.localScale = initScale;
            spriteRenderer.color = origColor;
            isAttacking = false;
        }
    }
}

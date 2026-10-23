using System.Collections;
using UnityEngine;

namespace SimpleRPG
{
    public class ChaserEnemy : EnemyBase
    {
        private float _bounceTimer = 0f;
        private float _lungeCooldown = 0f;

        protected override void Awake()
        {
            base.Awake();
            enemyName = "Slime Chaser";
            maxHealth = 35f;
            currentHealth = maxHealth;
            moveSpeed = 3.6f;
            contactDamage = 12f;
            xpDrop = 12;

            spriteRenderer.sprite = SpriteFactory.GetSprite("chaser");
            var col = GetComponent<CircleCollider2D>();
            col.radius = 0.4f;
        }

        protected override void UpdateAI()
        {
            if (_lungeCooldown > 0f) _lungeCooldown -= Time.deltaTime;

            float dist = Vector2.Distance(transform.position, playerTransform.position);
            Vector2 dir = ((Vector2)playerTransform.position - (Vector2)transform.position).normalized;

            if (dist < 2.8f && _lungeCooldown <= 0f)
            {
                StartCoroutine(LungeRoutine(dir));
                return;
            }

            // Bouncy hop movement with status effect modifier (Chill / Freeze)
            _bounceTimer += Time.deltaTime * 5f;
            float speedMod = Mathf.Max(0.2f, Mathf.Sin(_bounceTimer)) * CurrentSpeedModifier;
#if UNITY_6000_0_OR_NEWER
            rb.linearVelocity = Vector2.Lerp(rb.linearVelocity, dir * (moveSpeed * speedMod), 12f * Time.deltaTime);
#else
            rb.velocity = Vector2.Lerp(rb.velocity, dir * (moveSpeed * speedMod), 12f * Time.deltaTime);
#endif
            // Face player
            spriteRenderer.flipX = dir.x < 0;
        }

        private IEnumerator LungeRoutine(Vector2 dir)
        {
            isAttacking = true;
            _lungeCooldown = 2.2f;

            // Telegraph: squash down
            Vector3 initScale = transform.localScale;
            transform.localScale = new Vector3(initScale.x * 1.3f, initScale.y * 0.7f, initScale.z);
#if UNITY_6000_0_OR_NEWER
            rb.linearVelocity = Vector2.zero;
#else
            rb.velocity = Vector2.zero;
#endif
            yield return new WaitForSeconds(0.28f);

            // Lunge forward
            transform.localScale = new Vector3(initScale.x * 0.8f, initScale.y * 1.3f, initScale.z);
#if UNITY_6000_0_OR_NEWER
            rb.linearVelocity = dir * (moveSpeed * 2.8f * CurrentSpeedModifier);
#else
            rb.velocity = dir * (moveSpeed * 2.8f * CurrentSpeedModifier);
#endif
            yield return new WaitForSeconds(0.35f);

            transform.localScale = initScale;
            isAttacking = false;
        }
    }
}

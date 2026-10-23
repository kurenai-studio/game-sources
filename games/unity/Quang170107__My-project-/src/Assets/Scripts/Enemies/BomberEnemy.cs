using System.Collections;
using UnityEngine;

namespace SimpleRPG
{
    /// <summary>
    /// Quái tự nổ (lấy cảm hứng từ Enter the Gungeon): lao về phía người chơi, đứng lại
    /// nhấp nháy báo hiệu rồi nổ AOE. Vụ nổ làm đau cả quái khác (friendly fire),
    /// nên có thể dụ nó nổ vào đồng bọn. Nếu bị giết trước khi nổ thì không nổ.
    /// </summary>
    public class BomberEnemy : EnemyBase
    {
        private const float TriggerDistance = 1.7f;
        private const float FuseTime = 0.75f;
        private const float BlastRadius = 2.2f;
        private const float PlayerBlastDamage = 20f;
        private const float EnemyBlastDamage = 40f;

        private bool _selfDestructed;

        protected override bool CountsForCombo => !_selfDestructed;

        protected override void Awake()
        {
            base.Awake();
            enemyName = "Bomber Slime";
            maxHealth = 22f;
            currentHealth = maxHealth;
            moveSpeed = 4.2f;
            contactDamage = 6f;
            xpDrop = 18;
            coinDropChance = 60;
            potionDropChance = 10;

            spriteRenderer.sprite = SpriteFactory.GetSprite("bomber");
            var col = GetComponent<CircleCollider2D>();
            col.radius = 0.38f;
        }

        protected override void UpdateAI()
        {
            float dist = Vector2.Distance(transform.position, playerTransform.position);
            Vector2 dir = ((Vector2)playerTransform.position - (Vector2)transform.position).normalized;

            if (dist < TriggerDistance)
            {
                StartCoroutine(FuseRoutine());
                return;
            }

#if UNITY_6000_0_OR_NEWER
            rb.linearVelocity = Vector2.Lerp(rb.linearVelocity, dir * (moveSpeed * CurrentSpeedModifier), 10f * Time.deltaTime);
#else
            rb.velocity = Vector2.Lerp(rb.velocity, dir * (moveSpeed * CurrentSpeedModifier), 10f * Time.deltaTime);
#endif
            if (Mathf.Abs(dir.x) > 0.05f)
                spriteRenderer.flipX = dir.x < 0f;
        }

        protected override void DropLoot()
        {
            // Tự nổ thì không rơi gì: chỉ thưởng khi người chơi giết nó
            if (_selfDestructed) return;
            base.DropLoot();
        }

        private IEnumerator FuseRoutine()
        {
            isAttacking = true;
#if UNITY_6000_0_OR_NEWER
            rb.linearVelocity = Vector2.zero;
#else
            rb.velocity = Vector2.zero;
#endif

            // Vòng cảnh báo bán kính vụ nổ
            var warnGo = new GameObject("BomberWarning");
            warnGo.transform.position = transform.position;
            warnGo.transform.localScale = Vector3.one * (BlastRadius * 2f);
            var warnSr = warnGo.AddComponent<SpriteRenderer>();
            warnSr.sprite = SpriteFactory.CreateCircle(64, new Color(1f, 0.25f, 0.1f, 0.15f), new Color(1f, 0.35f, 0.1f, 0.85f), 3);
            warnSr.sortingOrder = 7;

            Vector3 initScale = transform.localScale;
            Color origColor = spriteRenderer.color;
            float elapsed = 0f;
            float nextBeep = 0f;

            while (elapsed < FuseTime)
            {
                if (!IsAlive)
                {
                    Destroy(warnGo);
                    yield break;
                }

                elapsed += Time.deltaTime;
                float t = elapsed / FuseTime;
                transform.localScale = Vector3.Lerp(initScale, initScale * 1.35f, t);

                // Tiếng bíp nhanh dần khi ngòi cháy
                if (elapsed >= nextBeep)
                {
                    AudioManager.Instance?.PlaySound("fuse", 0.5f);
                    nextBeep = elapsed + Mathf.Lerp(0.25f, 0.08f, t);
                }

                // Nhấp nháy nhanh dần
                float blink = Mathf.Sin(t * t * 40f) > 0f ? 1f : 0f;
                spriteRenderer.color = Color.Lerp(origColor, new Color(1f, 0.15f, 0.1f, 1f), blink);
                warnSr.color = new Color(1f, 1f, 1f, 0.5f + 0.5f * blink);
                yield return null;
            }

            Destroy(warnGo);
            if (!IsAlive) yield break;

            Explode();
        }

        private void Explode()
        {
            _selfDestructed = true;
            Vector3 center = transform.position;

            AudioManager.Instance?.PlaySound("explode");
            CameraFollow.Instance?.Shake(0.3f, 0.4f);

            VisualFX.Burst(center, new Color(1f, 0.7f, 0.2f), 30, 7f, 0.65f);
            VisualFX.Burst(center, new Color(1f, 0.3f, 0.1f), 14, 4f, 0.5f);

            var ringGo = new GameObject("BomberBlast");
            ringGo.transform.position = center;
            var sr = ringGo.AddComponent<SpriteRenderer>();
            sr.sprite = SpriteFactory.CreateCircle(64, new Color(1f, 0.55f, 0.1f, 0.35f), new Color(1f, 0.8f, 0.2f, 0.95f), 4);
            sr.sortingOrder = 15;
            var anim = ringGo.AddComponent<BlastRingAnimation>();
            anim.maxScale = BlastRadius * 2f;
            anim.duration = 0.3f;

            // Sao chép danh sách trúng đòn trước: TakeDamage có thể làm quái khác chết
            Collider2D[] hits = Physics2D.OverlapCircleAll(center, BlastRadius);
            foreach (var hit in hits)
            {
                if (hit == null) continue;

                if (hit.CompareTag("Player"))
                {
                    var player = hit.GetComponent<PlayerController>();
                    if (player != null)
                    {
                        Vector2 pushDir = ((Vector2)player.transform.position - (Vector2)center).normalized;
                        player.TakeDamage(PlayerBlastDamage, pushDir, 10f);
                    }
                    continue;
                }

                var other = hit.GetComponent<EnemyBase>();
                if (other != null && other != this && other.IsAlive)
                {
                    Vector2 pushDir = ((Vector2)other.transform.position - (Vector2)center).normalized;
                    other.TakeDamage(EnemyBlastDamage, pushDir, 8f, false, false);
                }
            }

            // Tự huỷ: tính là một cái chết để phòng được dọn đúng
            currentHealth = 0f;
            Die();
        }
    }

    public class BlastRingAnimation : MonoBehaviour
    {
        public float maxScale = 4f;
        public float duration = 0.3f;

        private SpriteRenderer _sr;
        private Color _startColor;
        private float _elapsed;

        private void Start()
        {
            _sr = GetComponent<SpriteRenderer>();
            _startColor = _sr != null ? _sr.color : Color.white;
            transform.localScale = Vector3.zero;
        }

        private void Update()
        {
            _elapsed += Time.deltaTime;
            float t = _elapsed / duration;
            if (t >= 1f)
            {
                Destroy(gameObject);
                return;
            }

            float s = Mathf.Lerp(0f, maxScale, Mathf.Sqrt(t));
            transform.localScale = new Vector3(s, s, 1f);
            if (_sr != null)
                _sr.color = new Color(_startColor.r, _startColor.g, _startColor.b, 1f - t);
        }
    }
}

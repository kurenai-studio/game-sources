using System.Collections;
using UnityEngine;

namespace SimpleRPG
{
    [RequireComponent(typeof(Rigidbody2D), typeof(CircleCollider2D))]
    public abstract class EnemyBase : MonoBehaviour
    {
        [Header("Enemy Stats")]
        public string enemyName = "Enemy";
        public float maxHealth = 40f;
        public float currentHealth;
        public float moveSpeed = 3f;
        public float contactDamage = 10f;
        public int xpDrop = 15;
        public int coinDropChance = 50; // percentage
        public int potionDropChance = 15; // percentage
        public bool isElite = false;

        public bool IsAlive => currentHealth > 0;

        /// <summary>Cái chết này có được tính vào combo hạ gục không (quái tự nổ thì không).</summary>
        protected virtual bool CountsForCombo => true;
        // Status effects
        private float _poisonTimer = 0f;
        private float _poisonDmgPerSec = 0f;
        private float _poisonTickAccum = 0f;
        private float _chillTimer = 0f;
        public float CurrentSpeedModifier => _chillTimer > 0f ? 0.5f : 1.0f;

        protected Rigidbody2D rb;
        protected SpriteRenderer spriteRenderer;
        protected Transform playerTransform;
        protected bool isAttacking = false;

        // Mini health bar
        private Transform _healthBarRoot;
        private Transform _healthBarFill;

        protected virtual void Awake()
        {
            rb = GetComponent<Rigidbody2D>();
            rb.gravityScale = 0f;
            rb.freezeRotation = true;
#if UNITY_6000_0_OR_NEWER
            rb.linearDamping = 4f;
#else
            rb.drag = 4f;
#endif

            spriteRenderer = GetComponent<SpriteRenderer>();
            if (spriteRenderer == null)
            {
                spriteRenderer = gameObject.AddComponent<SpriteRenderer>();
            }

            currentHealth = maxHealth;
            CreateMiniHealthBar();
        }

        protected virtual void Start()
        {
            if (PlayerController.Instance != null)
            {
                playerTransform = PlayerController.Instance.transform;
            }
            PositionHealthBar();
            VisualFX.AddShadow(transform, spriteRenderer);
        }

        public void MakeElite()
        {
            isElite = true;
            enemyName = "Elite " + enemyName;
            maxHealth *= 1.8f;
            currentHealth = maxHealth;
            contactDamage *= 1.3f;
            xpDrop *= 2;
            coinDropChance = 100;
            potionDropChance = 40;
            transform.localScale *= 1.25f;

            if (spriteRenderer != null)
            {
                spriteRenderer.color = new Color(1f, 0.85f, 0.4f, 1f); // Golden tint for elite
            }
        }

        private void PositionHealthBar()
        {
            if (_healthBarRoot == null || spriteRenderer == null || spriteRenderer.sprite == null)
                return;
            float top = spriteRenderer.sprite.bounds.max.y + 0.16f;
            _healthBarRoot.localPosition = new Vector3(0f, top, 0f);
        }

        private void CreateMiniHealthBar()
        {
            var barGo = new GameObject("HealthBar");
            barGo.transform.SetParent(transform, false);
            barGo.transform.localPosition = new Vector3(0, 0.7f, 0);
            _healthBarRoot = barGo.transform;

            // Background
            var bgGo = new GameObject("BG");
            bgGo.transform.SetParent(barGo.transform, false);
            var bgSr = bgGo.AddComponent<SpriteRenderer>();
            bgSr.sprite = SpriteFactory.CreateRoundedRect(36, 6, 2, new Color(0.1f, 0.1f, 0.1f, 0.8f), Color.clear, 0);
            bgSr.sortingOrder = 20;

            // Fill
            var fillGo = new GameObject("Fill");
            fillGo.transform.SetParent(barGo.transform, false);
            var fillSr = fillGo.AddComponent<SpriteRenderer>();
            fillSr.sprite = SpriteFactory.CreateRoundedRect(34, 4, 1, new Color(0.9f, 0.2f, 0.25f, 1f), Color.clear, 0);
            fillSr.sortingOrder = 21;
            _healthBarFill = fillGo.transform;

            _healthBarRoot.gameObject.SetActive(false); // only show when damaged
        }

        protected virtual void Update()
        {
            if (!IsAlive) return;

            // Register into Native spatial hash grid for high-speed C++ queries
            NativeRoguelikeCore.InsertGrid(GetInstanceID(), transform.position.x, transform.position.y, 0.5f, isElite ? 1 : 0);

            // Process Poison DoT
            if (_poisonTimer > 0f)
            {
                _poisonTimer -= Time.deltaTime;
                _poisonTickAccum += Time.deltaTime;
                if (_poisonTickAccum >= 0.5f)
                {
                    _poisonTickAccum = 0f;
                    float tickDmg = _poisonDmgPerSec * 0.5f;
                    currentHealth = Mathf.Max(0, currentHealth - tickDmg);
                    DamageNumberManager.Instance?.SpawnNumber(transform.position + Vector3.up * 0.3f, Mathf.RoundToInt(tickDmg), new Color(0.4f, 0.9f, 0.2f), "☣");
                    if (currentHealth <= 0)
                    {
                        Die();
                        return;
                    }
                }
            }

            // Process Chill / Freeze
            if (_chillTimer > 0f)
            {
                _chillTimer -= Time.deltaTime;
                if (_chillTimer <= 0f && spriteRenderer != null)
                {
                    spriteRenderer.color = isElite ? new Color(1f, 0.85f, 0.4f) : Color.white;
                }
            }

            if (playerTransform == null && PlayerController.Instance != null)
            {
                playerTransform = PlayerController.Instance.transform;
            }

            if (playerTransform != null && !isAttacking)
            {
                UpdateAI();
            }
        }

        public void ApplyPoison(float dmgPerSec, float duration)
        {
            _poisonTimer = Mathf.Max(_poisonTimer, duration);
            _poisonDmgPerSec = Mathf.Max(_poisonDmgPerSec, dmgPerSec);
        }

        public void ApplyChill(float slowPct, float duration)
        {
            _chillTimer = Mathf.Max(_chillTimer, duration);
            if (spriteRenderer != null)
            {
                spriteRenderer.color = new Color(0.5f, 0.8f, 1f, 1f); // icy tint
            }
        }

        protected abstract void UpdateAI();

        public virtual void TakeDamage(float damage, Vector2 knockbackDir, float knockbackForce = 5f, bool isCritical = false, bool triggerRelics = true)
        {
            if (!IsAlive) return;

            currentHealth = Mathf.Max(0, currentHealth - damage);

            // Floating damage text
            DamageNumberManager.Instance?.SpawnNumber(transform.position + Vector3.up * 0.3f, Mathf.RoundToInt(damage), isCritical ? new Color(1f, 0.85f, 0.1f) : Color.white, isCritical ? "!" : "");
            if (isCritical)
            {
                AudioManager.Instance?.PlaySound("hit");
                CameraFollow.Instance?.Shake(0.1f, 0.12f);
            }

            // Relic trigger on hit
            // Tia lửa khi trúng đòn (chí mạng nhiều và vàng hơn)
            VisualFX.Burst(transform.position + Vector3.up * 0.3f, isCritical ? new Color(1f, 0.85f, 0.2f) : new Color(1f, 1f, 1f), isCritical ? 9 : 4, isCritical ? 4.5f : 3f, isCritical ? 0.4f : 0.28f);

            // triggerRelics = false cho sát thương phụ (đốt, nổ, tia sét chuỗi) để không kích hoạt relic lặp lại
            if (triggerRelics) RelicSystem.Instance?.OnHitEnemy(this, damage, isCritical);

            // Update mini health bar
            if (_healthBarRoot != null)
            {
                _healthBarRoot.gameObject.SetActive(true);
                float pct = currentHealth / maxHealth;
                _healthBarFill.localScale = new Vector3(Mathf.Clamp01(pct), 1f, 1f);
            }

            // Knockback
            if (rb != null && knockbackForce > 0f)
            {
                rb.AddForce(knockbackDir.normalized * knockbackForce, ForceMode2D.Impulse);
            }

            // Hit flash
            StartCoroutine(FlashRoutine());

            if (currentHealth <= 0)
            {
                Die();
            }
        }

        private IEnumerator FlashRoutine()
        {
            Color orig = spriteRenderer.color;
            spriteRenderer.color = Color.white * 2f;
            yield return new WaitForSeconds(0.08f);
            spriteRenderer.color = orig;
        }

        protected virtual void Die()
        {
            AudioManager.Instance?.PlaySound("enemy_death");

            // Drop loot
            DropLoot();

            // Relic kill trigger (explosions, blood chalice)
            RelicSystem.Instance?.OnEnemyKilled(this);

            // Mảnh vỡ khi chết
            VisualFX.Burst(transform.position + Vector3.up * 0.2f, DeathBurstColor(), 16, 4.5f, 0.6f);

            // Combo kill streak
            if (CountsForCombo) ComboSystem.RegisterKill(transform.position);

            // Notify DungeonManager
            DungeonManager.Instance?.OnEnemyDefeated(this);

            // Death poof animation
            StartCoroutine(DeathRoutine());
        }

        protected virtual void DropLoot()
        {
            // Always drop XP gem
            LootManager.Instance?.SpawnXP(transform.position, xpDrop);

            // Chance of coin
            if (Random.Range(0, 100) < coinDropChance)
            {
                LootManager.Instance?.SpawnCoin(transform.position + (Vector3)Random.insideUnitCircle * 0.4f, Random.Range(1, 4));
            }

            // Chance of health potion
            if (Random.Range(0, 100) < potionDropChance)
            {
                LootManager.Instance?.SpawnPotion(transform.position + (Vector3)Random.insideUnitCircle * 0.4f, 35f);
            }
            // Chance of equipment (boss luôn rơi)
            int floor = DungeonManager.Instance != null ? DungeonManager.Instance.currentFloor : 1;
            bool isBoss = this is BossEnemy || this is WardenEnemy;
            EquipmentPickup.TryDrop(transform.position + (Vector3)Random.insideUnitCircle * 0.4f, 0.12f, floor, isBoss);
        }

        private Color DeathBurstColor()
        {
            if (isElite) return new Color(1f, 0.85f, 0.4f);
            if (this is BossEnemy) return new Color(0.95f, 0.3f, 0.3f);
            if (this is WardenEnemy) return new Color(1f, 0.78f, 0.35f);
            if (this is BomberEnemy) return new Color(1f, 0.6f, 0.15f);
            if (this is BruteEnemy) return new Color(0.6f, 0.4f, 0.95f);
            if (this is RangerEnemy) return new Color(0.95f, 0.3f, 0.35f);
            return new Color(0.4f, 0.9f, 0.35f);
        }

        private IEnumerator DeathRoutine()
        {
            GetComponent<Collider2D>().enabled = false;
            float elapsed = 0f;
            float duration = 0.25f;
            Vector3 initScale = transform.localScale;

            while (elapsed < duration)
            {
                elapsed += Time.deltaTime;
                float t = elapsed / duration;
                transform.localScale = Vector3.Lerp(initScale, Vector3.zero, t);
                spriteRenderer.color = new Color(1f, 1f, 1f, 1f - t);
                yield return null;
            }

            Destroy(gameObject);
        }

        private void OnCollisionStay2D(Collision2D collision)
        {
            if (!IsAlive) return;

            if (collision.gameObject.CompareTag("Player"))
            {
                var player = collision.gameObject.GetComponent<PlayerController>();
                if (player != null)
                {
                    Vector2 dir = ((Vector2)player.transform.position - (Vector2)transform.position).normalized;
                    player.TakeDamage(contactDamage, dir, 5f);
                }
            }
        }
    }
}

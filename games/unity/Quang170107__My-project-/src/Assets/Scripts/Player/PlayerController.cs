using System.Collections;
using UnityEngine;

namespace SimpleRPG
{
    [RequireComponent(typeof(Rigidbody2D), typeof(CircleCollider2D), typeof(CombatStats))]
    public class PlayerController : MonoBehaviour
    {
        public static PlayerController Instance { get; private set; }

        [Header("Components")]
        public CombatStats stats;
        public Rigidbody2D rb;
        public SpriteRenderer bodyRenderer;
        public Transform weaponPivot;
        public SpriteRenderer weaponRenderer;

        [Header("State")]
        public bool isDashing = false;
        public bool isAttacking = false;
        public float dashCooldownTimer = 0f;
        public float specialCooldownTimer = 0f;
        public const float SpecialMaxCooldown = 6f;

        private Vector2 _moveInput;
        private Vector2 _aimDirection;
        private float _attackTimer = 0f;
        private Vector3 _initialScale;
        private float _walkBobTimer = 0f;
        private readonly Color _baseBodyColor = Color.white;
        private int _bodyColorFxId;
        private int _invulnLocks;

        // Zero-GC non-allocating query buffer
        private static readonly Collider2D[] _hitsBuffer = new Collider2D[32];

        private void Awake()
        {
            Instance = this;
            stats = GetComponent<CombatStats>();
            rb = GetComponent<Rigidbody2D>();
            _initialScale = transform.localScale;

            // Configure physics
            rb.gravityScale = 0f;
            rb.freezeRotation = true;
            rb.collisionDetectionMode = CollisionDetectionMode2D.Continuous;

            var col = GetComponent<CircleCollider2D>();
            col.radius = 0.42f;

            gameObject.tag = "Player";
        }

        private void Start()
        {
            SetupVisuals();
            stats.OnDeath += HandleDeath;
        }

        private void OnDestroy()
        {
            if (stats != null)
            {
                stats.OnDeath -= HandleDeath;
            }
        }

        private void SetupVisuals()
        {
            if (bodyRenderer == null)
            {
                bodyRenderer = gameObject.AddComponent<SpriteRenderer>();
            }
            bodyRenderer.sprite = SpriteFactory.GetSprite("player");
            bodyRenderer.color = _baseBodyColor;
            bodyRenderer.sortingOrder = 10;

            if (transform.Find("Shadow") == null)
            {
                var shadowGo = new GameObject("Shadow");
                shadowGo.transform.SetParent(transform, false);
                shadowGo.transform.localPosition = new Vector3(0f, -0.08f, 0f);
                shadowGo.transform.localScale = new Vector3(1.15f, 0.38f, 1f);
                var ssr = shadowGo.AddComponent<SpriteRenderer>();
                ssr.sprite = SpriteFactory.CreateCircle(32, new Color(0f, 0f, 0f, 0.4f), Color.clear, 0);
                ssr.sortingOrder = 8;
            }

            if (weaponPivot == null)
            {
                var pivotGo = new GameObject("WeaponPivot");
                pivotGo.transform.SetParent(transform, false);
                pivotGo.transform.localPosition = new Vector3(0f, 0.28f, 0f);
                weaponPivot = pivotGo.transform;

                var swordGo = new GameObject("Sword");
                swordGo.transform.SetParent(weaponPivot, false);
                swordGo.transform.localPosition = new Vector3(0.52f, 0f, 0f);
                swordGo.transform.localRotation = Quaternion.Euler(0, 0, -45f);

                weaponRenderer = swordGo.AddComponent<SpriteRenderer>();
                weaponRenderer.sprite = SpriteFactory.GetSprite("sword");
                weaponRenderer.sortingOrder = 11;
            }
        }

        private void Update()
        {
            if (stats.currentHealth <= 0) return;

            // Timers
            if (dashCooldownTimer > 0f) dashCooldownTimer -= Time.deltaTime;
            if (specialCooldownTimer > 0f) specialCooldownTimer -= Time.deltaTime;
            if (_attackTimer > 0f) _attackTimer -= Time.deltaTime;

            // Input
            _moveInput = InputHelper.GetMoveInput();
            Vector2 mouseWorld = InputHelper.GetAimWorldPosition(Camera.main);
            _aimDirection = (mouseWorld - (Vector2)transform.position).normalized;

            // Face the aim direction so the knight isn't a static blob
            if (bodyRenderer != null && Mathf.Abs(_aimDirection.x) > 0.12f)
            {
                bodyRenderer.flipX = _aimDirection.x < 0f;
            }

            // Weapon aim rotation
            if (weaponPivot != null && !isAttacking)
            {
                float aimAngle = Mathf.Atan2(_aimDirection.y, _aimDirection.x) * Mathf.Rad2Deg;
                weaponPivot.rotation = Quaternion.Euler(0, 0, aimAngle);
            }

            // Attack input
            if ((InputHelper.GetAttackDown() || InputHelper.GetAttackHeld()) && _attackTimer <= 0f && !isDashing)
            {
                PerformMeleeAttack();
            }

            // Dash input
            if (InputHelper.GetDashDown() && dashCooldownTimer <= 0f && !isDashing)
            {
                StartCoroutine(PerformDash());
            }

            // Special Skill (Nova)
            if (InputHelper.GetSpecialDown() && specialCooldownTimer <= 0f)
            {
                PerformSpecialNova();
            }

            // Walk bob animation
            AnimateWalkSquash();
        }

        private void FixedUpdate()
        {
            if (stats.currentHealth <= 0)
            {
#if UNITY_6000_0_OR_NEWER
                rb.linearVelocity = Vector2.zero;
#else
                rb.velocity = Vector2.zero;
#endif
                return;
            }

            if (!isDashing)
            {
                Vector2 targetVelocity = _moveInput * stats.moveSpeed;
#if UNITY_6000_0_OR_NEWER
                rb.linearVelocity = Vector2.Lerp(rb.linearVelocity, targetVelocity, 18f * Time.fixedDeltaTime);
#else
                rb.velocity = Vector2.Lerp(rb.velocity, targetVelocity, 18f * Time.fixedDeltaTime);
#endif
            }
        }

        private void AnimateWalkSquash()
        {
            if (_moveInput.sqrMagnitude > 0.01f)
            {
                _walkBobTimer += Time.deltaTime * stats.moveSpeed * 2.5f;
                float squash = Mathf.Sin(_walkBobTimer) * 0.08f;
                transform.localScale = new Vector3(_initialScale.x * (1f + squash), _initialScale.y * (1f - squash), _initialScale.z);
            }
            else
            {
                _walkBobTimer = 0f;
                transform.localScale = Vector3.Lerp(transform.localScale, _initialScale, 10f * Time.deltaTime);
            }
        }

        private void PerformMeleeAttack()
        {
            _attackTimer = 1f / stats.attackRate;
            StartCoroutine(AttackSwingRoutine());
        }

        private IEnumerator AttackSwingRoutine()
        {
            isAttacking = true;
            AudioManager.Instance?.PlaySound("slash");

            // Slash arc effect
            SpawnSlashEffect();

            // Swing sword through 120-degree arc
            float baseAngle = Mathf.Atan2(_aimDirection.y, _aimDirection.x) * Mathf.Rad2Deg;
            float startAngle = baseAngle + 65f;
            float endAngle = baseAngle - 65f;
            float swingDuration = 0.15f;
            float elapsed = 0f;

            // Non-alloc hit detection in front arc
            int hitCount = Physics2D.OverlapCircleNonAlloc(transform.position + (Vector3)(_aimDirection * 0.8f), stats.attackRange, _hitsBuffer);
            bool hitAny = false;
            float healTotal = 0f;

            for (int i = 0; i < hitCount; i++)
            {
                var hit = _hitsBuffer[i];
                if (hit == null || hit.gameObject == gameObject) continue;
                var enemy = hit.GetComponent<EnemyBase>();
                if (enemy != null && enemy.IsAlive)
                {
                    hitAny = true;
                    Vector2 hitDir = ((Vector2)enemy.transform.position - (Vector2)transform.position).normalized;
                    float swingDamage = stats.RollDamage(stats.baseDamage, out bool swingCrit);
                    enemy.TakeDamage(swingDamage, hitDir, swingCrit ? 9f : 6f, swingCrit);
                    ApplyOnHitEffects(enemy);

                    // Lifesteal (gộp lại, hồi 1 lần mỗi nhát chém)
                    if (stats.lifesteal > 0f)
                    {
                        healTotal += stats.baseDamage * Mathf.Min(stats.lifesteal, CombatStats.MaxLifesteal);
                    }
                }
            }

            if (healTotal > 0f)
            {
                stats.Heal(healTotal);
            }

            if (hitAny)
            {
                AudioManager.Instance?.PlaySound("hit");
                CameraFollow.Instance?.Shake(0.12f, 0.15f);
            }

            while (elapsed < swingDuration)
            {
                elapsed += Time.deltaTime;
                float t = elapsed / swingDuration;
                float currentAngle = Mathf.Lerp(startAngle, endAngle, Mathf.SmoothStep(0f, 1f, t));
                if (weaponPivot != null)
                {
                    weaponPivot.rotation = Quaternion.Euler(0, 0, currentAngle);
                }
                yield return null;
            }

            isAttacking = false;
        }

        private void SpawnSlashEffect()
        {
            var slashGo = new GameObject("SlashEffect");
            slashGo.transform.position = transform.position + (Vector3)(_aimDirection * 0.7f);
            float angle = Mathf.Atan2(_aimDirection.y, _aimDirection.x) * Mathf.Rad2Deg;
            slashGo.transform.rotation = Quaternion.Euler(0, 0, angle);

            var sr = slashGo.AddComponent<SpriteRenderer>();
            sr.sprite = SpriteFactory.GetSprite("slash");
            sr.sortingOrder = 12;

            var anim = slashGo.AddComponent<QuickFadeAnimation>();
            anim.duration = 0.15f;
        }

        private IEnumerator PerformDash()
        {
            isDashing = true;
            dashCooldownTimer = stats.dashCooldown;
            PushInvuln();
            AudioManager.Instance?.PlaySound("dash");

            Vector2 dashDir = _moveInput.sqrMagnitude > 0.01f ? _moveInput.normalized : _aimDirection;
#if UNITY_6000_0_OR_NEWER
            rb.linearVelocity = dashDir * stats.dashSpeed;
#else
            rb.velocity = dashDir * stats.dashSpeed;
#endif

            // Ghost trail effect
            StartCoroutine(SpawnGhostTrail(stats.dashDuration));

            int fx = ++_bodyColorFxId;
            if (bodyRenderer != null)
                bodyRenderer.color = new Color(0.4f, 1f, 1f, 0.6f);

            yield return new WaitForSeconds(stats.dashDuration);

            if (fx == _bodyColorFxId)
                RestoreBodyColor();
            PopInvuln();
            isDashing = false;
        }

        private IEnumerator SpawnGhostTrail(float duration)
        {
            float elapsed = 0f;
            while (elapsed < duration)
            {
                var ghost = new GameObject("Ghost");
                ghost.transform.position = transform.position;
                ghost.transform.rotation = transform.rotation;
                ghost.transform.localScale = transform.localScale;

                var sr = ghost.AddComponent<SpriteRenderer>();
                sr.sprite = bodyRenderer.sprite;
                sr.flipX = bodyRenderer.flipX;
                sr.color = new Color(0.2f, 0.8f, 1f, 0.45f);
                sr.sortingOrder = 9;

                var fade = ghost.AddComponent<QuickFadeAnimation>();
                fade.duration = 0.22f;

                yield return new WaitForSeconds(0.04f);
                elapsed += 0.04f;
            }
        }

        /// <summary>Áp hiệu ứng đốt / làm chậm từ nâng cấp lên quái vừa trúng đòn.</summary>
        private void ApplyOnHitEffects(EnemyBase enemy)
        {
            if (enemy == null || !enemy.IsAlive) return;

            if (stats.igniteLevel > 0)
            {
                float dps = stats.baseDamage * 0.5f * stats.igniteLevel;
                EnemyStatus.Ignite(enemy, dps, 3f);
            }
            if (stats.frostbiteLevel > 0)
            {
                float factor = Mathf.Max(0.4f, 1f - 0.15f * stats.frostbiteLevel);
                EnemyStatus.Slow(enemy, factor, 2f);
            }
        }

        private void PerformSpecialNova()
        {
            specialCooldownTimer = stats.specialCooldown;
            VisualFX.Burst(transform.position, new Color(0.4f, 0.95f, 1f), 34, 8f, 0.6f);
            AudioManager.Instance?.PlaySound("special");
            CameraFollow.Instance?.Shake(0.25f, 0.35f);

            // Radial shockwave visual
            var novaGo = new GameObject("NovaRing");
            novaGo.transform.position = transform.position;
            var sr = novaGo.AddComponent<SpriteRenderer>();
            sr.sprite = SpriteFactory.CreateCircle(64, Color.clear, new Color(0.3f, 0.95f, 1f, 0.9f), 4);
            sr.sortingOrder = 15;

            var expand = novaGo.AddComponent<NovaExpandAnimation>();
            expand.maxRadius = 3.5f;
            expand.duration = 0.35f;

            // Non-alloc query for all enemies in 3.5m radius
            int novaHits = Physics2D.OverlapCircleNonAlloc(transform.position, 3.5f, _hitsBuffer);
            for (int i = 0; i < novaHits; i++)
            {
                var hit = _hitsBuffer[i];
                if (hit == null || hit.gameObject == gameObject) continue;
                var enemy = hit.GetComponent<EnemyBase>();
                if (enemy != null && enemy.IsAlive)
                {
                    Vector2 pushDir = ((Vector2)enemy.transform.position - (Vector2)transform.position).normalized;
                    float novaDamage = stats.RollDamage(stats.baseDamage * 1.8f, out bool novaCrit);
                    enemy.TakeDamage(novaDamage, pushDir, 12f, novaCrit);
                    ApplyOnHitEffects(enemy);
                }
            }
        }

        public void TakeDamage(float damage, Vector2 knockbackDir, float knockbackForce)
        {
            if (stats.isInvulnerable || stats.currentHealth <= 0) return;

            // Divine Aegis barrier check
            if (RelicSystem.Instance != null && RelicSystem.Instance.TryAbsorbHit())
            {
                return;
            }

            stats.TakeDamage(damage, knockbackDir, knockbackForce);
            ComboSystem.Instance?.BreakCombo();
            VisualFX.DamagePulse(Mathf.Clamp01(0.45f + damage / 60f));
            AudioManager.Instance?.PlaySound("hurt");
            CameraFollow.Instance?.Shake(0.18f, 0.25f);
            if (stats.currentHealth <= 0) return;
            StartCoroutine(HurtIFramesRoutine());
            StartCoroutine(DamageFlashRoutine());
        }

        private IEnumerator HurtIFramesRoutine()
        {
            PushInvuln();
            yield return new WaitForSeconds(0.45f);
            PopInvuln();
        }

        private IEnumerator DamageFlashRoutine()
        {
            int fx = ++_bodyColorFxId;
            if (bodyRenderer != null)
                bodyRenderer.color = new Color(1f, 0.2f, 0.2f, 1f);
            yield return new WaitForSeconds(0.12f);
            if (fx == _bodyColorFxId)
                RestoreBodyColor();
        }

        private void RestoreBodyColor()
        {
            if (bodyRenderer != null)
                bodyRenderer.color = _baseBodyColor;
        }

        private void PushInvuln()
        {
            _invulnLocks++;
            stats.isInvulnerable = true;
        }

        private void PopInvuln()
        {
            _invulnLocks = Mathf.Max(0, _invulnLocks - 1);
            stats.isInvulnerable = _invulnLocks > 0;
        }

        private void HandleDeath()
        {
            AudioManager.Instance?.PlaySound("enemy_death");
            CameraFollow.Instance?.Shake(0.4f, 0.45f);
            _bodyColorFxId++;
            if (bodyRenderer != null)
                bodyRenderer.color = new Color(0.4f, 0.4f, 0.4f, 0.5f);
            DungeonManager.Instance?.OnPlayerDied();
        }

        public void ResetPlayer(Vector3 spawnPos)
        {
            transform.position = spawnPos;
            transform.localScale = _initialScale;
            StopAllCoroutines();
            isDashing = false;
            isAttacking = false;
            dashCooldownTimer = 0f;
            specialCooldownTimer = 0f;
            _attackTimer = 0f;
            _walkBobTimer = 0f;
            _bodyColorFxId++;
            _invulnLocks = 0;
            if (stats != null)
                stats.isInvulnerable = false;

            if (bodyRenderer != null)
            {
                bodyRenderer.color = _baseBodyColor;
            }

            if (rb != null)
            {
#if UNITY_6000_0_OR_NEWER
                rb.linearVelocity = Vector2.zero;
#else
                rb.velocity = Vector2.zero;
#endif
            }

            if (stats != null)
            {
                stats.ResetStats();
            }

            RelicSystem.Instance?.ClearRelics();
        }
    }

    public class QuickFadeAnimation : MonoBehaviour
    {
        public float duration = 0.2f;
        private SpriteRenderer _sr;
        private float _elapsed = 0f;
        private Color _initColor;

        private void Start()
        {
            _sr = GetComponent<SpriteRenderer>();
            _initColor = _sr != null ? _sr.color : Color.white;
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

            if (_sr != null)
            {
                _sr.color = new Color(_initColor.r, _initColor.g, _initColor.b, Mathf.Lerp(_initColor.a, 0f, t));
            }
        }
    }

    public class NovaExpandAnimation : MonoBehaviour
    {
        public float maxRadius = 3.5f;
        public float duration = 0.35f;
        private float _elapsed = 0f;
        private SpriteRenderer _sr;

        private void Start()
        {
            _sr = GetComponent<SpriteRenderer>();
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

            float currentRadius = Mathf.Lerp(0f, maxRadius * 2f, Mathf.Sqrt(t));
            transform.localScale = new Vector3(currentRadius, currentRadius, 1f);

            if (_sr != null)
            {
                _sr.color = new Color(0.3f, 0.95f, 1f, 1f - t);
            }
        }
    }
}

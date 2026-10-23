using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace SimpleRPG
{
    public class RelicSystem : MonoBehaviour
    {
        public static RelicSystem Instance { get; private set; }

        private readonly List<RelicItem> _activeRelics = new List<RelicItem>();
        public IReadOnlyList<RelicItem> ActiveRelics => _activeRelics;

        public event Action<RelicItem> OnRelicAcquired;

        // Divine Aegis barrier state
        public bool HasShieldActive { get; private set; } = false;
        private float _shieldCooldownTimer = 0f;
        private const float ShieldCooldownMax = 12f;

        private GameObject _shieldVisual;

        private void Awake()
        {
            if (Instance == null)
            {
                Instance = this;
            }
            else
            {
                Destroy(gameObject);
                return;
            }
        }

        private void Update()
        {
            if (HasRelic(RelicType.DivineAegis))
            {
                if (!HasShieldActive)
                {
                    _shieldCooldownTimer -= Time.deltaTime;
                    if (_shieldCooldownTimer <= 0f)
                    {
                        ActivateShield();
                    }
                }
            }
        }

        public bool HasRelic(RelicType type)
        {
            for (int i = 0; i < _activeRelics.Count; i++)
            {
                if (_activeRelics[i].type == type) return true;
            }
            return false;
        }

        public void AddRelic(RelicType type)
        {
            if (HasRelic(type)) return;

            var relic = new RelicItem(type);
            _activeRelics.Add(relic);

            if (type == RelicType.DivineAegis)
            {
                ActivateShield();
            }

            AudioManager.Instance?.PlaySound("potion");
            GameUI.Instance?.ShowBanner($"RELIC UNLOCKED: {relic.relicName.ToUpper()}!", 3f);
            OnRelicAcquired?.Invoke(relic);
        }

        public void ClearRelics()
        {
            _activeRelics.Clear();
            HasShieldActive = false;
            if (_shieldVisual != null) Destroy(_shieldVisual);
        }

        private void ActivateShield()
        {
            HasShieldActive = true;
            if (_shieldVisual == null && PlayerController.Instance != null)
            {
                _shieldVisual = new GameObject("AegisShieldBarrier");
                _shieldVisual.transform.SetParent(PlayerController.Instance.transform, false);
                _shieldVisual.transform.localPosition = Vector3.zero;

                var sr = _shieldVisual.AddComponent<SpriteRenderer>();
                sr.sprite = SpriteFactory.CreateCircle(48, Color.clear, new Color(1f, 0.9f, 0.3f, 0.85f), 3);
                sr.sortingOrder = 14;
            }
            else if (_shieldVisual != null)
            {
                _shieldVisual.SetActive(true);
            }
        }

        /// <summary>
        /// Checks if shield absorbs an incoming attack. Returns true if hit was fully absorbed.
        /// </summary>
        public bool TryAbsorbHit()
        {
            if (HasRelic(RelicType.DivineAegis) && HasShieldActive)
            {
                HasShieldActive = false;
                _shieldCooldownTimer = ShieldCooldownMax;
                if (_shieldVisual != null) _shieldVisual.SetActive(false);

                AudioManager.Instance?.PlaySound("special");
                DamageNumberManager.Instance?.SpawnNumber(PlayerController.Instance.transform.position + Vector3.up * 0.5f, 0, Color.yellow, "BLOCKED! ");
                CameraFollow.Instance?.Shake(0.12f, 0.15f);
                return true;
            }
            return false;
        }

        /// <summary>
        /// Triggered on successful hit against an enemy.
        /// </summary>
        public void OnHitEnemy(EnemyBase target, float damageDealt, bool isCritical)
        {
            if (target == null || !target.IsAlive) return;

            // 1. Frost Core: chill enemy on critical strike
            if (HasRelic(RelicType.FrostCore) && isCritical)
            {
                target.ApplyChill(0.5f, 2.5f);
            }

            // 2. Toxic Fang: apply poison DOT
            if (HasRelic(RelicType.ToxicFang))
            {
                target.ApplyPoison(damageDealt * 0.2f, 3f);
            }

            // 3. Thunder Conduit: chain lightning to up to 3 nearby foes
            if (HasRelic(RelicType.ThunderConduit))
            {
                TriggerChainLightning(target.transform.position, damageDealt * 0.5f, target);
            }
        }

        private void TriggerChainLightning(Vector2 origin, float chainDmg, EnemyBase initialTarget)
        {
            // Use NativeRoguelikeCore spatial grid to query nearest enemies
            int[] hitIds = new int[8];
            float[] distSq = new float[8];
            int count = NativeRoguelikeCore.QueryRadius(origin.x, origin.y, 4.5f, hitIds, distSq, 8);

            int zaps = 0;
            Collider2D[] colliders = Physics2D.OverlapCircleAll(origin, 4.5f);
            foreach (var col in colliders)
            {
                var enemy = col.GetComponent<EnemyBase>();
                if (enemy != null && enemy != initialTarget && enemy.IsAlive)
                {
                    enemy.TakeDamage(chainDmg, (enemy.transform.position - (Vector3)origin).normalized, 3f, false, false);
                    SpawnLightningBoltVisual(origin, enemy.transform.position);
                    zaps++;
                    if (zaps >= 3) break;
                }
            }

            if (zaps > 0)
            {
                AudioManager.Instance?.PlaySound("shoot");
            }
        }

        private void SpawnLightningBoltVisual(Vector3 from, Vector3 to)
        {
            var lineGo = new GameObject("ChainLightningBeam");
            var lr = lineGo.AddComponent<LineRenderer>();
            lr.positionCount = 3;
            Vector3 mid = (from + to) * 0.5f + (Vector3)(UnityEngine.Random.insideUnitCircle * 0.35f);
            lr.SetPositions(new Vector3[] { from, mid, to });
            lr.startWidth = 0.12f;
            lr.endWidth = 0.04f;
            lr.material = new Material(Shader.Find("Sprites/Default"));
            lr.startColor = new Color(0.4f, 0.9f, 1f, 0.9f);
            lr.endColor = new Color(0.2f, 0.6f, 1f, 0.1f);
            lr.sortingOrder = 18;

            Destroy(lineGo, 0.12f);
        }

        /// <summary>
        /// Triggered when any enemy dies.
        /// </summary>
        public void OnEnemyKilled(EnemyBase victim)
        {
            if (victim == null) return;
            Vector3 deathPos = victim.transform.position;

            // 1. Combustion Sigil: explode on death
            if (HasRelic(RelicType.CombustionSigil))
            {
                SpawnExplosion(deathPos, 28f, 2.5f);
            }

            // 2. Blood Chalice: drop blood healing orb
            if (HasRelic(RelicType.BloodChalice) && UnityEngine.Random.value < 0.25f)
            {
                LootManager.Instance?.SpawnPotion(deathPos, 15f);
            }
        }

        private void SpawnExplosion(Vector3 pos, float damage, float radius)
        {
            var expGo = new GameObject("ExplosionRing");
            expGo.transform.position = pos;
            var sr = expGo.AddComponent<SpriteRenderer>();
            sr.sprite = SpriteFactory.CreateCircle(48, new Color(1f, 0.5f, 0.1f, 0.6f), new Color(1f, 0.8f, 0.2f, 1f), 3);
            sr.sortingOrder = 16;
            var anim = expGo.AddComponent<NovaExpandAnimation>();
            anim.maxRadius = radius;
            anim.duration = 0.22f;

            AudioManager.Instance?.PlaySound("special");

            Collider2D[] hits = Physics2D.OverlapCircleAll(pos, radius);
            foreach (var hit in hits)
            {
                var enemy = hit.GetComponent<EnemyBase>();
                if (enemy != null && enemy.IsAlive)
                {
                    Vector2 dir = (enemy.transform.position - pos).normalized;
                    enemy.TakeDamage(damage, dir, 8f, false);
                }
            }
        }
    }
}

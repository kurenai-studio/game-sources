using System;
using UnityEngine;

namespace SimpleRPG
{
    public enum UpgradeType
    {
        MaxHealth,
        Damage,
        MoveSpeed,
        AttackSpeed,
        DashCooldown,
        Lifesteal,
        Armor,
        CritChance,
        NovaCooldown,
        Ignite,
        Frostbite
    }

    public class CombatStats : MonoBehaviour
    {
        public const float MaxLifesteal = 0.3f; // trần hút máu 30%
        public const float MaxCritChance = 0.6f; // trần chí mạng 60%
        public const float MinSpecialCooldown = 2.5f;

        [Header("Health & Defense")]
        public float maxHealth = 100f;
        public float currentHealth;
        public float armor = 0f; // giảm sát thương theo % (diminishing returns), xem TakeDamage
        public bool isInvulnerable = false;

        [Header("Offense")]
        public float baseDamage = 25f;
        public float attackRate = 2.5f; // attacks per second
        public float attackRange = 1.4f;
        public float lifesteal = 0f; // percentage e.g. 0.1f = 10%
        public float critChance = 0.05f; // xác suất chí mạng (0..MaxCritChance)
        public float critMultiplier = 2f; // hệ số sát thương khi chí mạng
        public float specialCooldown = 6f; // hồi chiêu kỹ năng Nova (giây)
        public int igniteLevel = 0; // cấp độ đốt: mỗi cấp = 50% sát thương cơ bản/giây trong 3s
        public int frostbiteLevel = 0; // cấp độ làm chậm: mỗi cấp giảm 15% tốc độ quái (tối thiểu còn 40%)

        [Header("Mobility")]
        public float moveSpeed = 5.5f;
        public float dashCooldown = 1.2f;
        public float dashSpeed = 14f;
        public float dashDuration = 0.2f;

        [Header("RPG Progression")]
        public int level = 1;
        public int currentXP = 0;
        public int xpToNextLevel = 50;
        public int gold = 0;

        public event Action<float, float> OnHealthChanged;
        public event Action<int, int> OnXPChanged;
        public event Action<int> OnLevelUp;
        public event Action<int> OnGoldChanged;
        public event Action OnDeath;

        private void Awake()
        {
            currentHealth = maxHealth;
        }

        public void ResetStats()
        {
            maxHealth = 100f;
            currentHealth = maxHealth;
            armor = 0f;
            isInvulnerable = false;
            baseDamage = 25f;
            attackRate = 2.5f;
            moveSpeed = 5.5f;
            dashCooldown = 1.2f;
            lifesteal = 0f;
            critChance = 0.05f;
            critMultiplier = 2f;
            specialCooldown = 6f;
            igniteLevel = 0;
            frostbiteLevel = 0;
            level = 1;
            currentXP = 0;
            xpToNextLevel = 50;
            gold = 0;

            OnHealthChanged?.Invoke(currentHealth, maxHealth);
            OnXPChanged?.Invoke(currentXP, xpToNextLevel);
            OnGoldChanged?.Invoke(gold);
        }

        public void TakeDamage(float incomingDamage, Vector2 knockbackDir = default, float knockbackForce = 0f, bool isCritical = false)
        {
            if (isInvulnerable || currentHealth <= 0) return;

            // Armor 10 => giảm 50%, armor 20 => giảm ~67%. Không bao giờ miễn nhiễm hoàn toàn.
            float effectiveDamage = Mathf.Max(1f, incomingDamage * 100f / (100f + armor * 10f));
            currentHealth = Mathf.Max(0, currentHealth - effectiveDamage);

            // Pop floating damage text
            DamageNumberManager.Instance?.SpawnNumber(transform.position + Vector3.up * 0.4f, Mathf.RoundToInt(effectiveDamage), isCritical ? Color.yellow : (gameObject.CompareTag("Player") ? new Color(1f, 0.3f, 0.3f) : Color.white));

            OnHealthChanged?.Invoke(currentHealth, maxHealth);

            // Knockback
            var rb = GetComponent<Rigidbody2D>();
            if (rb != null && knockbackForce > 0f)
            {
                rb.AddForce(knockbackDir.normalized * knockbackForce, ForceMode2D.Impulse);
            }

            if (currentHealth <= 0)
            {
                OnDeath?.Invoke();
            }
        }

        /// <summary>Tung xúc xắc chí mạng. Trả về sát thương cuối cùng và cho biết có chí mạng không.</summary>
        public float RollDamage(float baseValue, out bool isCrit)
        {
            isCrit = UnityEngine.Random.value < Mathf.Min(critChance, MaxCritChance);
            return isCrit ? baseValue * critMultiplier : baseValue;
        }

        public void Heal(float amount)
        {
            if (currentHealth <= 0) return;
            currentHealth = Mathf.Min(maxHealth, currentHealth + amount);
            DamageNumberManager.Instance?.SpawnNumber(transform.position + Vector3.up * 0.4f, Mathf.RoundToInt(amount), new Color(0.2f, 1f, 0.4f), "+");
            OnHealthChanged?.Invoke(currentHealth, maxHealth);
            AudioManager.Instance?.PlaySound("potion");
        }
        public void RefreshHealthUI()
        {
            OnHealthChanged?.Invoke(currentHealth, maxHealth);
        }

        public void AddXP(int amount)
        {
            currentXP += amount;
            while (currentXP >= xpToNextLevel)
            {
                currentXP -= xpToNextLevel;
                level++;
                xpToNextLevel = Mathf.RoundToInt(xpToNextLevel * 1.45f);
                OnLevelUp?.Invoke(level);
                AudioManager.Instance?.PlaySound("levelup");
            }
            OnXPChanged?.Invoke(currentXP, xpToNextLevel);
        }

        public void AddGold(int amount)
        {
            gold += amount;
            OnGoldChanged?.Invoke(gold);
            AudioManager.Instance?.PlaySound("coin");
        }

        public void ApplyUpgrade(UpgradeType type)
        {
            switch (type)
            {
                case UpgradeType.MaxHealth:
                    maxHealth += 25f;
                    currentHealth += 25f;
                    break;
                case UpgradeType.Damage:
                    baseDamage += 8f;
                    break;
                case UpgradeType.MoveSpeed:
                    moveSpeed += 0.7f;
                    break;
                case UpgradeType.AttackSpeed:
                    attackRate += 0.8f;
                    break;
                case UpgradeType.DashCooldown:
                    dashCooldown = Mathf.Max(0.4f, dashCooldown - 0.2f);
                    break;
                case UpgradeType.Lifesteal:
                    lifesteal = Mathf.Min(MaxLifesteal, lifesteal + 0.08f);
                    break;
                case UpgradeType.Armor:
                    armor += 2f;
                    break;
                case UpgradeType.CritChance:
                    critChance = Mathf.Min(MaxCritChance, critChance + 0.08f);
                    break;
                case UpgradeType.NovaCooldown:
                    specialCooldown = Mathf.Max(MinSpecialCooldown, specialCooldown - 0.8f);
                    break;
                case UpgradeType.Ignite:
                    igniteLevel++;
                    break;
                case UpgradeType.Frostbite:
                    frostbiteLevel++;
                    break;
            }
            OnHealthChanged?.Invoke(currentHealth, maxHealth);
        }
    }
}

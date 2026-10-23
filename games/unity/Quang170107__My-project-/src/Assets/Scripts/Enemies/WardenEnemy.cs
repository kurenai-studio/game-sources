using UnityEngine;

namespace SimpleRPG
{
    /// <summary>
    /// Mini-boss xuất hiện ở tầng 3 và 8 (giữa các tầng boss). Dùng lại đòn đập đất của
    /// Armored Slime nhưng to hơn, trâu hơn, tô màu vàng đồng và luôn rơi trang bị.
    /// </summary>
    public class WardenEnemy : BruteEnemy
    {
        protected override void Awake()
        {
            base.Awake();
            enemyName = "Warden Brute";
            maxHealth = 180f;
            currentHealth = maxHealth;
            moveSpeed = 2.3f;
            contactDamage = 20f;
            xpDrop = 90;
            coinDropChance = 100;
            potionDropChance = 60;

            spriteRenderer.color = new Color(1f, 0.78f, 0.4f, 1f);
            var col = GetComponent<CircleCollider2D>();
            col.radius = 0.7f;
            transform.localScale = Vector3.one * 1.5f;
        }
    }
}

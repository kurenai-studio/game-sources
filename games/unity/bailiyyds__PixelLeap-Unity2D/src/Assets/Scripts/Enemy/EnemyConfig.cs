using UnityEngine;

namespace PixelLeap.Enemy
{
    public enum EnemyKind { Walker, Jumper, Shooter }

    /// <summary>敌人数值配置：三类敌人共用一套状态机，差异只体现在数据和攻击方式上。</summary>
    [CreateAssetMenu(menuName = "PixelLeap/Enemy Config", fileName = "EnemyConfig")]
    public class EnemyConfig : ScriptableObject
    {
        public EnemyKind kind = EnemyKind.Walker;
        public Color color = new Color(0.9f, 0.35f, 0.3f);
        public int maxHp = 3;
        public int contactDamage = 1;

        [Header("巡逻 / 追击")]
        public float patrolSpeed = 2f;
        public float patrolDistance = 3f;
        public float chaseSpeed = 3.6f;
        public float detectRange = 6f;
        public float loseRange = 9f;

        [Header("攻击")]
        public float attackRange = 2.5f;
        public float attackCooldown = 1.6f;
        public float windUp = 0.35f;           // 攻击前摇：给玩家反应时间
        public float lungeSpeed = 9f;          // Walker 冲刺速度
        public Vector2 jumpVelocity = new Vector2(5f, 9f);  // Jumper 扑跳
        public float projectileSpeed = 9f;     // Shooter 弹速

        [Header("受击")]
        public float hurtStun = 0.25f;
        public float knockback = 5f;

        public static EnemyConfig CreateDefault(EnemyKind kind)
        {
            var c = CreateInstance<EnemyConfig>();
            c.kind = kind;
            switch (kind)
            {
                case EnemyKind.Jumper:
                    c.color = new Color(0.95f, 0.65f, 0.2f); c.maxHp = 2; c.attackRange = 4f; c.attackCooldown = 1.8f;
                    break;
                case EnemyKind.Shooter:
                    c.color = new Color(0.65f, 0.4f, 0.95f); c.maxHp = 2; c.attackRange = 7f; c.detectRange = 8f;
                    c.loseRange = 11f; c.chaseSpeed = 0f; c.patrolSpeed = 0f; c.attackCooldown = 1.4f;
                    break;
            }
            return c;
        }
    }
}

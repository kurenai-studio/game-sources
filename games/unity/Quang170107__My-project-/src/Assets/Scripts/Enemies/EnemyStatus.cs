using UnityEngine;

namespace SimpleRPG
{
    /// <summary>
    /// Hiệu ứng trạng thái trên quái: đốt (burn) và làm chậm (slow).
    /// Tự gắn vào quái khi bị dính hiệu ứng đầu tiên, không cần sửa các lớp quái.
    /// Slow nhân moveSpeed theo hệ số rồi chia lại khi hết, nên cộng hưởng đúng
    /// với các chỗ khác cũng nhân moveSpeed (ví dụ boss nổi giận).
    /// </summary>
    public class EnemyStatus : MonoBehaviour
    {
        private const float TickInterval = 0.5f;

        private EnemyBase _enemy;

        private float _burnTime;
        private float _burnDps;
        private float _tickTimer;

        private float _slowTime;
        private float _slowFactor = 1f;
        private bool _slowed;

        public static void Ignite(EnemyBase enemy, float dps, float duration)
        {
            if (enemy == null || !enemy.IsAlive) return;
            var s = Get(enemy);
            s._burnDps = Mathf.Max(s._burnTime > 0f ? s._burnDps : 0f, dps); // giữ mức cao hơn
            s._burnTime = duration;
            if (s._tickTimer <= 0f) s._tickTimer = TickInterval;
        }

        public static void Slow(EnemyBase enemy, float factor, float duration)
        {
            if (enemy == null || !enemy.IsAlive) return;
            factor = Mathf.Clamp(factor, 0.2f, 1f);
            var s = Get(enemy);

            // Đổi sang hệ số mới: gỡ hệ số cũ rồi áp hệ số mới
            if (s._slowed) enemy.moveSpeed /= s._slowFactor;
            s._slowFactor = factor;
            enemy.moveSpeed *= factor;
            s._slowed = true;
            s._slowTime = duration;
        }

        private static EnemyStatus Get(EnemyBase enemy)
        {
            var s = enemy.GetComponent<EnemyStatus>();
            if (s == null) s = enemy.gameObject.AddComponent<EnemyStatus>();
            s._enemy = enemy;
            return s;
        }

        private void Awake()
        {
            _enemy = GetComponent<EnemyBase>();
        }

        private void Update()
        {
            if (_enemy == null || !_enemy.IsAlive)
            {
                enabled = false;
                return;
            }

            if (_burnTime > 0f)
            {
                _burnTime -= Time.deltaTime;
                _tickTimer -= Time.deltaTime;
                if (_tickTimer <= 0f)
                {
                    _tickTimer += TickInterval;
                    _enemy.TakeDamage(Mathf.Max(1f, _burnDps * TickInterval), Vector2.zero, 0f, false, false);
                    if (!_enemy.IsAlive) return;
                }
            }

            if (_slowed)
            {
                _slowTime -= Time.deltaTime;
                if (_slowTime <= 0f)
                {
                    _enemy.moveSpeed /= _slowFactor;
                    _slowFactor = 1f;
                    _slowed = false;
                }
            }
        }
    }
}

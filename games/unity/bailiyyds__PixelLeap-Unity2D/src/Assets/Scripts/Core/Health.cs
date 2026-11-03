using System;
using System.Collections;
using UnityEngine;

namespace PixelLeap.Core
{
    public enum Team { Player, Enemy, Neutral }

    public interface IDamageable
    {
        Team Team { get; }
        bool TakeDamage(int amount, Vector2 hitDirection);
    }

    /// <summary>生命值组件：受击无敌帧、受击闪白、死亡事件。玩家和敌人共用。</summary>
    public class Health : MonoBehaviour, IDamageable
    {
        [SerializeField] Team team = Team.Enemy;
        [SerializeField] int maxHp = 3;
        [SerializeField] float invincibleTime = 0.6f;

        public event Action<int, Vector2> Damaged;   // (剩余血量, 受击方向)
        public event Action Died;

        public Team Team => team;
        public int MaxHp => maxHp;
        public int Hp { get; private set; }
        public bool IsDead => Hp <= 0;
        public bool IsInvincible => Time.time < invincibleUntil;

        float invincibleUntil;
        SpriteRenderer sr;
        Color baseColor;

        public void Setup(Team t, int hp, float iFrames)
        {
            team = t; maxHp = hp; invincibleTime = iFrames;
            if (sr) baseColor = sr.color;
            ResetHealth();
        }

        void Awake()
        {
            sr = GetComponentInChildren<SpriteRenderer>();
            if (sr) baseColor = sr.color;
            ResetHealth();
        }

        public void ResetHealth()
        {
            Hp = maxHp;
            invincibleUntil = 0;
            if (sr) sr.color = baseColor;
        }

        public bool TakeDamage(int amount, Vector2 hitDirection)
        {
            if (IsDead || IsInvincible || amount <= 0) return false;
            Hp = Mathf.Max(0, Hp - amount);
            invincibleUntil = Time.time + invincibleTime;
            Damaged?.Invoke(Hp, hitDirection);
            if (sr && isActiveAndEnabled) StartCoroutine(Flash());
            if (Hp == 0) Died?.Invoke();
            return true;
        }

        IEnumerator Flash()
        {
            // 闪白 + 无敌期间闪烁：给玩家清晰的受击反馈
            sr.color = Color.white;
            yield return new WaitForSeconds(0.06f);
            while (IsInvincible && !IsDead)
            {
                sr.color = new Color(baseColor.r, baseColor.g, baseColor.b, 0.35f);
                yield return new WaitForSeconds(0.08f);
                sr.color = baseColor;
                yield return new WaitForSeconds(0.08f);
            }
            sr.color = baseColor;
        }
    }
}

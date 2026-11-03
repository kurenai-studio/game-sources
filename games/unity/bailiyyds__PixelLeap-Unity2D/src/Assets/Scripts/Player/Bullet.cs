using System;
using PixelLeap.Core;
using UnityEngine;

namespace PixelLeap.Player
{
    /// <summary>子弹：由对象池管理，按阵营判断伤害对象，撞墙或超时自动回池。</summary>
    [RequireComponent(typeof(Rigidbody2D), typeof(CircleCollider2D))]
    public class Bullet : MonoBehaviour, IPoolable
    {
        Rigidbody2D rb;
        Team team;
        int damage;
        float lifeLeft;
        Action<Bullet> release;
        bool released;

        void Awake()
        {
            rb = GetComponent<Rigidbody2D>();
            rb.bodyType = RigidbodyType2D.Kinematic;
            rb.collisionDetectionMode = CollisionDetectionMode2D.Continuous;
            GetComponent<CircleCollider2D>().isTrigger = true;
        }

        public void Launch(Vector2 velocity, int dmg, Team owner, float lifetime, Action<Bullet> onRelease)
        {
            rb.velocity = velocity;
            damage = dmg;
            team = owner;
            lifeLeft = lifetime;
            release = onRelease;
        }

        public void OnSpawn() => released = false;
        public void OnDespawn() { if (rb) rb.velocity = Vector2.zero; }   // 预热回池时 Awake 尚未执行

        void Update()
        {
            lifeLeft -= Time.deltaTime;
            if (lifeLeft <= 0) Despawn();
        }

        void OnTriggerEnter2D(Collider2D other)
        {
            if (released || other.isTrigger) return;
            var target = other.GetComponentInParent<IDamageable>();
            if (target != null)
            {
                if (target.Team == team) return;               // 不打自己人
                target.TakeDamage(damage, rb.velocity.normalized);
            }
            Despawn();                                         // 命中目标或撞到墙
        }

        void Despawn()
        {
            if (released) return;
            released = true;
            if (release != null) release(this);
            else gameObject.SetActive(false);
        }
    }
}

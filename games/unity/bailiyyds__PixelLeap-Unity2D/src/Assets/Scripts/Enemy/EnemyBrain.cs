using PixelLeap.Core;
using PixelLeap.Player;
using UnityEngine;

namespace PixelLeap.Enemy
{
    /// <summary>
    /// 敌人主体：持有状态机与各个状态实例，并提供移动、感知（视线 / 墙 / 悬崖）等基础能力。
    /// 状态只描述"做什么"，Brain 负责"怎么做"，新增敌人类型时只需新增数据或状态。
    /// </summary>
    [RequireComponent(typeof(Rigidbody2D), typeof(BoxCollider2D), typeof(Health))]
    public class EnemyBrain : MonoBehaviour
    {
        public EnemyConfig Config;
        public Bullet projectileTemplate;
        public LayerMask groundMask = ~(1 << 2);   // 玩家、敌人、子弹都在 Ignore Raycast 层，射线只检测地形

        public StateMachine Fsm { get; } = new StateMachine();
        public PatrolState Patrol { get; private set; }
        public ChaseState Chase { get; private set; }
        public AttackState Attack { get; private set; }
        public HurtState Hurt { get; private set; }
        public DeadState Dead { get; private set; }

        public Rigidbody2D Body { get; private set; }
        public float HomeX { get; private set; }
        public int Dir { get; set; } = -1;
        public bool Grounded { get; private set; }
        public bool AttackReady => Time.time >= cooldownUntil;
        public float DistanceToPlayer => player ? Vector2.Distance(player.position, transform.position) : float.MaxValue;

        Transform player;
        BoxCollider2D box;
        Health health;
        SpriteRenderer sr;
        float cooldownUntil;
        static ObjectPool<Bullet> sharedProjectilePool;   // 所有射手共用一个池

        public void Init(EnemyConfig config, Transform playerTarget, Bullet projectile)
        {
            Config = config;
            player = playerTarget;
            projectileTemplate = projectile;
            if (sr) sr.color = config.color;          // 先上色，Health 会以此作为闪白后的还原色
            health.Setup(Team.Enemy, config.maxHp, 0.12f);
            HomeX = transform.position.x;
            if (projectileTemplate && sharedProjectilePool == null)
                sharedProjectilePool = new ObjectPool<Bullet>(projectileTemplate, 12, 48);
            Fsm.Change(Patrol);
        }

        public static void ResetSharedPool() => sharedProjectilePool = null;

        void Awake()
        {
            Body = GetComponent<Rigidbody2D>();
            Body.freezeRotation = true;
            Body.gravityScale = 3f;
            box = GetComponent<BoxCollider2D>();
            health = GetComponent<Health>();
            sr = GetComponentInChildren<SpriteRenderer>();
            Patrol = new PatrolState(this);
            Chase = new ChaseState(this);
            Attack = new AttackState(this);
            Hurt = new HurtState(this);
            Dead = new DeadState(this);
            health.Damaged += OnDamaged;
            health.Died += () => Fsm.Change(Dead);
            HomeX = transform.position.x;
        }

        void FixedUpdate()
        {
            Grounded = Physics2D.Raycast(transform.position, Vector2.down, box.bounds.extents.y + 0.08f, groundMask);
            Fsm.Tick(Time.fixedDeltaTime);
        }

        void OnDamaged(int hpLeft, Vector2 dir)
        {
            if (hpLeft <= 0) return;
            Hurt.HitDirection = dir;
            Fsm.Change(Hurt);
        }

        // ---------------- 能力 ----------------
        public void Move(float vx) => Body.velocity = new Vector2(vx, Body.velocity.y);

        public void FacePlayer()
        {
            if (!player) return;
            float dx = player.position.x - transform.position.x;
            if (Mathf.Abs(dx) > 0.1f) Dir = dx > 0 ? 1 : -1;
        }

        public bool CanSeePlayer()
        {
            if (!player) return false;
            Vector2 from = transform.position, to = player.position;
            var hit = Physics2D.Linecast(from, to, groundMask);
            return !hit.collider || hit.collider.transform == player;
        }

        public bool WallAhead()
        {
            Vector2 origin = (Vector2)transform.position + Vector2.right * Dir * (box.bounds.extents.x + 0.02f);
            var hit = Physics2D.Raycast(origin, Vector2.right * Dir, 0.1f, groundMask);
            return hit.collider && !hit.collider.isTrigger && hit.collider.transform != player;
        }

        public bool LedgeAhead()
        {
            if (!Grounded) return false;
            Vector2 origin = (Vector2)transform.position + Vector2.right * Dir * (box.bounds.extents.x + 0.15f);
            return !Physics2D.Raycast(origin, Vector2.down, box.bounds.extents.y + 0.6f, groundMask);
        }

        public void StartCooldown() => cooldownUntil = Time.time + Config.attackCooldown;

        public void SetTelegraph(bool on)
        {
            if (sr) sr.color = on ? Color.Lerp(Config.color, Color.white, 0.6f) : Config.color;
        }

        public void FireProjectile()
        {
            if (sharedProjectilePool == null || !player) return;
            Vector2 dir = ((Vector2)player.position - (Vector2)transform.position).normalized;
            var b = sharedProjectilePool.Get(transform.position + (Vector3)(dir * 0.6f), Quaternion.identity);
            b.Launch(dir * Config.projectileSpeed, 1, Team.Enemy, 2f, sharedProjectilePool.Release);
        }

        // 接触伤害
        void OnCollisionStay2D(Collision2D col)
        {
            if (Fsm.Current == Dead) return;
            var target = col.collider.GetComponentInParent<IDamageable>();
            if (target != null && target.Team == Team.Player)
                target.TakeDamage(Config.contactDamage, (col.transform.position - transform.position).normalized);
        }

        public string DebugState => Fsm.Current?.Name ?? "-";
    }
}

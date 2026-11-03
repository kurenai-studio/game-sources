using PixelLeap.Core;
using UnityEngine;

namespace PixelLeap.Player
{
    /// <summary>
    /// 平台跳跃角色控制器。
    /// 不使用刚体重力，而是在 FixedUpdate 里自己积分速度，便于精确控制手感：
    ///  · 加速度 / 减速度分离，空中控制力单独配置
    ///  · 土狼时间 + 跳跃缓冲，降低"明明按了却没跳"的挫败感
    ///  · 可变跳跃高度（提前松键 = 小跳）+ 下落加重
    ///  · 二段跳、射击（对象池）、受击击退
    /// </summary>
    [RequireComponent(typeof(Rigidbody2D), typeof(BoxCollider2D), typeof(Health))]
    public class PlayerController2D : MonoBehaviour
    {
        public PlayerConfig config;
        public LayerMask groundMask = ~(1 << 2);   // 默认排除 Ignore Raycast 层（玩家所在层）
        public Bullet bulletTemplate;

        Rigidbody2D rb;
        BoxCollider2D box;
        Health health;
        ObjectPool<Bullet> bulletPool;
        Transform visual;

        float inputX;
        bool jumpHeld, jumpPressed;
        float coyoteTimer, bufferTimer, fireTimer, stunTimer;
        int jumpsLeft;
        bool grounded, wasGrounded;

        public int Facing { get; private set; } = 1;
        public bool Grounded => grounded;
        public Vector2 Velocity => rb ? rb.velocity : Vector2.zero;
        public ObjectPool<Bullet> BulletPool => bulletPool;
        public Health Health => health;

        bool initialized;

        void Awake()
        {
            rb = GetComponent<Rigidbody2D>();
            box = GetComponent<BoxCollider2D>();
            health = GetComponent<Health>();
            rb.gravityScale = 0f;
            rb.freezeRotation = true;
            rb.interpolation = RigidbodyInterpolation2D.Interpolate;
            rb.collisionDetectionMode = CollisionDetectionMode2D.Continuous;
        }

        /// <summary>由 GameManager 在代码生成角色后调用；若角色是手动摆在场景里的，则在 Start 中自动调用。</summary>
        public void Init(PlayerConfig cfg, Bullet bullet)
        {
            if (initialized) return;
            initialized = true;
            config = cfg ? cfg : ScriptableObject.CreateInstance<PlayerConfig>();
            bulletTemplate = bullet;
            health.Setup(Team.Player, config.maxHp, config.invincibleTime);
            health.Damaged += OnDamaged;
            visual = transform.childCount > 0 ? transform.GetChild(0) : transform;
            if (bulletTemplate) bulletPool = new ObjectPool<Bullet>(bulletTemplate, 24, 64);
        }

        void Start() => Init(config, bulletTemplate);

        void OnDestroy()
        {
            if (health) health.Damaged -= OnDamaged;
        }

        // ---------------- 输入：在 Update 中采样，FixedUpdate 中消费 ----------------
        void Update()
        {
            if (!initialized || health.IsDead) return;
            inputX = Input.GetAxisRaw("Horizontal");
            jumpHeld = Input.GetButton("Jump");
            if (Input.GetButtonDown("Jump"))
            {
                bufferTimer = config.jumpBufferTime;
                jumpPressed = true;
            }
            if (Mathf.Abs(inputX) > 0.01f) Facing = inputX > 0 ? 1 : -1;

            fireTimer -= Time.deltaTime;
            if ((Input.GetButton("Fire1") || Input.GetKey(KeyCode.J)) && fireTimer <= 0f) Shoot();

            // 简单的挤压拉伸，让起跳和落地更有弹性
            Vector3 target = grounded ? Vector3.one : new Vector3(0.9f, 1.12f, 1f);
            visual.localScale = Vector3.Lerp(visual.localScale, new Vector3(target.x * Facing, target.y, 1f), 18f * Time.deltaTime);
        }

        void FixedUpdate()
        {
            if (!initialized) return;
            float dt = Time.fixedDeltaTime;
            Vector2 v = rb.velocity;

            wasGrounded = grounded;
            grounded = CheckGround();
            if (grounded)
            {
                coyoteTimer = config.coyoteTime;
                jumpsLeft = config.extraJumps;
                if (!wasGrounded) visual.localScale = new Vector3(1.2f * Facing, 0.8f, 1f);   // 落地压扁
            }
            else coyoteTimer -= dt;
            bufferTimer -= dt;
            stunTimer -= dt;

            // 1) 水平：向目标速度逼近
            if (stunTimer <= 0f)
            {
                float targetX = inputX * config.maxSpeed;
                float accel = grounded
                    ? (Mathf.Abs(targetX) > 0.01f ? config.groundAcceleration : config.groundDeceleration)
                    : config.airAcceleration;
                v.x = Mathf.MoveTowards(v.x, targetX, accel * dt);
            }

            // 2) 跳跃：地面（含土狼时间）跳优先，其次二段跳
            if (bufferTimer > 0f && coyoteTimer > 0f)
            {
                v.y = config.JumpVelocity;
                bufferTimer = coyoteTimer = 0f;
            }
            else if (jumpPressed && !grounded && coyoteTimer <= 0f && jumpsLeft > 0)
            {
                v.y = config.JumpVelocity * config.extraJumpRatio;
                jumpsLeft--;
                bufferTimer = 0f;
            }
            jumpPressed = false;

            // 3) 重力：上升松键 → 加大重力（小跳）；下落 → 加大重力（干脆）
            float g = config.Gravity;
            if (v.y < 0f) g *= config.fallGravityMultiplier;
            else if (v.y > 0f && !jumpHeld) g *= config.jumpCutGravityMultiplier;
            if (!(grounded && v.y <= 0f)) v.y -= g * dt;
            else v.y = Mathf.Max(v.y, -1f);                  // 贴地时给一点向下速度，防止斜坡弹起
            v.y = Mathf.Max(v.y, -config.maxFallSpeed);

            rb.velocity = v;
        }

        bool CheckGround()
        {
            Bounds b = box.bounds;
            Vector2 size = new Vector2(b.size.x * 0.9f, 0.05f);
            Vector2 origin = new Vector2(b.center.x, b.min.y + 0.03f);
            RaycastHit2D hit = Physics2D.BoxCast(origin, size, 0f, Vector2.down, 0.06f, groundMask);
            return hit.collider && !hit.collider.isTrigger && rb.velocity.y <= 0.01f;
        }

        void Shoot()
        {
            if (bulletPool == null) return;
            fireTimer = config.fireInterval;
            Vector3 muzzle = transform.position + new Vector3(0.55f * Facing, 0.1f, 0f);
            Bullet b = bulletPool.Get(muzzle, Quaternion.identity);
            b.Launch(new Vector2(config.bulletSpeed * Facing, 0f), config.bulletDamage, Team.Player,
                config.bulletLifetime, bulletPool.Release);
        }

        void OnDamaged(int hpLeft, Vector2 dir)
        {
            float side = Mathf.Abs(dir.x) > 0.01f ? Mathf.Sign(dir.x) : -Facing;
            rb.velocity = new Vector2(config.knockback.x * side, config.knockback.y);
            stunTimer = 0.18f;
            CameraFollow2D.Shake(0.18f, 0.25f);
        }

        /// <summary>复活到检查点。</summary>
        public void Respawn(Vector3 position)
        {
            transform.position = position;
            rb.velocity = Vector2.zero;
            health.ResetHealth();
            stunTimer = 0f;
        }
    }
}

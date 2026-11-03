using PixelLeap.Core;
using UnityEngine;

namespace PixelLeap.Enemy
{
    /// <summary>巡逻：在出生点左右往返，遇到墙壁或悬崖边缘就掉头。</summary>
    public class PatrolState : State
    {
        public PatrolState(EnemyBrain b) : base(b) { }

        protected override void Tick(float dt)
        {
            var c = brain.Config;
            if (brain.DistanceToPlayer < c.detectRange && brain.CanSeePlayer()) { brain.Fsm.Change(brain.Chase); return; }
            if (c.patrolSpeed <= 0f) { brain.Move(0f); return; }

            float offset = brain.transform.position.x - brain.HomeX;
            if ((offset > c.patrolDistance && brain.Dir > 0) || (offset < -c.patrolDistance && brain.Dir < 0)
                || brain.WallAhead() || brain.LedgeAhead())
                brain.Dir = -brain.Dir;
            brain.Move(brain.Dir * c.patrolSpeed);
        }
    }

    /// <summary>追击：朝玩家移动，进入攻击距离且冷却完毕就攻击，丢失目标后回到巡逻。</summary>
    public class ChaseState : State
    {
        public ChaseState(EnemyBrain b) : base(b) { }

        protected override void Tick(float dt)
        {
            var c = brain.Config;
            if (brain.DistanceToPlayer > c.loseRange) { brain.Fsm.Change(brain.Patrol); return; }
            brain.FacePlayer();
            if (brain.DistanceToPlayer <= c.attackRange && brain.AttackReady) { brain.Fsm.Change(brain.Attack); return; }
            bool blocked = brain.LedgeAhead() || brain.WallAhead();
            brain.Move(blocked ? 0f : brain.Dir * c.chaseSpeed);
        }
    }

    /// <summary>攻击：前摇（闪烁提示）→ 出招（三类敌人各不相同）→ 收招。</summary>
    public class AttackState : State
    {
        bool released;
        public AttackState(EnemyBrain b) : base(b) { }

        protected override void Enter()
        {
            released = false;
            brain.Move(0f);
            brain.SetTelegraph(true);
        }

        protected override void Tick(float dt)
        {
            var c = brain.Config;
            if (!released)
            {
                brain.Move(0f);
                if (Elapsed < c.windUp) return;
                released = true;
                brain.SetTelegraph(false);
                brain.StartCooldown();
                switch (c.kind)
                {
                    case EnemyKind.Walker: brain.Body.velocity = new Vector2(brain.Dir * c.lungeSpeed, brain.Body.velocity.y); break;
                    case EnemyKind.Jumper: brain.Body.velocity = new Vector2(brain.Dir * c.jumpVelocity.x, c.jumpVelocity.y); break;
                    case EnemyKind.Shooter: brain.FireProjectile(); break;
                }
                return;
            }
            // 收招：冲刺 / 扑跳落地后回到追击
            if (Elapsed > c.windUp + 0.45f && brain.Grounded) brain.Fsm.Change(brain.Chase);
        }

        public override void Exit() => brain.SetTelegraph(false);
    }

    /// <summary>受击硬直：被击退，短时间内无法行动。</summary>
    public class HurtState : State
    {
        public Vector2 HitDirection;
        public HurtState(EnemyBrain b) : base(b) { }

        protected override void Enter()
        {
            float side = Mathf.Abs(HitDirection.x) > 0.01f ? Mathf.Sign(HitDirection.x) : -brain.Dir;
            brain.Body.velocity = new Vector2(side * brain.Config.knockback, 3f);
        }

        protected override void Tick(float dt)
        {
            if (Elapsed >= brain.Config.hurtStun) brain.Fsm.Change(brain.Chase);
        }
    }

    /// <summary>死亡：关闭碰撞，播放缩小消失，通知关卡管理器。</summary>
    public class DeadState : State
    {
        public DeadState(EnemyBrain b) : base(b) { }

        protected override void Enter()
        {
            brain.Body.velocity = Vector2.zero;
            brain.Body.simulated = false;
            Level.GameManager.Instance?.OnEnemyKilled();
        }

        protected override void Tick(float dt)
        {
            float t = Mathf.Clamp01(Elapsed / 0.3f);
            brain.transform.localScale = Vector3.one * (1f - t);
            if (t >= 1f) brain.gameObject.SetActive(false);
        }
    }
}

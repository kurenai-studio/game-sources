using System;

namespace QapaqInqa.Core
{
    /// <summary>One frame of player intent, whatever device it came from.</summary>
    public readonly struct InputFrame
    {
        public InputFrame(float moveX, float moveY, bool jumpPressed, bool jumpHeld, bool fire)
        {
            MoveX = Math.Max(-1f, Math.Min(1f, moveX));
            MoveY = Math.Max(-1f, Math.Min(1f, moveY));
            JumpPressed = jumpPressed;
            JumpHeld = jumpHeld;
            Fire = fire;
        }

        public float MoveX { get; }
        public float MoveY { get; }
        public bool JumpPressed { get; }
        public bool JumpHeld { get; }
        /// <summary>Held or pressed: the bow fires again whenever its cooldown allows.</summary>
        public bool Fire { get; }

        public static readonly InputFrame None = new InputFrame(0f, 0f, false, false, false);
    }

    /// <summary>Hearts and the short mercy time after a hit.</summary>
    public sealed class Health
    {
        public Health(int max)
        {
            if (max <= 0) throw new ArgumentOutOfRangeException(nameof(max));
            Max = max;
            Hearts = max;
        }

        public int Max { get; }
        public int Hearts { get; private set; }
        public float Invulnerable { get; private set; }
        public bool IsDead => Hearts <= 0;

        /// <summary>Takes damage unless still flashing from the last hit. Returns true when it hurt.</summary>
        public bool TryHurt(int damage)
        {
            if (damage <= 0 || IsDead || Invulnerable > 0f) return false;
            Hearts = Math.Max(0, Hearts - damage);
            Invulnerable = Tuning.HurtInvulnerability;
            return true;
        }

        /// <summary>Adds a heart. Returns false (and changes nothing) when already full.</summary>
        public bool Heal(int amount)
        {
            if (amount <= 0 || IsDead || Hearts >= Max) return false;
            Hearts = Math.Min(Max, Hearts + amount);
            return true;
        }

        public void Kill() => Hearts = 0;

        public void Restore()
        {
            Hearts = Max;
            Invulnerable = 0f;
        }

        public void Tick(float dt) => Invulnerable = Math.Max(0f, Invulnerable - dt);
    }

    /// <summary>What the player body did this step (the view turns these into sounds and dust).</summary>
    [Flags]
    public enum MoveEvents
    {
        None = 0,
        Jumped = 1,
        Landed = 2,
        StartedClimbing = 4,
        Bonked = 8,
    }

    /// <summary>
    /// The platforming rules: acceleration, gravity, variable jump height, coyote time, jump
    /// buffering, dropping through ledges, and ladders.
    /// </summary>
    public sealed class PlayerMotor : Body
    {
        float coyote;
        float jumpBuffer;
        float dropThrough;
        float controlLock;
        bool canCutJump;

        public PlayerMotor(Vec2 feet) : base(Tuning.PlayerWidth, Tuning.PlayerHeight, feet)
        {
            Facing = 1;
        }

        /// <summary>+1 when facing right, -1 when facing left.</summary>
        public int Facing { get; private set; }
        public bool Climbing { get; private set; }
        public bool Rising => VelocityY > 0f && !Grounded && !Climbing;

        public MoveEvents Step(LevelMap map, InputFrame input, float dt)
        {
            MoveEvents events = MoveEvents.None;
            bool wasGrounded = Grounded;
            coyote = Grounded ? Tuning.CoyoteTime : Math.Max(0f, coyote - dt);
            jumpBuffer = input.JumpPressed ? Tuning.JumpBufferTime : Math.Max(0f, jumpBuffer - dt);
            dropThrough = Math.Max(0f, dropThrough - dt);
            controlLock = Math.Max(0f, controlLock - dt);
            float moveX = controlLock > 0f ? 0f : input.MoveX;

            if (moveX > 0.2f) Facing = 1;
            else if (moveX < -0.2f) Facing = -1;

            bool onLadder = OnRungs(map);
            bool ladderBelow = LadderAt(map, X, Y - 0.1f);
            if (!Climbing && controlLock <= 0f &&
                ((input.MoveY > 0.5f && onLadder) || (input.MoveY < -0.5f && ladderBelow && Grounded)))
            {
                Climbing = true;
                X = LevelMap.Floor(X) + 0.5f; // snap onto the rungs
                events |= MoveEvents.StartedClimbing;
            }

            if (Climbing)
            {
                if (input.JumpPressed)
                {
                    Climbing = false;
                    VelocityY = Tuning.JumpVelocity * 0.8f;
                    canCutJump = true;
                    VelocityX = moveX * Tuning.RunSpeed;
                    jumpBuffer = 0f;
                    events |= MoveEvents.Jumped;
                }
                else
                {
                    VelocityX = moveX * Tuning.ClimbSpeed * 0.5f;
                    VelocityY = input.MoveY * Tuning.ClimbSpeed;
                    Move(map, dt, ignoreLedges: true);
                    if (!OnRungs(map))
                    {
                        Climbing = false;
                        if (VelocityY > 0f)
                        {
                            // Topped out: step onto the ladder's top, which holds like a ledge.
                            Y = LevelMap.Floor(Y + 0.5f);
                            VelocityY = 0f;
                        }
                    }
                    else if (Grounded && input.MoveY < 0f)
                    {
                        Climbing = false;
                    }
                    return events;
                }
            }

            if (controlLock <= 0f)
            {
                // While knocked back the hit carries the body; afterwards the stick steers again.
                float target = moveX * Tuning.RunSpeed;
                float accel = (Grounded ? Tuning.GroundAcceleration : Tuning.AirAcceleration) * dt;
                VelocityX = Approach(VelocityX, target, accel);
            }

            if (jumpBuffer > 0f && Grounded && input.MoveY < -0.5f && StandingOnLedge(map))
            {
                dropThrough = Tuning.DropThroughTime;
                jumpBuffer = 0f;
                coyote = 0f;
            }
            else if (jumpBuffer > 0f && coyote > 0f)
            {
                VelocityY = Tuning.JumpVelocity;
                jumpBuffer = 0f;
                coyote = 0f;
                canCutJump = true;
                events |= MoveEvents.Jumped;
            }

            if (canCutJump && !input.JumpHeld && VelocityY > Tuning.JumpReleaseVelocity)
            {
                VelocityY = Tuning.JumpReleaseVelocity;
            }

            VelocityY = Math.Max(-Tuning.MaxFallSpeed, VelocityY - Tuning.Gravity * dt);
            Move(map, dt, ignoreLedges: dropThrough > 0f);
            if ((events & MoveEvents.Jumped) != 0)
            {
                coyote = 0f;
            }
            if (Grounded && !wasGrounded) events |= MoveEvents.Landed;
            if (HitCeiling) events |= MoveEvents.Bonked;
            return events;
        }

        /// <summary>Pushes the player away from a hit and takes control for a moment.</summary>
        public void Knockback(float fromX)
        {
            int away = X >= fromX ? 1 : -1;
            VelocityX = away * Tuning.KnockbackX;
            VelocityY = Tuning.KnockbackY;
            canCutJump = false;
            Climbing = false;
            controlLock = Tuning.HurtControlLock;
        }

        public void Bounce()
        {
            VelocityY = Tuning.StompBounce;
            canCutJump = true; // holding jump bounces higher
            Climbing = false;
        }

        public void Respawn(Vec2 feet)
        {
            Place(feet);
            Climbing = false;
            coyote = 0f;
            jumpBuffer = 0f;
            dropThrough = 0f;
            controlLock = 0f;
            Facing = 1;
            Grounded = false;
        }

        bool StandingOnLedge(LevelMap map)
        {
            int row = LevelMap.Floor(Y - 0.05f);
            int left = LevelMap.Floor(X - Width / 2f + 0.01f);
            int right = LevelMap.Floor(X + Width / 2f - 0.01f);
            bool anyLedge = false;
            for (int x = left; x <= right; x++)
            {
                if (map.IsSolid(x, row)) return false;
                anyLedge |= map.IsStandableTop(x, row);
            }
            return anyLedge;
        }

        /// <summary>A ladder anywhere from the feet to the chest.</summary>
        bool OnRungs(LevelMap map) => LadderAt(map, X, Y + 0.1f) || LadderAt(map, X, Y + 0.7f) || LadderAt(map, X, Y + 1.2f);

        static bool LadderAt(LevelMap map, float x, float y) => map.At(LevelMap.Floor(x), LevelMap.Floor(y)) == Tile.Ladder;

        static float Approach(float value, float target, float step)
        {
            if (value < target) return Math.Min(target, value + step);
            return Math.Max(target, value - step);
        }
    }
}

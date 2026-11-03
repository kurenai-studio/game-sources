using System;

namespace QapaqInqa.Core
{
    public enum EnemyKind
    {
        /// <summary>A stone warrior that paces its ledge and turns at walls and drops.</summary>
        Walker,
        /// <summary>A cave bat that swoops back and forth over a fixed stretch.</summary>
        Bat,
        /// <summary>The Stone Puma that guards the Gate of Inti.</summary>
        Boss,
    }

    public abstract class Enemy
    {
        protected Enemy(EnemyKind kind, int id, int health, float width, float height, Vec2 feet)
        {
            Kind = kind;
            Id = id;
            MaxHealth = health;
            HealthLeft = health;
            Width = width;
            Height = height;
            Home = feet;
            X = feet.X;
            Y = feet.Y;
        }

        public EnemyKind Kind { get; }
        /// <summary>Stable within a level, so the view can match its sprite.</summary>
        public int Id { get; }
        public int MaxHealth { get; }
        public int HealthLeft { get; protected set; }
        public float Width { get; }
        public float Height { get; }
        public Vec2 Home { get; }
        public float X { get; protected set; }
        public float Y { get; protected set; }
        public int Facing { get; protected set; } = -1;
        public bool Alive => HealthLeft > 0;
        /// <summary>Counts down after a hit so the view can flash the sprite white.</summary>
        public float Flash { get; private set; }
        public float Age { get; private set; }
        public Box Bounds => new Box(X, Y, Width, Height);
        public abstract int Points { get; }
        /// <summary>Whether landing on its head defeats (or, for the boss, hurts) it.</summary>
        public virtual bool Stompable => true;

        /// <summary>Applies damage. Returns true when this hit defeated it.</summary>
        public virtual bool Hurt(int damage)
        {
            if (!Alive || damage <= 0) return false;
            HealthLeft = Math.Max(0, HealthLeft - damage);
            Flash = Tuning.EnemyFlashTime;
            return !Alive;
        }

        public void Tick(LevelMap map, Vec2 player, float dt)
        {
            Age += dt;
            Flash = Math.Max(0f, Flash - dt);
            if (Alive) Think(map, player, dt);
        }

        protected abstract void Think(LevelMap map, Vec2 player, float dt);
    }

    public sealed class Walker : Enemy
    {
        public Walker(int id, Vec2 feet) : base(EnemyKind.Walker, id, Tuning.WalkerHealth, 0.8f, 0.95f, feet) { }

        public override int Points => Tuning.WalkerPoints;

        protected override void Think(LevelMap map, Vec2 player, float dt)
        {
            float half = Width / 2f;
            float ahead = X + Facing * (half + 0.05f);
            bool wall = map.IsSolid(LevelMap.Floor(ahead), LevelMap.Floor(Y + 0.5f));
            bool drop = !Body.GroundAt(map, ahead, Y);
            if (wall || drop)
            {
                Facing = -Facing;
                return;
            }
            X += Facing * Tuning.WalkerSpeed * dt;
        }
    }

    public sealed class Bat : Enemy
    {
        public Bat(int id, Vec2 feet) : base(EnemyKind.Bat, id, Tuning.BatHealth, 0.8f, 0.6f, feet) { }

        public override int Points => Tuning.BatPoints;

        protected override void Think(LevelMap map, Vec2 player, float dt)
        {
            X += Facing * Tuning.BatSpeed * dt;
            if (X < Home.X - Tuning.BatRange) Facing = 1;
            if (X > Home.X + Tuning.BatRange) Facing = -1;
            Y = Home.Y + (float)Math.Sin(Age * 3.2f) * 0.6f;
        }
    }

    public enum BossMove
    {
        /// <summary>Asleep on its plinth until the player comes close.</summary>
        Dormant,
        Prowl,
        Crouch,
        Leap,
        Recover,
        Throw,
        Defeated,
    }

    /// <summary>
    /// The Stone Puma: prowls toward the player, crouches and leaps at them, then hurls rocks.
    /// Below half health it moves faster and throws more. Arrows hurt it; stomping hurts it twice.
    /// </summary>
    public sealed class StonePuma : Enemy
    {
        readonly Body body;
        int rocksLeft;
        float rockTimer;

        public StonePuma(int id, Vec2 feet) : base(EnemyKind.Boss, id, Tuning.BossHealth, Tuning.BossWidth, Tuning.BossHeight, feet)
        {
            body = new Body(Tuning.BossWidth, Tuning.BossHeight, feet);
            Move = BossMove.Dormant;
        }

        public BossMove Move { get; private set; }
        public float MoveTime { get; private set; }
        public bool Enraged => Alive && HealthLeft * 2 <= MaxHealth;
        public bool Grounded => body.Grounded;
        public override int Points => Tuning.BossPoints;
        /// <summary>Set for one step when a rock should be thrown at the player.</summary>
        public bool ThrowsRockNow { get; private set; }
        /// <summary>Set for one step when it lands from a leap (the view shakes the screen).</summary>
        public bool SlammedNow { get; private set; }
        public bool WokeNow { get; private set; }

        public override bool Hurt(int damage)
        {
            if (Move == BossMove.Dormant) Wake();
            bool defeated = base.Hurt(damage);
            if (defeated)
            {
                ThrowsRockNow = false;
                SlammedNow = false;
                Switch(BossMove.Defeated);
            }
            return defeated;
        }

        /// <summary>Back to sleep at full strength (used when the player loses a life mid-fight).</summary>
        public void Reset()
        {
            HealthLeft = MaxHealth;
            body.Place(Home);
            X = Home.X;
            Y = Home.Y;
            Facing = -1;
            Switch(BossMove.Dormant);
        }

        void Wake()
        {
            WokeNow = true;
            Switch(BossMove.Prowl);
        }

        void Switch(BossMove move)
        {
            Move = move;
            MoveTime = 0f;
        }

        protected override void Think(LevelMap map, Vec2 player, float dt)
        {
            ThrowsRockNow = false;
            SlammedNow = false;
            WokeNow = false;
            MoveTime += dt;
            float toPlayer = player.X - body.X;
            float speedUp = Enraged ? 1.4f : 1f;

            switch (Move)
            {
                case BossMove.Dormant:
                    if (Math.Abs(toPlayer) < Tuning.BossWakeDistance && Math.Abs(player.Y - body.Y) < 4f) Wake();
                    break;
                case BossMove.Prowl:
                    Facing = toPlayer >= 0f ? 1 : -1;
                    body.VelocityX = Facing * Tuning.BossProwlSpeed * speedUp;
                    if (MoveTime > 1.4f / speedUp || Math.Abs(toPlayer) < 2.5f) Switch(BossMove.Crouch);
                    break;
                case BossMove.Crouch:
                    body.VelocityX = 0f;
                    Facing = toPlayer >= 0f ? 1 : -1;
                    if (MoveTime > 0.45f / speedUp)
                    {
                        // Leap so that it would land where the player stands now.
                        const float rise = 13f;
                        float airTime = 2f * rise / Tuning.Gravity;
                        body.VelocityY = rise;
                        body.VelocityX = Math.Max(-9f, Math.Min(9f, toPlayer / airTime));
                        Switch(BossMove.Leap);
                    }
                    break;
                case BossMove.Leap:
                    if (body.Grounded && MoveTime > 0.1f)
                    {
                        body.VelocityX = 0f;
                        SlammedNow = true;
                        Switch(BossMove.Recover);
                    }
                    break;
                case BossMove.Recover:
                    body.VelocityX = 0f;
                    if (MoveTime > 0.8f / speedUp)
                    {
                        rocksLeft = Enraged ? 5 : 3;
                        rockTimer = 0.2f;
                        Switch(BossMove.Throw);
                    }
                    break;
                case BossMove.Throw:
                    body.VelocityX = 0f;
                    Facing = toPlayer >= 0f ? 1 : -1;
                    rockTimer -= dt;
                    if (rockTimer <= 0f && rocksLeft > 0)
                    {
                        ThrowsRockNow = true;
                        rocksLeft--;
                        rockTimer = 0.38f / speedUp;
                    }
                    if (rocksLeft == 0 && rockTimer <= 0f) Switch(BossMove.Prowl);
                    break;
            }

            if (Move != BossMove.Dormant)
            {
                body.VelocityY = Math.Max(-Tuning.MaxFallSpeed, body.VelocityY - Tuning.Gravity * dt);
                body.Move(map, dt);
            }
            X = body.X;
            Y = body.Y;
        }

        /// <summary>A rock thrown from the paw toward <paramref name="target"/>, arcing under gravity.</summary>
        public Rock MakeRock(Vec2 target, int index)
        {
            var from = new Vec2(X + Facing * Width * 0.45f, Y + Height * 0.7f);
            const float flight = 0.9f;
            float spread = (index % 3 - 1) * 0.9f;
            float vx = (target.X + spread - from.X) / flight;
            float vy = (target.Y + 0.6f - from.Y) / flight + 0.5f * Tuning.RockGravity * flight;
            return new Rock(from, new Vec2(vx, vy));
        }
    }

    /// <summary>A rock the boss throws. It falls under gravity and shatters on stone.</summary>
    public sealed class Rock
    {
        public Rock(Vec2 position, Vec2 velocity)
        {
            Position = position;
            Velocity = velocity;
        }

        public Vec2 Position { get; private set; }
        public Vec2 Velocity { get; private set; }
        public bool Gone { get; set; }
        public Box Bounds => new Box(Position.X, Position.Y - 0.3f, 0.6f, 0.6f);

        public void Tick(LevelMap map, float dt)
        {
            Velocity = new Vec2(Velocity.X, Velocity.Y - Tuning.RockGravity * dt);
            Position += Velocity * dt;
            if (map.IsSolid(LevelMap.Floor(Position.X), LevelMap.Floor(Position.Y)) || Position.Y < -2f)
            {
                Gone = true;
            }
        }
    }

    /// <summary>An arrow from the player's bow: flies straight and stops at the first stone or enemy.</summary>
    public sealed class Arrow
    {
        public Arrow(Vec2 position, int direction)
        {
            Position = position;
            Direction = direction;
        }

        public Vec2 Position { get; private set; }
        public int Direction { get; }
        public float Age { get; private set; }
        public bool Gone { get; set; }
        public Box Bounds => new Box(Position.X, Position.Y - 0.1f, 0.6f, 0.2f);

        public void Tick(LevelMap map, float dt)
        {
            Age += dt;
            Position += new Vec2(Direction * Tuning.ArrowSpeed * dt, 0f);
            if (Age > Tuning.ArrowLifetime || map.IsSolid(LevelMap.Floor(Position.X + Direction * 0.3f), LevelMap.Floor(Position.Y)))
            {
                Gone = true;
            }
        }
    }
}

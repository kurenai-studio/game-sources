namespace QapaqInqa.Core
{
    /// <summary>
    /// Every number that shapes how the game feels, in tiles and seconds (one tile is one world unit).
    /// With these values a jump rises about 2.6 tiles and clears a gap of about 4 tiles.
    /// </summary>
    public static class Tuning
    {
        public const float Step = 1f / 60f;

        // Player body and movement.
        public const float PlayerWidth = 0.7f;
        public const float PlayerHeight = 1.4f;
        public const float RunSpeed = 7f;
        public const float GroundAcceleration = 70f;
        public const float AirAcceleration = 45f;
        public const float Gravity = 45f;
        public const float MaxFallSpeed = 20f;
        public const float JumpVelocity = 15.3f;
        /// <summary>Releasing jump early caps the rise at this speed, so a tap is a short hop.</summary>
        public const float JumpReleaseVelocity = 6f;
        public const float CoyoteTime = 0.1f;
        public const float JumpBufferTime = 0.12f;
        public const float ClimbSpeed = 4.5f;
        public const float DropThroughTime = 0.25f;

        // Health.
        public const int MaxHearts = 3;
        public const int StartingLives = 3;
        public const int MaxLives = 9;
        public const float HurtInvulnerability = 1.2f;
        public const float HurtControlLock = 0.25f;
        public const float KnockbackX = 6f;
        public const float KnockbackY = 9f;
        public const float StompBounce = 12f;
        public const float DyingTime = 1.2f;
        /// <summary>Falling this far below the map loses a life.</summary>
        public const float FallOutDepth = -3f;

        // Bow.
        public const float ArrowSpeed = 17f;
        public const float ArrowLifetime = 1.1f;
        public const float FireCooldown = 0.32f;
        public const int ArrowDamage = 1;

        // Enemies.
        public const float WalkerSpeed = 2f;
        public const int WalkerHealth = 2;
        public const float BatSpeed = 2.6f;
        public const float BatRange = 3f;
        public const int BatHealth = 1;
        public const int BossHealth = 24;
        public const float BossWidth = 2.4f;
        public const float BossHeight = 1.7f;
        public const float BossProwlSpeed = 3f;
        public const float BossWakeDistance = 11f;
        public const float RockGravity = 22f;
        public const float EnemyFlashTime = 0.12f;

        // Points.
        public const int CoinPoints = 100;
        public const int ArtifactPoints = 300;
        public const int ShellPoints = 500;
        public const int SpareHeartPoints = 250;
        public const int WalkerPoints = 50;
        public const int BatPoints = 75;
        public const int BossPoints = 2000;
        public const int StompBonus = 25;
        /// <summary>Points per second left under the level's par time.</summary>
        public const int TimeBonusPerSecond = 20;
        public const int LifeBonus = 1000;
    }
}

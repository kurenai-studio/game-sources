namespace Proto4X.Sandbox.Components
{
    public enum FactionId
    {
        Neutral = 0,
        Player = 1,
        Enemy = 2,
        Rival = 3,
    }

    public struct Faction(FactionId id)
    {
        public FactionId Id = id;

        /// <summary>Every faction that actually plays. Neutral owns asteroids and nothing else.</summary>
        public static readonly FactionId[] Playing = [FactionId.Player, FactionId.Enemy, FactionId.Rival];

        /// <summary>The AI-controlled factions - everyone except the player.</summary>
        public static readonly FactionId[] AiControlled = [FactionId.Enemy, FactionId.Rival];
    }
}

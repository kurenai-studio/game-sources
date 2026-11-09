using Microsoft.Xna.Framework;

namespace PortalMercenary.Game;

public class CharacterOptions
{
    public string Atlas { get; set; }
    public float MovementSpeed { get; set; }
    public float RunMovementSpeed { get; set; }

    public AttackOptions Attack { get; set; }
    
    public string[] DamageSounds { get; set; }

    public class AttackOptions
    {
        public float ActorAnimationDuration { get; set; }
        public string SpriteSheet { get; set; }
        public string Sound { get; set; }
        public float Distance { get; set; }
    }
}
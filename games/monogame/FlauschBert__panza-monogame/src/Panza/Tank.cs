using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace org.flauschhaus.Panza {

public class Tank {

// Derive properties from property Player
public Texture2D TankSprite { get; set; }
public Texture2D GunSprite { get; set; }
public Vector2 Direction { get; set; }
public Vector2 GunDirection { get; set; }

// Derive properties from window size
public Vector2 Position { get; set; }

// Derive properties from property Sprite

public Tank (int player, Vector2 windowSize)
{
  var defaultTank = DefaultTank.GetTank (player);
  Direction = defaultTank.Direction;
  GunDirection = defaultTank.GunDirection;
  Position = DefaultTank.GetPosition (defaultTank.PositionInfo, windowSize);
}

} // Tank

} // ns

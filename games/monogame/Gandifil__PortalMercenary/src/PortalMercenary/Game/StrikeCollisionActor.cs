using Microsoft.Xna.Framework;
using MonoGame.Extended;
using MonoGame.Extended.Collisions;

namespace PortalMercenary.Game;

public class StrikeCollisionActor: ICollisionActor
{
    public StrikeCollisionActor(Vector2 center)
    {
        Id = GetHashCode();
        Shape = new CollisionShape2D(new BoundingCircle2D(center, 10));
    }
    public int Id { get; }
    public CollisionShape2D Shape { get; }
}
using Microsoft.Xna.Framework;
using OrbitDefender.Models;

namespace OrbitDefender.Services;

public sealed class CollisionService : ICollisionService
{
    public bool PlayerHitsAsteroid(PlayerShip player, Asteroid asteroid)
    {
        return AreIntersecting(player.Position, player.Radius, asteroid.Position, asteroid.Radius);
    }

    public bool ShotHitsAsteroid(LaserShot shot, Asteroid asteroid)
    {
        return AreIntersecting(shot.Position, shot.Radius, asteroid.Position, asteroid.Radius);
    }

    private static bool AreIntersecting(Vector2 aPosition, float aRadius, Vector2 bPosition, float bRadius)
    {
        var maxDistance = aRadius + bRadius;
        return Vector2.DistanceSquared(aPosition, bPosition) <= maxDistance * maxDistance;
    }
}

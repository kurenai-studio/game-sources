using OrbitDefender.Models;

namespace OrbitDefender.Services;

public interface ICollisionService
{
    bool PlayerHitsAsteroid(PlayerShip player, Asteroid asteroid);
    bool ShotHitsAsteroid(LaserShot shot, Asteroid asteroid);
}

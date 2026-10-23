using Microsoft.Xna.Framework;
using OrbitDefender.Core;
using OrbitDefender.Models;

namespace OrbitDefender.Services;

public interface ISpawnService
{
    Asteroid CreateAsteroid(GameSession session, Rectangle playBounds);
    void PopulateStars(ICollection<Star> stars, Rectangle playBounds);
    void RecycleStar(Star star, Rectangle playBounds);
}

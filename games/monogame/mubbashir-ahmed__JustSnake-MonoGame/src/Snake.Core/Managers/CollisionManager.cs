using Microsoft.Xna.Framework;
using Snake.Core.Collisions;
using Snake.Core.Common;
using Snake.Core.Graphics;
using System;

namespace Snake.Core.Managers
{
    /// <summary>
    /// Manages collision detection between game entities.
    /// </summary>
    public class CollisionManager
    {
        /// <summary>
        /// Checks if the snake's head collides with a wall.
        /// </summary>
        /// <param name="snake">The snake to check.</param>
        /// <param name="tilemap">The tilemap to check against.</param>
        /// <returns>True if the snake collides with a wall, false otherwise.</returns>
        public bool IsSnakeCollideWithWall(Graphics.Snake snake, Tilemap tilemap)
        {
            ArgumentNullException.ThrowIfNull(snake);
            ArgumentNullException.ThrowIfNull(tilemap);

            // Convert the snake's head position to tile coordinates
            Point tilePosition = Helper.WorldToTile(snake.HeadSegment.To, tilemap);

            // Return true if the snake collides with a wall, false otherwise
            return tilemap.IsWall(tilePosition.X, tilePosition.Y);
        }

        /// <summary>
        /// Checks if the snake's head collides with food.
        /// </summary>
        /// <param name="snake">The snake to check.</param>
        /// <param name="food">The food to check against.</param>
        /// <returns>True if the snake collides with food, false otherwise.</returns>
        public bool IsSnakeCollideWithFood(Graphics.Snake snake, Food food)
        {
            ArgumentNullException.ThrowIfNull(snake);
            ArgumentNullException.ThrowIfNull(food);

            // Get the snake's bounds
            Circle snakeBounds = snake.GetBounds(snake.HeadSegment);
            Circle foodBounds = food.GetBounds();

            // Return true if the snake collides with food, false otherwise
            return snakeBounds.Intersect(foodBounds);
        }
    }
}

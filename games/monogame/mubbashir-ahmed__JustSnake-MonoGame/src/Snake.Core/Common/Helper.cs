using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Snake.Core.Collisions;
using Snake.Core.Graphics;
using System;

namespace Snake.Core.Common
{
    /// <summary>
    /// Provides utility methods for common game operations.
    /// </summary>
    public static class Helper
    {
        /// <summary>
        /// The random number generator.
        /// </summary>
        private static readonly Random random = new Random();

        /// <summary>
        /// The minimum playable column.
        /// </summary>
        private const int MinPlayableColumn = 1;

        /// <summary>
        /// The minimum playable row.
        /// </summary>
        private const int MinPlayableRow = 1;

        /// <summary>
        /// The wall thickness.
        /// </summary>
        private const int WallThickness = 2;

        /// <summary>
        /// The viewport padding factor.
        /// </summary>
        private const float ViewportPaddingFactor = 0.015f;

        /// <summary>
        /// The half size factor of 0.5f.
        /// </summary>
        private const float HalfSizeFactor = 0.5f;

        /// <summary>
        /// Converts a world position to tile coordinates.
        /// </summary>
        /// <param name="position">The world position to convert.</param>
        /// <param name="tilemap">The tilemap to use for conversion.</param>
        /// <returns>The tile coordinates as a Point.</returns>
        public static Point WorldToTile(Vector2 position, Tilemap tilemap)
        {
            ArgumentNullException.ThrowIfNull(tilemap);

            // Return the tile coordinates
            return new Point(
                (int)(position.X / tilemap.TileWidth),
                (int)(position.Y / tilemap.TileHeight)
            );
        }

        /// <summary>
        /// Generates a random position within the playable area of the tilemap.
        /// </summary>
        /// <param name="tilemap">The tilemap to generate a position within.</param>
        /// <returns>A random Vector2 position within the playable bounds.</returns>
        public static Vector2 GetRandomVector2(Tilemap tilemap)
        {
            ArgumentNullException.ThrowIfNull(tilemap);

            // Get the tile width and height
            float tileWidth = tilemap.TileWidth;
            float tileHeight = tilemap.TileHeight;

            // Get the maximum column and row
            int maxCol = tilemap.Columns - WallThickness;
            int maxRow = tilemap.Rows - WallThickness;

            // Generate a random cell X and Y
            int cellX = random.Next(MinPlayableColumn, maxCol + 1);
            int cellY = random.Next(MinPlayableRow, maxRow + 1);

            // Return the random position
            return new Vector2(cellX * tileWidth, cellY * tileHeight);
        }

        /// <summary>
        /// Calculates the center position for a texture region on the screen.
        /// </summary>
        /// <param name="graphicsDevice">The graphics device.</param>
        /// <param name="region">The texture region to center.</param>
        /// <returns>The centered position as a Vector2.</returns>
        public static Vector2 GetCenterScreenVector2(Viewport screenSize, TextureRegion region)
        {
            ArgumentNullException.ThrowIfNull(screenSize);
            ArgumentNullException.ThrowIfNull(region);

            // Return the center position from the screen size vector with optional padding
            return new Vector2(
                (screenSize.Width - region.Width) * HalfSizeFactor,
                (screenSize.Height - region.Height) * HalfSizeFactor
            );
        }

        /// <summary>
        /// Calculates the center position from a screen size vector.
        /// </summary>
        /// <param name="screenSize">The screen size vector.</param>
        /// <param name="vector">The vector to center.</param>
        /// <returns>The center position as a Vector2.</returns>
        public static Vector2 GetCenterScreenVector2(Viewport screenSize, Vector2 vector)
        {
            ArgumentNullException.ThrowIfNull(screenSize);
            ArgumentNullException.ThrowIfNull(vector);

            // Return the center position from the screen size vector with optional padding
            return new Vector2(
                (screenSize.Width - vector.X) * HalfSizeFactor,
                (screenSize.Height - vector.Y) * HalfSizeFactor
            );
        }

        /// <summary>
        /// Calculates the center position from a screen size vector.
        /// </summary>
        /// <param name="screenSize">The screen size vector.</param>
        /// <returns>The center position as a Vector2.</returns>
        public static Vector2 GetCenterScreenVector2(Vector2 screenSize)
        {
            // Return the center position from the screen size vector
            return new Vector2(
                screenSize.X * HalfSizeFactor,
                screenSize.Y * HalfSizeFactor
            );
        }

        /// <summary>
        /// Calculates the top-left position with optional padding.
        /// </summary>
        /// <param name="graphicsDevice">The graphics device.</param>
        /// <param name="position">The base position.</param>
        /// <param name="paddingX">The horizontal padding (default: 0).</param>
        /// <param name="paddingY">The vertical padding (default: 0).</param>
        /// <returns>The top-left position as a Vector2.</returns>
        public static Vector2 GetTopLeftVector2(GraphicsDevice graphicsDevice, Vector2 position, float paddingX = 0, float paddingY = 0)
        {
            ArgumentNullException.ThrowIfNull(graphicsDevice);

            // Return the top-left position with optional padding
            return new Vector2(
                graphicsDevice.Viewport.X * ViewportPaddingFactor + paddingX,
                graphicsDevice.Viewport.Y * ViewportPaddingFactor + paddingY
            );
        }

        /// <summary>
        /// Checks if a position overlaps with any snake segment.
        /// </summary>
        /// <param name="checkPosition">The position to check.</param>
        /// <param name="snake">The snake to check against.</param>
        /// <param name="foodSprite">The food sprite used to determine the check circle size.</param>
        /// <returns>True if the position overlaps with any snake segment, false otherwise.</returns>
        public static bool IsPositionOnAnySnakeSegment(Vector2 checkPosition, Graphics.Snake snake, AnimatedSprite foodSprite)
        {
            ArgumentNullException.ThrowIfNull(snake);
            ArgumentNullException.ThrowIfNull(foodSprite);

            // Calculate the radius of the check circle
            float radius = foodSprite.Width * HalfSizeFactor;

            // Create a new circle for the check
            Circle checkCircle = new Circle(
                (int)(checkPosition.X + radius),
                (int)(checkPosition.Y + radius),
                (int)radius
            );

            // Check if the check circle intersects with the snake's head segment
            return checkCircle.Intersect(snake.GetBounds(snake.HeadSegment));
        }
    }
}

using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using System;

namespace Snake.Core.Graphics
{
    public class TextureRegion
    {
        /// <summary>
        /// The texture of the region.
        /// </summary>
        /// <returns>The texture of the region.</returns>
        public Texture2D Texture { get; set; }

        /// <summary>
        /// The source rectangle of the region.
        /// </summary>
        /// <returns>The source rectangle of the region.</returns>
        public Rectangle SourceRectangle { get; set; }
        
        /// <summary>
        /// The width of the region. The width is the width of the source rectangle.
        /// </summary>
        /// <returns>The width of the region.</returns>
        public int Width => SourceRectangle.Width;

        /// <summary>
        /// The height of the region. The height is the height of the source rectangle.
        /// </summary>
        /// <returns>The height of the region.</returns>
        public int Height => SourceRectangle.Height;

        /// <summary>
        /// Initializes a new instance of the TextureRegion class.
        /// </summary>
        /// <returns>A new instance of the TextureRegion class.</returns>
        public TextureRegion() { }

        /// <summary>
        /// Initializes a new instance of the TextureRegion class with a texture, x, y, width, and height.
        /// </summary>
        /// <param name="texture">The texture of the region.</param>
        /// <param name="x">The x position of the region.</param>
        /// <param name="y">The y position of the region.</param>
        /// <param name="width">The width of the region.</param>
        /// <param name="height">The height of the region.</param>
        /// <returns>A new instance of the TextureRegion class.</returns>
        public TextureRegion(Texture2D texture, int x, int y, int width, int height)
        {
            // Check if the texture is null and throw an exception
            ArgumentNullException.ThrowIfNull(texture);

            // Check if the width is less than or equal to zero and throw an exception
            if (width <= 0)
                throw new ArgumentOutOfRangeException(nameof(width));

            // Check if the height is less than or equal to zero and throw an exception
            if (height <= 0)
                throw new ArgumentOutOfRangeException(nameof(height));

            // Set the texture and source rectangle
            Texture = texture;

            // Set the source rectangle
            SourceRectangle = new Rectangle(x, y, width, height);
        }

        /// <summary>
        /// Draws the region to the sprite batch.
        /// </summary>
        /// <param name="spriteBatch">The sprite batch to draw to.</param>
        /// <param name="position">The position of the region.</param>
        /// <param name="color">The color of the region.</param>
        /// <param name="rotation">The rotation of the region.</param>
        /// <param name="origin">The origin of the region.</param>
        /// <param name="scale">The scale of the region.</param>
        /// <param name="effects">The effects of the region.</param>
        /// <param name="layerDepth">The layer depth of the region.</param>
        public void Draw(SpriteBatch spriteBatch, Vector2 position, Color color, float rotation, Vector2 origin, Vector2 scale, SpriteEffects effects, float layerDepth)
        {
            // Draw the region
            spriteBatch.Draw(
                Texture,
                position,
                SourceRectangle,
                color,
                rotation,
                origin,
                scale,
                effects,
                layerDepth
            );
        }
    }
}

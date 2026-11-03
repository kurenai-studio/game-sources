using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using System;

namespace Snake.Core.Graphics
{
    public class Sprite
    {
        /// <summary>
        /// The region of the texture to draw.
        /// </summary>
        /// <returns>The region of the texture to draw.</returns>
        public TextureRegion Region { get; set;}

        /// <summary>
        /// The position of the sprite. Default is (0, 0).
        /// </summary>
        /// <returns>The position of the sprite.</returns>
        public Vector2 Position { get; set; } = Vector2.Zero;
        
        /// <summary>
        /// The color of the sprite. Default is white.
        /// </summary>
        /// <returns>The color of the sprite.</returns>
        public Color Color { get; set; } = Color.White;
        
        /// <summary>
        /// The rotation of the sprite. Default is 0.0f.
        /// </summary>
        /// <returns>The rotation of the sprite.</returns>
        public float Rotation { get; set; } = 0.0f;
        
        /// <summary>
        /// The scale of the sprite. Default is (1, 1).
        /// </summary>
        /// <returns>The scale of the sprite.</returns>
        public Vector2 Scale { get; set; } = Vector2.One;
        
        /// <summary>
        /// The origin of the sprite. Default is (0, 0).
        /// </summary>
        /// <returns>The origin of the sprite.</returns>
        public Vector2 Origin { get; set; } = Vector2.Zero;
        
        /// <summary>
        /// The effects of the sprite. Default is none.
        /// </summary>
        /// <returns>The effects of the sprite.</returns>
        public SpriteEffects Effects { get; set; } = SpriteEffects.None;
        
        /// <summary>
        /// The layer depth of the sprite. Default is 0.0f.
        /// </summary>
        /// <returns>The layer depth of the sprite.</returns>
        public float LayerDepth { get; set; } = 0.0f;

        /// <summary>
        /// Gets the width of the sprite.
        /// </summary>
        public float Width => Region?.Width * Scale.X ?? 0;

        /// <summary>
        /// Gets the height of the sprite.
        /// </summary>
        public float Height => Region?.Height * Scale.Y ?? 0;

        /// <summary>
        /// Initializes a new instance of the Sprite class.
        /// </summary>
        public Sprite() { }

        /// <summary>
        /// Initializes a new instance of the Sprite class with a region.
        /// </summary>
        /// <param name="region">The region of the texture to draw.</param>
        /// <returns>A new instance of the Sprite class.</returns>
        public Sprite(TextureRegion region)
        {
            ArgumentNullException.ThrowIfNull(region);

            // Set the region
            Region = region;
        }

        /// <summary>
        /// Draws the sprite to the sprite batch.
        /// </summary>
        /// <param name="spriteBatch">The sprite batch to draw to.</param>
        public void Draw(SpriteBatch spriteBatch)
        {
            // Draw the region
            Region.Draw(
                spriteBatch,
                Position, 
                Color, 
                Rotation,
                Origin,
                Scale,
                Effects, 
                LayerDepth
            );
        }
    }
}

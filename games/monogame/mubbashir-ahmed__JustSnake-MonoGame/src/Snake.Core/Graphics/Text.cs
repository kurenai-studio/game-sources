using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Snake.Core.Enums;
using System;

namespace Snake.Core.Graphics
{
    /// <summary>
    /// Represents a text element that can be drawn to the screen.
    /// </summary>
    public class Text
    {
        /// <summary>
        /// The text string to display.
        /// </summary>
        private string textString;

        /// <summary>
        /// The sprite font to use for rendering.
        /// </summary>
        private SpriteFont spriteFont;

        /// <summary>
        /// Gets or sets the text string to display.
        /// </summary>
        public string TextString { get => textString; set => textString = value; }

        /// <summary>
        /// Gets or sets the sprite font to use for rendering.
        /// </summary>
        public SpriteFont SpriteFont { get => spriteFont; set => spriteFont = value; }

        /// <summary>
        /// Gets or sets the position of the text.
        /// </summary>
        public Vector2 Position { get; set; } = Vector2.Zero;

        /// <summary>
        /// Gets or sets the color of the text.
        /// </summary>
        public Color Color { get; set; } = Color.White;

        /// <summary>
        /// Gets or sets the rotation of the text in radians.
        /// </summary>
        public float Rotation { get; set; } = 0.0f;

        /// <summary>
        /// Gets or sets the scale of the text.
        /// </summary>
        public Vector2 Scale { get; set; } = Vector2.One;

        /// <summary>
        /// Gets or sets the origin point for rotation and scaling.
        /// </summary>
        public Vector2 Origin { get; set; } = Vector2.Zero;

        /// <summary>
        /// Gets or sets the sprite effects to apply.
        /// </summary>
        public SpriteEffects Effects { get; set; } = SpriteEffects.None;

        /// <summary>
        /// Gets or sets the layer depth for sorting.
        /// </summary>
        public float LayerDepth { get; set; } = 0.0f;

        public Rectangle RectangleBounds => GetRectangleBounds();

        /// <summary>
        /// Initializes a new instance of the Text class.
        /// </summary>
        public Text() { }

        /// <summary>
        /// Initializes a new instance of the Text class with a text string.
        /// </summary>
        /// <param name="textString">The text string to display.</param>
        public Text(string textString)
        {
            ArgumentNullException.ThrowIfNull(textString);

            // Set the text string
            this.textString = textString;
        }

        /// <summary>
        /// Gets the size of the text.
        /// </summary>
        /// <returns>The size of the text.</returns>
        public Vector2 GetTextSize()
        {
            ArgumentNullException.ThrowIfNull(SpriteFont);

            // Measure the text string
            Vector2 textSize = SpriteFont.MeasureString(TextString);

            // Scale the text size
            Vector2 scaledTextSize = textSize * Scale;

            // Return the scaled text size
            return scaledTextSize;
        }

        /// <summary>
        /// Gets the origin of the text.
        /// </summary>
        /// <param name="horizontalAlignment">The horizontal alignment of the text.</param>
        /// <returns>The origin of the text.</returns>
        public Vector2 GetOrigin(HorizontalAlignment horizontalAlignment, VerticalAlignment verticalAlignment)
        {
            ArgumentNullException.ThrowIfNull(SpriteFont);

            // Get the text size
            Vector2 textSize = this.GetTextSize();

            // Set the origin to zero
            Vector2 origin = Vector2.Zero;

            // Set the x origin
            origin.X = horizontalAlignment switch
            {
                HorizontalAlignment.Left => 0,
                HorizontalAlignment.Center => textSize.X / 2,
                HorizontalAlignment.Right => -textSize.X,
                _ => 0,
            };

            // Set the y origin
            origin.Y = verticalAlignment switch
            {
                VerticalAlignment.Top => 0,
                VerticalAlignment.Middle => textSize.Y / 2,
                VerticalAlignment.Bottom => -textSize.Y,
                _ => 0,
            };

            // Return the origin
            return origin;
        }

        /// <summary>
        /// Gets the rectangle bounds of the text.
        /// </summary>
        /// <returns>The rectangle bounds of the text.</returns>
        public Rectangle GetRectangleBounds()
        {
            ArgumentNullException.ThrowIfNull(SpriteFont);
            ArgumentNullException.ThrowIfNull(TextString);

            // Measure the text string
            Vector2 measuredSize = SpriteFont.MeasureString(TextString);

            // Scale the text size
            Vector2 scaledSize = new Vector2(measuredSize.X * Scale.X, measuredSize.Y * Scale.Y);

            // Set the top left position
            Vector2 topLeft = new Vector2(
                Position.X - Origin.X * Scale.X,
                Position.Y - Origin.Y * Scale.Y
            );

            // Return the rectangle bounds
            return new Rectangle(
                (int)topLeft.X,
                (int)topLeft.Y,
                (int)scaledSize.X,
                (int)scaledSize.Y
            );
        }

        /// <summary>
        /// Draws the text to the sprite batch.
        /// </summary>
        /// <param name="spriteBatch">The sprite batch to draw to.</param>
        public void Draw(SpriteBatch spriteBatch)
        {
            // Draw the text string
            spriteBatch.DrawString(
                SpriteFont,
                TextString,
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

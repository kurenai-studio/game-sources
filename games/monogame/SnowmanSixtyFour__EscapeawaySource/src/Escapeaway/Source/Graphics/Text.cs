using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace Escapeaway.Source.Graphics
{
    internal class Text
    {
        protected SpriteFont font = Global.defaultFont;
        protected String text;
        protected Vector2
            position,
            origin;
        protected Color color = Color.White;
        protected float size = 1.0f;
        public readonly bool centered = false;

        public Text(SpriteFont font, String text, Vector2 position, Color color, float size, bool centered)
        {
            // Initialize Text
            setFont(font);
            setText(text);
            setPosition(position);
            setColor(color);
            setSize(size);
            this.centered = centered;
        }

        public void Draw(SpriteBatch spriteBatch)
        {
            spriteBatch.DrawString(font, text, position, color, 0, origin, size, SpriteEffects.None, 0.5f);
        }

        // Getters

        public SpriteFont getFont()
        {
            return this.font;
        }

        public String getText()
        {
            return this.text;
        }

        public Vector2 getPosition()
        {
            return this.position;
        }

        public Color getColor()
        {
            return this.color;
        }

        public float getSize()
        {
            return this.size;
        }

        // Setters

        public void setFont(SpriteFont newFont)
        {
            this.font = newFont;
        }

        public void setText(String newText)
        {
            // Update Text
            this.text = newText;

            // Find the center of the string
            if (centered) origin = (font.MeasureString(text) / 2);
        }

        public void setPosition(Vector2 newPosition)
        {
            this.position = newPosition;
        }

        public void setColor(Color newColor)
        {
            this.color = newColor;
        }

        public void setSize(float newSize)
        {
            this.size = newSize;
        }
    }
}

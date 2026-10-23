using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Escapeaway.Source;

namespace Escapeaway.Source.Graphics
{
    internal class StaticSprite
    {
        protected Texture2D texture;
        protected Rectangle destRect;
        protected Color color;

        public bool tiled;
        public float xOffset, yOffset; // Offset values for tiled scrolling

        public StaticSprite(Texture2D texture, Rectangle rect, Color color, bool tiled = false)
        {
            // Error check
            if (texture == null) texture = Global.noImg;

            // Initialize sprite
            SetTexture(texture);
            SetDestRect(rect);
            SetColor(color);

            // Set Tiled
            this.tiled = tiled;
        }

        public void Draw(SpriteBatch spriteBatch)
        {
            // If Sprite is Tiled
            if (tiled)
            {
                // End Default SpriteBatch if Sprite is Tiled
                spriteBatch.End();

                // Draw with Sampler State set to Point Wrap
                spriteBatch.Begin(samplerState: SamplerState.PointWrap);
            }

            // Draw Sprite
            if (!tiled) spriteBatch.Draw(texture, destRect, color);

            // Draw Tiled Sprite (With Offset)
            else spriteBatch.Draw(texture, destRect, new Rectangle(new Point((int)xOffset, (int)yOffset), destRect.Size), color);

            // End Tiled SpriteBatch
            if (tiled) spriteBatch.End();

            // Restart Default SpriteBatch
            if (tiled)
            {
                spriteBatch.Begin(SpriteSortMode.Deferred,
                BlendState.AlphaBlend,
                SamplerState.PointClamp,
                DepthStencilState.None,
                RasterizerState.CullNone
                );
            }
        }

        // --- Getters ---

        public Texture2D GetTexture()
        {
            return this.texture;
        }

        public Rectangle GetDestRect()
        {
            return this.destRect;
        }

        public Color GetColor()
        {
            return this.color;
        }

        // Position and Size

        public int GetX()
        {
            return this.destRect.X;
        }

        public int GetY()
        {
            return this.destRect.Y;
        }

        public int GetWidth()
        {
            return this.destRect.Width;
        }

        public int GetHeight()
        {
            return this.destRect.Height;
        }

        // --- Setters ---

        public void SetTexture(Texture2D newTexture)
        {
            this.texture = newTexture;
        }

        public void SetDestRect(Rectangle newRect)
        {
            this.destRect = newRect;
        }

        public void SetColor(Color newColor)
        {
            this.color = newColor;
        }

        // Position and Size

        public void SetX(int newX)
        {
            this.destRect.X = newX;
        }

        public void SetY(int newY)
        {
            this.destRect.Y = newY;
        }

        public void SetWidth(int newWidth)
        {
            this.destRect.Width = newWidth;
        }

        public void SetHeight(int newHeight)
        {
            this.destRect.Height = newHeight;
        }
    }
}

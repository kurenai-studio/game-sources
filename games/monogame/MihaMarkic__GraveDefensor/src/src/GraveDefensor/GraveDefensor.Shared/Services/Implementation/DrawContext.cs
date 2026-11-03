using System.Text;
using GraveDefensor.Shared.Core;
using GraveDefensor.Shared.Service.Abstract;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace GraveDefensor.Shared.Services.Implementation
{
    public class DrawContext : IDrawContext
    {
        readonly SpriteBatch spriteBatch;
        public DrawContext(SpriteBatch spriteBatch)
        {
            this.spriteBatch = spriteBatch;
        }
        public void Draw(Texture2D texture, Vector2 position, Color color)
        {
            spriteBatch.Draw(texture, position, color);
        }
        public void Draw(Texture2D texture, Rectangle destinationRectangle, Rectangle? sourceRectangle, Color color,
            float rotation, Vector2 origin, SpriteEffects effects, float layerDepth)
        {
            spriteBatch.Draw(texture, destinationRectangle, sourceRectangle, color, rotation, origin, effects, layerDepth);
        }
        public void Draw(Texture2D texture, Vector2 position, Rectangle? sourceRectangle, Color color, 
            float rotation, Vector2 origin, Vector2 scale, SpriteEffects effects, float layerDepth)
        {
            spriteBatch.Draw(texture, position, sourceRectangle, color, rotation, origin, scale, effects, layerDepth);
        }

        public void DrawLine(float x1, float y1, float x2, float y2, Color color)
        {
            spriteBatch.DrawLine(x1, y1, x2, y2, color);
        }

        public void DrawLine(float x1, float y1, float x2, float y2, Color color, float thickness)
        {
            spriteBatch.DrawLine(x1, y1, x2, y2, color, thickness);
        }

        public void DrawLine(Vector2 point1, Vector2 point2, Color color)
        {
            spriteBatch.DrawLine(point1, point2, color);
        }

        public void DrawLine(Vector2 point1, Vector2 point2, Color color, float thickness)
        {
            spriteBatch.DrawLine(point1, point2, color, thickness);
        }

        public void DrawLine(Vector2 point, float length, float angle, Color color)
        {
            spriteBatch.DrawLine(point, length, angle, color);
        }

        public void DrawLine(Vector2 point, float length, float angle, Color color, float thickness)
        {
            spriteBatch.DrawLine(point, length, angle, color, thickness);
        }

        public void DrawRectangle(Rectangle rect, Color color)
        {
            spriteBatch.DrawRectangle(rect, color);
        }

        public void DrawRectangle(Rectangle rect, Color color, float thickness)
        {
            spriteBatch.DrawRectangle(rect, color, thickness);
        }

        public void DrawRectangle(Vector2 location, Vector2 size, Color color)
        {
            spriteBatch.DrawRectangle(location, size, color);
        }

        public void DrawRectangle(Vector2 location, Vector2 size, Color color, float thickness)
        {
            spriteBatch.DrawRectangle(location, size, color, thickness);
        }

        public void DrawString(SpriteFont spriteFont, string text, Vector2 position, Color color)
        {
            spriteBatch.DrawString(spriteFont, text, position, color);
        }

        public void DrawString(SpriteFont spriteFont, string text, Vector2 position, Color color, float rotation, Vector2 origin, float scale, SpriteEffects effects, float layerDepth)
        {
            spriteBatch.DrawString(spriteFont, text, position, color, rotation, origin, scale, effects, layerDepth);
        }

        public void DrawString(SpriteFont spriteFont, string text, Vector2 position, Color color, float rotation, Vector2 origin, Vector2 scale, SpriteEffects effects, float layerDepth)
        {
            spriteBatch.DrawString(spriteFont, text, position, color, rotation, origin, scale, effects, layerDepth);
        }

        public void DrawString(SpriteFont spriteFont, StringBuilder text, Vector2 position, Color color)
        {
            spriteBatch.DrawString(spriteFont, text, position, color);
        }

        public void DrawString(SpriteFont spriteFont, StringBuilder text, Vector2 position, Color color, float rotation, Vector2 origin, float scale, SpriteEffects effects, float layerDepth)
        {
            spriteBatch.DrawString(spriteFont, text, position, color, rotation, origin, scale, effects, layerDepth);
        }

        public void FillRectangle(Rectangle rect, Color color)
        {
            spriteBatch.FillRectangle(rect, color);

        }

        public void FillRectangle(Rectangle rect, Color color, float angle)
        {
            spriteBatch.FillRectangle(rect, color, angle);
        }

        public void FillRectangle(Vector2 location, Vector2 size, Color color)
        {
            spriteBatch.FillRectangle(location, size, color);
        }

        public void FillRectangle(Vector2 location, Vector2 size, Color color, float angle)
        {
            spriteBatch.FillRectangle(location, size, color, angle);
        }

        public void FillRectangle(float x, float y, float w, float h, Color color)
        {
            spriteBatch.FillRectangle(x, y, w, h, color);
        }

        public void FillRectangle(float x, float y, float w, float h, Color color, float angle)
        {
            spriteBatch.FillRectangle(x, y, w, h, color, angle);
        }
    }
}

using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using System.Text;

namespace GraveDefensor.Shared.Service.Abstract
{
    public interface IDrawContext
    {
        void Draw(Texture2D texture, Vector2 position, Color color);
        void Draw(Texture2D texture, Rectangle destinationRectangle, Rectangle? sourceRectangle, Color color,
            float rotation, Vector2 origin, SpriteEffects effects, float layerDepth);
        void Draw(Texture2D texture, Vector2 position, Rectangle? sourceRectangle, Color color,
            float rotation, Vector2 origin, Vector2 scale, SpriteEffects effects, float layerDepth);
        void DrawLine(float x1, float y1, float x2, float y2, Color color);
        void DrawLine(float x1, float y1, float x2, float y2, Color color, float thickness);
        void DrawLine(Vector2 point1, Vector2 point2, Color color);
        void DrawLine(Vector2 point1, Vector2 point2, Color color, float thickness);
        void DrawLine(Vector2 point, float length, float angle, Color color);
        void DrawLine(Vector2 point, float length, float angle, Color color, float thickness);
        void FillRectangle(Rectangle rect, Color color);
        void FillRectangle(Rectangle rect, Color color, float angle);
        void FillRectangle(Vector2 location, Vector2 size, Color color);
        void FillRectangle(Vector2 location, Vector2 size, Color color, float angle);
        void FillRectangle(float x, float y, float w, float h, Color color);
        void FillRectangle(float x, float y, float w, float h, Color color, float angle);
        void DrawRectangle(Rectangle rect, Color color);
        void DrawRectangle(Rectangle rect, Color color, float thickness);
        void DrawRectangle(Vector2 location, Vector2 size, Color color);
        void DrawRectangle(Vector2 location, Vector2 size, Color color, float thickness);
        void DrawString(SpriteFont spriteFont, string text, Vector2 position, Color color);
        void DrawString(SpriteFont spriteFont, string text, Vector2 position, Color color, float rotation, Vector2 origin, float scale, SpriteEffects effects, float layerDepth);
        void DrawString(SpriteFont spriteFont, string text, Vector2 position, Color color, float rotation, Vector2 origin, Vector2 scale, SpriteEffects effects, float layerDepth);
        void DrawString(SpriteFont spriteFont, StringBuilder text, Vector2 position, Color color);
        void DrawString(SpriteFont spriteFont, StringBuilder text, Vector2 position, Color color, float rotation, Vector2 origin, float scale, SpriteEffects effects, float layerDepth);
    }
}

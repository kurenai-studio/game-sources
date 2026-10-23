using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Pong
{
    class Sprite
    {
        protected Texture2D Texture;
       protected Vector2 Position;
        Color Color;
        Vector2 Scale;
        public Rectangle Hitbox
        {
            get
            {
                return new Rectangle((int)(Position.X), (int)(Position.Y), Texture.Width * (int)Scale.X, Texture.Height * (int)Scale.Y);
            }
        }
        public Sprite(Texture2D texture, Vector2 position, Color color, Vector2 scale)
        {
            this.Texture = texture;
            this.Position = position;
            this.Color = color;
            this.Scale = scale;
        }


        public void Draw(SpriteBatch spriteBatch)
        {
            spriteBatch.Draw(Texture, Position, null, Color, 0, Vector2.Zero, Scale, SpriteEffects.None, 0);
        }
    }
}

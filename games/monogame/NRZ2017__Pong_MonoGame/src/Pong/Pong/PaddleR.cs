using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Pong
{
    class PaddleR : Sprite
    {
        float Velocity;
        public Rectangle Hitbox;
        public PaddleR(Texture2D texture) : base(texture, new Vector2(300,100), Color.Black, new Vector2(0.5f, 0.5f))
        {
            Velocity = 3;
            Hitbox = new Rectangle(300, 100, Texture.Width, Texture.Height);
        }
        public void UpdateMovement(KeyboardState key, GraphicsDevice graphics)
        {
            //Position.Y += VelocityY;

            if (key.IsKeyDown(Keys.Down))
            {
                Position.Y += Velocity;
            }
            else if (key.IsKeyDown(Keys.Up))
            {
                Position.Y -= Velocity;
            }
            if (Position.Y <= 0)
            {
                Position.Y += Velocity;
            }
            else if (Position.Y + 123 >= graphics.Viewport.Height)
            {
                Position.Y -= Velocity;
            }
            Hitbox = new Rectangle((int)(Position.X), (int)(Position.Y), Texture.Width, Texture.Height);

        }
    }
}

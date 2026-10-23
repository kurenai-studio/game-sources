using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;

namespace Pong
{
    class Paddle : Sprite
    {
        float Velocity;
   
        public Paddle(Vector2 pos, Texture2D texture) : base(texture, pos, Color.Black, new Vector2(0.5f, 0.5f))
        {
            Velocity = 3;
            
        }

        public void UpdateCollision(GraphicsDevice graphics)
        {
            if (Position.Y <= 0)
            {
                Position.Y += Velocity;
            }
            else if (Position.Y + 123 >= graphics.Viewport.Height)
            {
                Position.Y -= Velocity;
            }
           
        }

        public void MoveUp()
        {
            Position.Y -= Velocity;
        }

        public void MoveDown()
        {
            Position.Y += Velocity;
        }
    }
}

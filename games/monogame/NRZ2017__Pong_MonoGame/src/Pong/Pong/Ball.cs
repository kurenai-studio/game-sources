using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Pong
{
    class Ball : Sprite
    {
        
       public float VelocityX;
       public float VelocityY;

        public Ball(Texture2D texture2D) : base (texture2D, new Vector2(100, 100), Color.White, new Vector2(0.2f, 0.2f))
        {
            VelocityX = 4;
            VelocityY = 4;

            
        }

        public void UpdateMovement(GraphicsDevice graphics)
        {
            

            if(Position.X > graphics.Viewport.Width - 50)
            {
                VelocityX = -Math.Abs(VelocityX);
            }
            if(Position.X < 0)
            {
                VelocityX = Math.Abs(VelocityX);
            }
            if(Position.Y > graphics.Viewport.Height - 50)
            {
                VelocityY = -Math.Abs(VelocityY);
            }
            if(Position.Y < 0)
            {
                VelocityY = Math.Abs(VelocityY);
            } 

            Position.X += VelocityX;
            Position.Y += VelocityY;
            

        }


    }
}


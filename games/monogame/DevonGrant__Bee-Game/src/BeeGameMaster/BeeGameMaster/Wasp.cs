using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BeeGameMaster
{
    class Wasp : Enemy, Dies, Shoots
    {
        private Projectile stinger;
        private int width;
        private double shootTime;
        public int Width { get => width; set => width = value; }
        public Projectile Stinger { get => stinger; set => stinger = value; }
        public Wasp(Texture2D newTexture, int x, int y, int wWidth, int wHeight, Color newColor, int life) : base(newTexture, x, y, wHeight, newColor, life)
        {
            width = wWidth;
            stinger = null;
            Speed = 5;
        }

        public override void Update(GameTime gameTime, List<Projectile> list)
        {
            this.X += Speed;
            shootTime += gameTime.ElapsedGameTime.TotalMilliseconds;

            //Makes sure that if enemy falls off screen it dies
            if ((this.X <= 0) || (this.X >= (width - Rect.Width)))
            {
                Speed = -Speed;
            }
            if (Health <= 0)
            {
                IsDead = true;
            }
            if (shootTime >= 2000)
            {
                shootTime = 0;
                stinger = new Projectile(Texture, X, Y + Rect.Height, 5, 1);
                list.Add(stinger);
            }


        }
    }
}

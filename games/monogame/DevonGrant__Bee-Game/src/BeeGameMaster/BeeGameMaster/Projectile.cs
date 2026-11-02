using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BeeGameMaster
{
    public class Projectile : Dies
    {
        Texture2D texture;
        Rectangle rect;
        int damage = 1;
        int speed = 5;
        private bool isDead = false;
        //if the added bullets are special, then they will be shot using 
        //a special projectile update method that shoots bullets diagonally
        private bool special = false;

        public Texture2D Texture { get => texture; set => texture = value; }
        public Rectangle Rect { get => rect; set => rect = value; }
        public int Speed { get => speed; set => speed = value; }
        public int X { get => rect.X; set => rect.X = value; }
        public int Y { get => rect.Y; set => rect.Y = value; }
        public bool IsDead { get => isDead; set => isDead = value; }
        public int Health { get => damage; set => damage = value; }
        public bool Special { get => special; set => special = value; }

        public Projectile(Texture2D newTexture, int x, int y, int s, int life)
        {
            if (Game1.player.SlowTime == false)
            {
                speed = s;
                texture = newTexture;
                damage = life;
                //fix for projectile
                if (speed > 0)
                {
                    rect = new Rectangle(x, y, texture.Width / 4, texture.Height / 4);
                }
                else
                {
                    rect = new Rectangle(x, y, texture.Width, texture.Height);
                }
            }
            else
            {
                speed = s / 2;
                texture = newTexture;
                damage = life;
                //fix for projectile size
                if (speed > 0)
                {
                    rect = new Rectangle(x, y, texture.Width / 4, texture.Height / 4);
                }
                else
                {
                    rect = new Rectangle(x, y, texture.Width, texture.Height);
                }
            }

        }

        public void Update(Shoots source, GameTime gameTime)
        {
            Y += speed;
        }
        
        public void UpdateSpecialLeft(Shoots source, GameTime gameTime)
        {
            Y += speed;
            X += speed;
        }
        public void UpdateSpecialRight(Shoots source, GameTime gameTime)
        {
            Y += speed;
            X -= speed;
        }

        public void CheckCollision(Dies a)
        {
            if (a != null)
            {
                if (rect.Intersects(a.Rect))
                {
                    //If a projectile hits another projectile, they should set each other's isDead to true
                    if (a is Projectile)
                    {
                        a.IsDead = true;
                        this.isDead = true;
                    }
                    //If a projectile hits a Hive, it hurts the Hive
                    else if (a is Hive)
                    {
                        a.Health -= damage;
                        this.isDead = true;
                    }
                    //If a Projectile hits an Enemy, it hurts the Enemy
                    else if (a is Enemy)
                    {
                        a.Health -= damage;
                        this.isDead = true;
                    }
                    //do something to deactivate a
                }
                //return this.isDead;
            }

        }
    }
}

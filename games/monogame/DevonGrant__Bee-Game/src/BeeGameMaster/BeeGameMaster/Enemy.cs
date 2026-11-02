using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BeeGameMaster
{
    class Enemy : Dies
    {
        Texture2D texture;
        Rectangle rect;
        int health = 1;
        private bool isDead = false;
        int speed = 2;

        private int height;
        private Color color;
        Random rng = new Random();

        public Texture2D Texture { get => texture; set => texture = value; }
        public Rectangle Rect { get => rect; set => rect = value; }
        public int Health { get => health; set => health = value; }
        public int X { get => rect.X; set => rect.X = value; }
        public int Y { get => rect.Y; set => rect.Y = value; }
        public bool IsDead { get => isDead; set => isDead = value; }
        public int Height { get => height; set => height = value; }
        public Color Color { get => color; set => color = value; }
        public int Speed { get => speed; set => speed = value; }
        public Random Rng { get => rng; set => rng = value; }


        //Constructor that determines what size and position and texture the enemy will spawn with
        public Enemy(Texture2D newTexture, int x, int y, int wHeight, Color newColor, int life)
        {
            texture = newTexture;
            //Spawns enemy randomly along the x value
            rect = new Rectangle(x, y, texture.Width / 4, texture.Height / 4);
            health = life;
            height = wHeight;
            color = newColor;
        }

        public virtual void Update(GameTime gameTime, List<Projectile> list)
        {
            if (Game1.player.SlowTime == false)
            {
                Y += speed;
            }
            else
            {
                Y += speed / 2;
            }

            //Makes sure that if enemy falls off screen it dies
            if (Y > height - rect.Height)
            {
                this.isDead = true;
            }
            if (health <= 0)
            {
                isDead = true;
            }
        }

        public void CheckCollision(Dies a)
        {
            if (a != null)
            {
                if (rect.Intersects(a.Rect))
                {
                    //If an Enemy hits a Hive, it hurts the Hive
                    if (a is Hive)
                    {
                        a.Health -= health;
                        this.isDead = true;
                    }
                    //If a Projectile hits an Enemy, it hurts the Enemy
                    else if (a is Projectile)
                    {
                        a.IsDead = true;
                        this.Health--;
                    }
                    //do something to deactivate a
                }
                //return this.isDead;
            }
        }
    }
}

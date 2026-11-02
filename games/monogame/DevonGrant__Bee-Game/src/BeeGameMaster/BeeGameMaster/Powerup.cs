using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Timers;


namespace BeeGameMaster
{
    enum Type { bullet, health, time }
    class Powerup
    {
        Texture2D texture;
        Rectangle rect;
        int speed = 5;
        private bool active = true;
        Type powerupType;
        private System.Timers.Timer aTimer;


        public Texture2D Texture { get => texture; set => texture = value; }
        public Rectangle Rect { get => rect; set => rect = value; }
        public int Speed { get => speed; set => speed = value; }
        public int X { get => rect.X; set => rect.X = value; }
        public int Y { get => rect.Y; set => rect.Y = value; }
        public bool Active { get => active; set => active = value; }
        public Type PowerupType { get => powerupType; set => powerupType = value; }


        public Powerup(Type thisType, Texture2D newTexture, int x, int s)
        {
            powerupType = thisType;
            texture = newTexture;
            rect = new Rectangle(x, 0, texture.Width / 5, texture.Height / 5);
            speed = s;
        }

        public void Update(GameTime gameTime)
        {
            //moves downward
            if (active == true)
            {
                Y += speed;

            }

        }


        //takes the player as well as hive that it is increasing health of as param
        public void CheckCollision(Player a, Hive b)
        {
            //check collision with player only
            if (a != null && active == true)
            {
                if (rect.Intersects(a.Rect))
                {
                    //behaves differently depending on powerup type
                    if (powerupType == Type.bullet)
                    {

                        a.SpecialShots = true;

                    }

                    //increase health of hive
                    if (powerupType == Type.health)
                    {
                        b.Health = b.Health + 1;


                    }

                    //Slow Time
                    if (PowerupType == Type.time)
                    {
                        a.SlowTime = true;
                        aTimer = new System.Timers.Timer(5000);
                        aTimer.Elapsed += OnTimedEvent;
                        aTimer.AutoReset = true;
                        aTimer.Enabled = true;
                    }
                    active = false;
                }

            }
        }

        private void OnTimedEvent(Object source, ElapsedEventArgs e)
        {
            Game1.player.SlowTime = false;
        }
    }
}

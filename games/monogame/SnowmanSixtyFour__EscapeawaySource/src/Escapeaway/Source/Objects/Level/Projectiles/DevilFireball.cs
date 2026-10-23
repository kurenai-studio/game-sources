using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace Escapeaway.Source.Objects.Level.Projectiles
{
    internal class DevilFireball
    {
        // Sprite
        private Character bullet;
        private Point
            startLocation = new Point(0, 0),

            size = new Point(8, 8),
            sheetSize = new Point(16, 8);

        // Properties
        public bool hit = false;
        public bool
            hurts = false, // Can Hurt Player
            moving = true, // If Bullet can Move
            parry = false, gone = false; // Parried by Player
        private bool
            movingUp = false; // Move Up (For Created Animation)

        private int pixelsToMove = 2;

        /// <summary>
        /// Creates a projectile for the player to dodge. Made with the room 100 boss in mind.
        /// </summary>
        /// <param name="startLocation">The starting location of the projectile.</param>
        /// <param name="hurts">Whether the projectile should hurt the player on contact.</param>
        /// <param name="movingUp">If the projectile should be moving up or left after creation. (True = Up, False = Left)</param>
        public DevilFireball(Point startLocation, bool hurts = false, bool movingUp = false)
        {
            // Set Variables
            this.hurts = hurts;
            this.movingUp = movingUp;
            this.startLocation = startLocation;

            // Set Character
            bullet = new Character(null, startLocation, sheetSize, size, Color.White);

            // Set Texture
            if (!hurts)
            {
                if (movingUp)
                {
                    bullet.SetSprite(Global.newFireballParry);
                }
                else
                {
                    bullet.SetSprite(Global.fireballParry);
                }
            }
            else
            {
                if (movingUp)
                {
                    bullet.SetSprite(Global.newFireball);
                }
                else
                {
                    bullet.SetSprite(Global.fireball);
                }
            }

            // Set Animation
            bullet.CreateAnimation("default", 0, 1);
        }

        public void Update(GameTime gameTime)
        {
            bullet.Update(gameTime);

            // Animate
            bullet.PlayAnimation("default");

            // Movement
            if (moving)
            {
                // Up
                if (movingUp)
                {
                    if (bullet.Y > -sheetSize.Y)
                    {
                        bullet.X += pixelsToMove;
                        bullet.Y -= pixelsToMove;
                    }
                }
                // Left
                else
                {
                    if (bullet.X > -sheetSize.X) bullet.X -= pixelsToMove;
                }
            }

            // Parry
            if (parry)
            {
                bullet.X += (pixelsToMove * 2);
                bullet.Y -= pixelsToMove;
            }

            // Disappear
            if (gone)
            {
                parry = false;
                moving = false;

                bullet.X = Global.resWidth;
            }
        }

        public void Draw(SpriteBatch spriteBatch)
        {
            bullet.Draw(spriteBatch);
        }

        public Character sprite => this.bullet;
    }
}

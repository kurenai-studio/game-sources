using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace Escapeaway.Source.Objects.Level.Boss
{
    internal class FollowerBoss : Boss
    {
        public Character sprite;
        private int currentScreen = 0;

        private Point
            startingPosition = new Point(0, 0),

            size = new Point(80, 64),
            sheetSize = new Point(480, 64);

        private int pixelsToMove = 2;

        public FollowerBoss() : base()
        {
            sprite = new Character(Global.devil, startingPosition, sheetSize, size, Color.White);

            sprite.CreateAnimation("default", 0, 0);
            sprite.CreateAnimation("hurt", 1, 1);
            sprite.CreateAnimation("staring", 2, 2);
            sprite.CreateAnimation("shocked", 3, 3);
            sprite.CreateAnimation("attack", 4, 5);
        }

        /// <summary>
        /// Resets the follower back to its state when endless mode first begins.
        /// </summary>
        public override void Reset()
        {
            base.Reset();

            // Reset Position
            sprite.SetLocation(startingPosition);
        }

        /// <summary>
        /// Moves the follower back a room. Useful for when the player reaches the end of a room.
        /// </summary>
        public void MovePositionBack()
        {
            // If Not Already Behind a Room
            if (sprite.X >= -size.X - 120)
            {
                // Move Follower Behind a Room
                sprite.X -= Global.resWidth;
            }
        }

        public void Update(GameTime gameTime, Player player, int currentScreen)
        {
            // Set Screen Variable
            this.currentScreen = currentScreen;

            // Move Follower
            if (this.currentScreen != 0)
            {
                sprite.Update(gameTime);

                // Move Towards Player

                if (player.X > sprite.X) sprite.X += pixelsToMove;
                else if (player.X < sprite.X) sprite.X -= pixelsToMove;

                if (player.Y > sprite.Y) sprite.Y += pixelsToMove;
                else if (player.Y < sprite.Y) sprite.Y -= pixelsToMove;
            }
        }

        public void Draw(SpriteBatch spriteBatch)
        {
            // Draw Follower
            if (currentScreen != 0) sprite.Draw(spriteBatch);
        }
    }
}

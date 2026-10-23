using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace Escapeaway.Source.Objects.Level.Background.Cutscene
{
    internal class FirstRoomDevil
    {
        private Character devil;
        private bool visible = true;
        private Point
            size = new Point(80, 64),
            sheetSize = new Point(80, 64);

        // Movement
        private bool movingUp = false;
        private float
            yVelocity = 0,
            gravity = 0.2f, maxMovementSpeed = 1.5f,

            maxUpHeight, maxDownHeight;

        public FirstRoomDevil(Point location)
        {
            devil = new Character(Global.devil, location, sheetSize, size, Color.White);

            devil.CreateAnimation("default", 0, 0);
            devil.CreateAnimation("hurt", 1, 1);
            devil.CreateAnimation("staring", 2, 2);
            devil.CreateAnimation("shocked", 3, 3);
            devil.CreateAnimation("attack", 4, 5);

            maxUpHeight = (location.Y - 2);
            maxDownHeight = (location.Y + 2);
        }

        public void Hide()
        {
            visible = false;
        }

        public void Show()
        {
            visible = true;
        }

        /// <summary>
        /// Reset the first room's Devil back to his original state.
        /// </summary>
        public void Reset()
        {
            devil.PlayAnimation("staring");
        }

        public void Update(GameTime gameTime, Player player)
        {
            devil.Update(gameTime);

            // Flying Movement

            if (devil.Y < maxUpHeight) movingUp = false;
            if (devil.Y > maxDownHeight) movingUp = true;

            devil.Y += Convert.ToInt32(yVelocity);

            if (movingUp)
            {
                if (yVelocity > -maxMovementSpeed) yVelocity -= gravity;
                else yVelocity = -maxMovementSpeed;
            }
            if (!movingUp)
            {
                if (yVelocity < maxMovementSpeed) yVelocity += gravity;
                else yVelocity = maxMovementSpeed;
            }

            // Animations

            if (player.moving)
            {
                devil.PlayAnimation("shocked");
            }
            else
            {
                devil.PlayAnimation("staring");
            }
        }

        public void Draw(SpriteBatch spriteBatch)
        {
            if (visible) devil.Draw(spriteBatch);
        }
    }
}

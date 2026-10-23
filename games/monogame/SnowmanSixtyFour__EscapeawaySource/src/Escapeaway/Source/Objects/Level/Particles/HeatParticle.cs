using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Escapeaway.Source.Graphics;

namespace Escapeaway.Source.Objects.Level.Particles
{
    internal class HeatParticle
    {
        private StaticSprite heat;
        private Point size = new Point(8, 8);

        private int pixelsToMove = 1;

        private Random random;
        private bool movingLeft;

        private float
            timeExisted = 0f,
            timeToExist = 700f;
        private bool draw = true;

        public HeatParticle(Point location)
        {
            // Set Variables
            random = new Random();

            // Set Sprite
            heat = new StaticSprite(Global.heatParticle, new Rectangle(location, size), CustomColor.LightOrange);

            // Set Direction to Move
            int moveLeft = random.Next(0, 2);
            if (moveLeft == 0) movingLeft = true;
            else movingLeft = false;
        }

        public void Update(GameTime gameTime)
        {
            // Move Up
            heat.SetDestRect(new Rectangle(heat.GetDestRect().X, heat.GetDestRect().Y - pixelsToMove, size.X, size.Y));

            // Move Left / Right
            if (movingLeft) heat.SetDestRect(new Rectangle(heat.GetDestRect().X - pixelsToMove, heat.GetDestRect().Y, size.X, size.Y));
            else heat.SetDestRect(new Rectangle(heat.GetDestRect().X + pixelsToMove, heat.GetDestRect().Y, size.X, size.Y));

            // Update Timer
            timeExisted += gameTime.ElapsedGameTime.Milliseconds;

            // Change Direction
            if (timeExisted > timeToExist / 2 && timeExisted < timeToExist / 2 + 10) movingLeft = !movingLeft;
            if (timeExisted > timeToExist / 4 && timeExisted < timeToExist / 4 + 10) movingLeft = !movingLeft;

            // When Time Limit to Exist Reached
            if (timeExisted > timeToExist) draw = false;
        }

        public void Draw(SpriteBatch spriteBatch)
        {
            if (draw) heat.Draw(spriteBatch);
        }
    }
}

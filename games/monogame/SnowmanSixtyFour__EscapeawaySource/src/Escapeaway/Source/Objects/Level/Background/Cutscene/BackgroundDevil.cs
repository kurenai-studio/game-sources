using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace Escapeaway.Source.Objects.Level.Background.Cutscene
{
    internal class BackgroundDevil
    {
        private Character devil;
        private Point
            size = new Point(80, 64),
            sheetSize = new Point(480, 64);
        private int
            yOffset = 25,
            pixelsToMove = 4,

            startingPosition;

        public BackgroundDevil()
        {
            // Set Starting Position
            startingPosition = 0 - size.X;

            // Set Sprite
            devil = new Character(Global.devil, new Point(startingPosition, Global.resHeight / 2 - size.Y / 2 - yOffset), sheetSize, size, CustomColor.Black * 0.5f);

            // Create Animations
            devil.CreateAnimation("default", 0, 0);
            devil.CreateAnimation("hurt", 1, 1);
            devil.CreateAnimation("staring", 2, 2);
            devil.CreateAnimation("shocked", 3, 3);
            devil.CreateAnimation("attack", 4, 5);
        }

        public void Reset()
        {
            // Set Position
            devil.X = startingPosition;
        }

        public void Update(GameTime gameTime)
        {
            devil.Update(gameTime);

            // Move Devil Across Background
            if (devil.X < Global.resWidth) devil.X += pixelsToMove;
        }

        public void Draw(SpriteBatch spriteBatch)
        {
            devil.Draw(spriteBatch);
        }
    }
}

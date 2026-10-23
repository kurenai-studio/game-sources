using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Escapeaway.Source.Graphics;

namespace Escapeaway.Source.Objects.Level.Background.Cutscene
{
    internal class LevelEndOverlay
    {
        private StaticSprite sprite;

        private Point startingPosition = new Point((Global.resWidth + 160), 0);

        public bool move = false;
        private int pixelsToMove = 1;

        private int centerOfScreen;
        public bool isCentered = false;

        public LevelEndOverlay()
        {
            // Set Sprite
            sprite = new StaticSprite(Global.endOverlay, new Rectangle(startingPosition.X, startingPosition.Y, 280, 224), CustomColor.White);

            // Set Destination
            centerOfScreen = (Global.resWidth - sprite.GetWidth());
        }

        public void Reset()
        {
            // Reset Events
            this.isCentered = false;
            this.move = false;

            // Reset Sprite
            this.sprite.SetX(startingPosition.X);
        }

        public void Update(GameTime gameTime)
        {
            // Move Sprite
            if (move)
            {
                // If Sprite is Not Centered (Middle of Screen)
                if (sprite.GetX() > centerOfScreen)
                {
                    // Move Sprite to Center
                    sprite.SetX(sprite.GetX() - pixelsToMove);
                }
                else
                {
                    // End Move Event
                    move = false;

                    // Center Sprite
                    sprite.SetX(centerOfScreen);

                    isCentered = true;
                }
            }
        }

        public void Draw(SpriteBatch spriteBatch)
        {
            // Draw Sprite
            sprite.Draw(spriteBatch);
        }
    }
}

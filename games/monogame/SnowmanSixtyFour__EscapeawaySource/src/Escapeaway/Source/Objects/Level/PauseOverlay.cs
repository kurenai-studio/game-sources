using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Escapeaway.Source.Graphics;

namespace Escapeaway.Source.Objects.Level
{
    internal class PauseOverlay
    {
        private Text pause, options;
        private string optionsText =
            """
            Press [ESCAPE] to Resume

                  [X] to Quit
            """;
        private StaticSprite background;

        public PauseOverlay()
        {
            // Initialize Pause Menu

            pause = new Text(Global.defaultFont, "PAUSED", new Vector2(Global.resWidth / 2 - 20, Global.resHeight / 2 - 30), CustomColor.White, 1f, true);
            options = new Text(Global.defaultFont, optionsText, new Vector2(42, Global.resHeight / 2), CustomColor.White, 1f, true);

            background = new StaticSprite(null, new Rectangle(0, Global.resHeight / 2 - 38, Global.resWidth, Global.resHeight / 3), CustomColor.Black);
        }

        public void Draw(SpriteBatch spriteBatch)
        {
            // Draw Pause Menu
            if (Global.paused)
            {
                background.Draw(spriteBatch);

                pause.Draw(spriteBatch);
                options.Draw(spriteBatch);
            }
        }
    }
}

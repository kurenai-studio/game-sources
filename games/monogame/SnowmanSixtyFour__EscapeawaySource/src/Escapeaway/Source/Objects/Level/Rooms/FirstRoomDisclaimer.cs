using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Escapeaway.Source.Graphics;
using Escapeaway.Source.Objects.Level;

namespace Escapeaway.Source.Objects.Level.Rooms
{
    internal class FirstRoomDisclaimer
    {
        // Text Variables

        private Text controls, start;

        private string controlsString =
            """
                [Z] - Jump
            [Left Arrow] - Slow Down
            [Down Arrow] - Slide
            """,
            startString =
            """
            Press [Right Arrow] to
               start the game!
            """;

        private float
            flickerTimer = 0f,
            framesUntilFlicker = 260f;
        private bool startVisible = true;

        // Public Variables

        public bool visible = true;

        public FirstRoomDisclaimer()
        {
            controls = new Text(Global.defaultFont, controlsString, new Vector2(Global.resWidth / 2 - 90, Global.resHeight / 4 - 26), CustomColor.White, 1.0f, false);
            start = new Text(Global.defaultFont, startString, new Vector2(Global.resWidth / 2 - 84, Global.resHeight / 4 + 10), CustomColor.White, 1.0f, false);
        }

        public void Update(GameTime gameTime, Player player)
        {
            // Only Update while Visible (ermm, optimization!)
            if (visible)
            {
                // Flicker Start Text
                flickerTimer += gameTime.ElapsedGameTime.Milliseconds;

                if (flickerTimer > framesUntilFlicker)
                {
                    // Flicker Text
                    startVisible = !startVisible;

                    // Reset Timer
                    flickerTimer = 0f;
                }
            }

            // Hide when Player Moves
            if (player.moving) visible = false;
        }

        public void Draw(SpriteBatch spriteBatch)
        {
            if (visible)
            {
                controls.Draw(spriteBatch);
                if (startVisible) start.Draw(spriteBatch);
            }
        }
    }
}

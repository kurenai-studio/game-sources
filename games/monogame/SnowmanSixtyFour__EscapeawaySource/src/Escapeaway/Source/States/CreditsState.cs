using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using Escapeaway;
using Escapeaway.Source.Graphics;

namespace Escapeaway.Source.States
{
    internal class CreditsState : State
    {
        private String credits =
            """
            Snowman64           Programmer
                           Particle Sprites

            ShawSure          Sprite Artist
                         Character Designer

            River347                 Music


             Copyrighted assets have been
             removed for the sake of the
                  GitHub repository.

                  Music used is by
                    Kevin Macleod
            """;

        private Text
            header,
            creditsText,
            goBack;

        public CreditsState()
        {
            header = new Text(Global.defaultFont, "Credits", new Vector2((Global.resWidth / 2) - 20, 6), Color.White, 1.0f, false);
            creditsText = new Text(Global.defaultFont, credits, new Vector2(6, 24), Color.White, 1.0f, false);
            goBack = new Text(Global.defaultFont, "Press [Z] or [X] to Exit", new Vector2((Global.resWidth / 2) - 120, 204), Color.White, 1.0f, false);
        }

        public override void OnUpdate(GameTime gameTime, Main main)
        {
            // Switch to Title
            if (KeyPress(Keys.Z) || KeyPress(Keys.X) || KeyPress(Keys.Enter) || KeyPress(Keys.Escape)
                || ButtonPress(Buttons.A) || ButtonPress(Buttons.B) || ButtonPress(Buttons.Start))
            {
                SwitchState(main.title);
            }
        }

        public override void OnDraw(SpriteBatch spriteBatch)
        {
            graphicsDevice.Clear(CustomColor.Black);

            header.Draw(spriteBatch);
            creditsText.Draw(spriteBatch);
            goBack.Draw(spriteBatch);
        }
    }
}

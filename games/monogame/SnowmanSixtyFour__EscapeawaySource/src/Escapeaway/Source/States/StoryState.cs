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
    internal class StoryState : State
    {
        private String story =
            """
            You (yes, YOU) have been dragged

            into the underdepths after being

            falsely accused of sins you

            never committed. Now, you must
            
            run for your life - as the devil

            is convinced you must stay...

            Make it back to the real world!
            """;

        private Text
            header,
            giantWallOfText,
            goBack;

        public StoryState()
        {
            header = new Text(Global.defaultFont, "Story", new Vector2((Global.resWidth / 2) - 20, 6), Color.White, 1.0f, false);
            giantWallOfText = new Text(Global.defaultFont, story, new Vector2(6, 24), Color.White, 1.0f, false);
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
            giantWallOfText.Draw(spriteBatch);
            goBack.Draw(spriteBatch);
        }
    }
}

using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using Escapeaway.Source.Objects.Intro;

namespace Escapeaway.Source.States
{
    internal class IntroState : State
    {
        private Snowman64 snowman64;

        public IntroState()
        {
            snowman64 = new Snowman64();
        }

        public override void OnUpdate(GameTime gameTime, Main main)
        {
            snowman64.Update(gameTime);

            // Skip Sequence
            if (KeyPress(Keys.Z) || KeyPress(Keys.X) || KeyPress(Keys.Escape) || KeyPress(Keys.Enter)
                || ButtonPress(Buttons.A) || ButtonPress(Buttons.B) || ButtonPress(Buttons.Start))
            {
                SwitchState(main.title);
            }

            // Go to Title When Sequence Over
            if (snowman64.gone) SwitchState(main.title);
        }

        public override void OnDraw(SpriteBatch spriteBatch)
        {
            graphicsDevice.Clear(CustomColor.Black);

            snowman64.Draw(spriteBatch);
        }
    }
}

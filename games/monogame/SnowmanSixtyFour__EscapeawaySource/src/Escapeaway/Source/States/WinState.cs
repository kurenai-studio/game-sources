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
using Escapeaway.Source.Graphics.GUI;

namespace Escapeaway.Source.States
{
    internal class WinState : State
    {
        private Text header, newHighscore;

        private ButtonList buttons;
        private int buttonX = 20, buttonY = 174;

        private int score;

        public WinState()
        {
            // Set Text
            header = new Text(Global.defaultFont, "YOU WIN!", new Vector2((Global.resWidth / 2) - 30, 16), CustomColor.White, 1.0f, false);
            newHighscore = new Text(Global.defaultFont, "", new Vector2(44, 32), CustomColor.Yellow, 1.0f, false);

            // Set Buttons
            buttons = new ButtonList();
            buttons.Add("Play Again", new Vector2(buttonX, buttonY - 20), CustomColor.White);
            buttons.Add("Endless Mode", new Vector2(buttonX, buttonY), CustomColor.White);
            buttons.Add("Quit to Title", new Vector2(buttonX, buttonY + 20), CustomColor.White);

            // Save Highscore
            WriteToOptions();
        }

        public void SetScore(int newScore)
        {
            this.score = newScore;

            Global.highscore = this.score;
            WriteToOptions(newScore: this.score);
        }

        public override void OnUpdate(GameTime gameTime, Main main)
        {
            // Update Objects
            if (newHighscore.getText() == "") newHighscore.setText("YOUR HISCORE IS " + Global.highscore + "!");
            buttons.Update(gameTime, main);

            // Button Selected

            // Go to Level
            if (buttons.ButtonSelected(0, this))
            {
                Reset();

                // Reset Level
                main.level.GoBackToFirstRoom();
                SwitchState(main.level);
            }

            // Endless Mode
            else if (buttons.ButtonSelected(1, this))
            {
                Reset();

                // Reset Level
                main.endless = true;
                main.level.GoBackToFirstRoom();
                SwitchState(main.level);
            }

            // Go to Title
            else if (buttons.ButtonSelected(2, this))
            {
                Reset();

                SwitchState(main.title);
            }
        }

        private void Reset()
        {
            // Reset Objects
            newHighscore.setText("");

            // Reset Selected Button
            buttons.SetSelectedButton(0);
        }

        public override void OnDraw(SpriteBatch spriteBatch)
        {
            graphicsDevice.Clear(CustomColor.Black);

            header.Draw(spriteBatch);
            newHighscore.Draw(spriteBatch);

            buttons.Draw(spriteBatch);
        }
    }
}

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
using Escapeaway.Source.Objects.Level;

namespace Escapeaway.Source.States
{
    internal class GameOverState : State
    {
        // Variables
        private int score = 0;
        private bool endless = false;

        public bool saveNewScore = false;

        // Text
        private Text header, newEndlessHighscore;

        // Buttons
        private ButtonList buttons;
        private int buttonX = 20, buttonY = 174;

        public GameOverState()
        {
            // Text
            header = new Text(Global.defaultFont, "GAME OVER", new Vector2((Global.resWidth / 2) - 32, 16), CustomColor.White, 1.0f, false);
            newEndlessHighscore = new Text(Global.defaultFont, "", new Vector2(8, 32), CustomColor.Yellow, 1.0f, false);

            // Buttons
            buttons = new ButtonList();
            buttons.Add("Play Again", new Vector2(buttonX, buttonY), CustomColor.White);
            buttons.Add("Quit to Title", new Vector2(buttonX, buttonY + 20), CustomColor.White);
        }

        public override void OnUpdate(GameTime gameTime, Main main)
        {
            // Set Properties
            this.endless = main.endless;

            // Update Objects
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

            // Go to Title
            else if (buttons.ButtonSelected(1, this))
            {
                Reset();

                SwitchState(main.title);
            }
        }

        public void SetEndlessScore(int newScore)
        {
            this.score = newScore;

            // Update Text

            if (this.score > Global.endlessHighscore)
            {
                // Announce New Score to Player
                newEndlessHighscore.setText("YOUR ENDLESS HISCORE IS " + this.score + "!");

                // Update Global Variable for Score
                Global.endlessHighscore = this.score;
                WriteToOptions(newEndlessScore: this.score);
            }
            else
            {
                newEndlessHighscore.setText("AIM FOR A NEW HISCORE!");
            }
        }

        private void Reset()
        {
            // Reset Properties
            this.endless = false;

            // Reset Objects
            newEndlessHighscore.setText("");

            // Reset Selected Button
            buttons.SetSelectedButton(0);
        }

        public override void OnDraw(SpriteBatch spriteBatch)
        {
            graphicsDevice.Clear(CustomColor.Black);

            header.Draw(spriteBatch);
            if (this.endless) newEndlessHighscore.Draw(spriteBatch);

            buttons.Draw(spriteBatch);
        }
    }
}

using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using Escapeaway.Source.Graphics;
using Escapeaway.Source.States;

namespace Escapeaway.Source.Graphics.GUI
{
    internal class ButtonList
    {
        private List<Text> buttons = new List<Text>();

        private int
            buttonSelected = 0,
            maxButtons = 0;

        public ButtonList()
        {
        }

        public void Update(GameTime gameTime, State state)
        {
            if (state.KeyPress(Keys.Up)
                || state.ButtonPress(Buttons.LeftThumbstickUp) || state.ButtonPress(Buttons.DPadUp))
            {
                if (buttonSelected != 0) buttonSelected--;
                else buttonSelected = Convert.ToByte(maxButtons - 1);
            }
            if (state.KeyPress(Keys.Down)
                || state.ButtonPress(Buttons.LeftThumbstickDown) || state.ButtonPress(Buttons.DPadDown))
            {
                if (buttonSelected < Convert.ToByte(maxButtons - 1)) buttonSelected++;
                else buttonSelected = 0;
            }
            if (state.KeyPress(Keys.Up) || state.KeyPress(Keys.Down)
                || state.ButtonPress(Buttons.LeftThumbstickDown) || state.ButtonPress(Buttons.DPadDown)
                || state.ButtonPress(Buttons.LeftThumbstickUp) || state.ButtonPress(Buttons.DPadUp))
            {
                // Set Color of Selected Button (don't if value is past limit)
                if (buttonSelected < maxButtons) SelectButton(buttonSelected);

                // Select SFX
                SFX.select.Play();
            }
        }

        public void Add(string text, Vector2 position, Color color)
        {
            Add(text, position, color, true);
        }

        public void Add(string text, Vector2 position, Color color, bool centered)
        {
            buttons.Add(new Text(Global.defaultFont, text, position, color, 1.0f, centered));

            maxButtons = buttons.Count;

            SelectButton(buttonSelected);
        }

        public Text GetButton(int button)
        {
            return buttons[button];
        }

        public Text GetSelectedButton()
        {
            return buttons[buttonSelected];
        }

        public void SetSelectedButton(int button)
        {
            this.buttonSelected = button;
            SelectButton(button);
        }

        private void SelectButton(int button)
        {
            // Reset all Button Colors
            foreach (Text otherButtons in buttons) otherButtons.setColor(CustomColor.White);

            // Update Chosen Button to be Selected Color
            buttons[button].setColor(CustomColor.LightOrange);
        }

        public bool ButtonSelected(int button, State state)
        {
            if (state.KeyPress(Keys.Z) || state.KeyPress(Keys.Enter)
                || state.ButtonPress(Buttons.A) || state.ButtonPress(Buttons.Start))
            {
                if (buttonSelected == button)
                {
                    SFX.intro.Play();

                    return true;
                }
                else return false;
            }
            else return false;
        }

        public void Draw(SpriteBatch spriteBatch)
        {
            // Draw List
            foreach (var button in buttons) button.Draw(spriteBatch);
        }
    }
}

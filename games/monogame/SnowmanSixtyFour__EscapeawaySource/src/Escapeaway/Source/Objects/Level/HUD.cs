using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Escapeaway.Source.Graphics;
using Escapeaway.Source.States;

namespace Escapeaway.Source.Objects.Level
{
    internal class HUD
    {
        private Text
            lives, score, room,
            endless;
        private int y = 6;
        private bool endlessMode = false;

        public HUD()
        {
            lives = new Text(Global.defaultFont, "", new Vector2(8, y), CustomColor.White, 1.0f, false);
            score = new Text(Global.defaultFont, "", new Vector2(78, y), CustomColor.White, 1.0f, false);
            room = new Text(Global.defaultFont, "", new Vector2(Global.resWidth - 64, y), CustomColor.White, 1.0f, false);

            endless = new Text(Global.defaultFont, "ENDLESS", new Vector2(room.getPosition().X, room.getPosition().Y + 12), CustomColor.White, 1.0f, false);
        }

        public void Update(GameTime gameTime, Player player, int currentScreen, Main main)
        {
            this.endlessMode = main.endless;
            lives.setText("LIVES " + player.lives);
            if (player.score <= Global.maxScore) score.setText("SCORE " + player.score);
            if (player.score < Global.maxScore) score.setColor(CustomColor.White);
            else score.setColor(CustomColor.Yellow);
            if (!this.endlessMode)
            {
                // Cap Rooms at 100
                if (currentScreen < 100) room.setText("ROOM " + (currentScreen + 1));
                else room.setText("ROOM 100");
            }
            else
            {
                // Cap Rooms at 999
                if (currentScreen < 999) room.setText("ROOM " + (currentScreen + 1));
                else room.setText("ROOM 999");
            }
        }

        public void Draw(SpriteBatch spriteBatch)
        {
            lives.Draw(spriteBatch);
            score.Draw(spriteBatch);
            room.Draw(spriteBatch);
            if (this.endlessMode) endless.Draw(spriteBatch);
        }
    }
}

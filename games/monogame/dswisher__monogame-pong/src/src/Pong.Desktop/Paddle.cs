// Copyright (c) Doug Swisher. All Rights Reserved.
// Licensed under the MIT License. See LICENSE in the project root for license information.

using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Input;

namespace Pong.Desktop
{
    public class Paddle
    {
        private const int PaddleWidth = 40;
        private const int PaddleHeight = 200;

        private Rectangle rect;
        private float moveSpeed = 500f;
        private bool isSecondPlayer;


        public Paddle(bool isSecondPlayer)
        {
            this.isSecondPlayer = isSecondPlayer;

            var x = isSecondPlayer ? Globals.Width - PaddleWidth : 0;
            rect = new Rectangle(x, 140, PaddleWidth, PaddleHeight);
        }


        public Rectangle Rect => rect;


        public void Update(GameTime gameTime)
        {
            var kstate = Keyboard.GetState();

            if ((isSecondPlayer ? kstate.IsKeyDown(Keys.Up) : kstate.IsKeyDown(Keys.W)) && rect.Y > 0)
            {
                rect.Y -= (int)(moveSpeed * (float)gameTime.ElapsedGameTime.TotalSeconds);
            }

            if ((isSecondPlayer ? kstate.IsKeyDown(Keys.Down) : kstate.IsKeyDown(Keys.S)) && rect.Y < Globals.Height - rect.Height)
            {
                rect.Y += (int)(moveSpeed * (float)gameTime.ElapsedGameTime.TotalSeconds);
            }
        }


        public void Draw()
        {
            Globals.SpriteBatch.Draw(Globals.Pixel, rect, Color.White);
        }
    }
}

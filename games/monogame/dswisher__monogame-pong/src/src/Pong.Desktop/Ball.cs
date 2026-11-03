// Copyright (c) Doug Swisher. All Rights Reserved.
// Licensed under the MIT License. See LICENSE in the project root for license information.

using Microsoft.Xna.Framework;

namespace Pong.Desktop
{
    public class Ball
    {
        private Rectangle rect;
        private int right = 1;
        private int top = 1;
        private int moveSpeed = 200;

        public Ball()
        {
            rect = new Rectangle(Globals.Width / 2 - 20, Globals.Height / 2 - 20, 40, 40);
        }


        public void Update(GameTime gameTime, Paddle player1, Paddle player2)
        {
            // Move the ball
            var deltaSpeed = (int)(moveSpeed * (float)gameTime.ElapsedGameTime.TotalSeconds);
            rect.X += right * deltaSpeed;
            rect.Y += top * deltaSpeed;

            // Check for collision with player1
            if (player1.Rect.Right > rect.Left && rect.Top > player1.Rect.Top && rect.Bottom < player1.Rect.Bottom)
            {
                right = 1;
            }

            // Check for collision with player2
            if (player2.Rect.Left < rect.Right && rect.Top > player2.Rect.Top && rect.Bottom < player2.Rect.Bottom)
            {
                right = -1;
            }

            // Check for collisions with boundary
            if (rect.Y < 0)
            {
                top *= -1;
            }

            if (rect.Y > Globals.Height - rect.Height)
            {
                top *= -1;
            }

            // Check for player1 miss
            if(rect.X < 0)
            {
                Globals.Player2Score += 1;
                ResetGame();
            }

            // Check for player2 miss
            if (rect.X > Globals.Width - rect.Width)
            {
                Globals.Player1Score += 1;
                ResetGame();
            }
        }


        public void Draw()
        {
            Globals.SpriteBatch.Draw(Globals.Pixel, rect, Color.White);
        }


        private void ResetGame()
        {
            rect.X = Globals.Width / 2 - 20;
            rect.Y = Globals.Height / 2 - 20;
        }
    }
}

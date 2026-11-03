// Copyright (c) Doug Swisher. All Rights Reserved.
// Licensed under the MIT License. See LICENSE in the project root for license information.

using Microsoft.Xna.Framework.Graphics;

namespace Pong.Desktop
{
    public static class Globals
    {
        public static int Width { get; set; } = 640;
        public static int Height { get; set; } = 480;

        public static SpriteBatch SpriteBatch { get; set; }

        public static Texture2D Pixel { get; set; }

        public static int Player1Score { get; set; }
        public static int Player2Score { get; set; }
    }
}

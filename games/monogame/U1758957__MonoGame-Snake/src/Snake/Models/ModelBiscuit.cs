using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;
using System;
using System.Collections.Generic;
using System.Text;

namespace Snake.Models
{
    class ModelBiscuit
    {

        private readonly Texture2D _biscuitTexture;
        private Vector2 _position;

        private double _inverseWidth;
        private double _inverseHeight;

        public ModelBiscuit(ContentManager content, GraphicsDeviceManager graphics)
        {

            _biscuitTexture = content.Load<Texture2D>("biscuit");

            _position = new Vector2(
                graphics.PreferredBackBufferWidth * 0.25f,
                graphics.PreferredBackBufferHeight * 0.25f);

            _inverseWidth = 1.0d / _biscuitTexture.Width;
            _inverseHeight = 1.0d / _biscuitTexture.Height;

            RectBiscuit = new Rectangle((int) _position.X, (int) _position.Y, _biscuitTexture.Width, _biscuitTexture.Height);

            Score = 0;

        }

        public Rectangle RectBiscuit { get; private set; }

        public bool Collided { private get; set; }

        public int Score { get; private set; }

        public void Update(GameTime gameTime, GraphicsDeviceManager graphics)
        {
            if (Collided)
            {
                Random rnd = new Random();

                _position.X = rnd.Next(0, graphics.PreferredBackBufferWidth - _biscuitTexture.Width);
                _position.Y = rnd.Next(0, graphics.PreferredBackBufferHeight - _biscuitTexture.Height);

                double roundX = Math.Round(_position.X * _inverseWidth) * _biscuitTexture.Width;
                double roundY = Math.Round(_position.Y * _inverseHeight) * _biscuitTexture.Height;

                _position.X = (int) roundX;
                _position.Y = (int) roundY;

                RectBiscuit = new Rectangle((int) _position.X, (int) _position.Y, _biscuitTexture.Width, _biscuitTexture.Height);

                Score += 10;

            }
        }

        public void Draw(SpriteBatch spriteBatch)
        {
            spriteBatch.Draw(_biscuitTexture, _position, Color.White);
        }

    }
}

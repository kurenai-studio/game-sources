using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Snake.Models
{
    class ModelDifficultyButton
    {

        private MouseState _currentMouseState;
        private MouseState _previousMouseState;

        private Texture2D _buttonTexture;

        private Vector2 _position;
        private Rectangle _buttonRectangle;

        public bool Clicked { get; private set; }
 
        public int Difficulty { get; private set; }

        public ModelDifficultyButton(ContentManager content, GraphicsDeviceManager graphics, int myDifficulty)
        {

            switch (myDifficulty)
            {
                case 0:
                    _buttonTexture = content.Load<Texture2D>("Difficulty_Hard");
                    _position = new Vector2((graphics.PreferredBackBufferWidth * 0.75f) - _buttonTexture.Width / 2, (graphics.PreferredBackBufferHeight / 2) - _buttonTexture.Height);
                    break;
                case 1:
                    _buttonTexture = content.Load<Texture2D>("Difficulty_Medium");
                    _position = new Vector2((graphics.PreferredBackBufferWidth * 0.5f) - _buttonTexture.Width / 2, (graphics.PreferredBackBufferHeight / 2) - _buttonTexture.Height);
                    break;
                case 2:
                    _buttonTexture = content.Load<Texture2D>("Difficulty_Easy");
                    _position = new Vector2((graphics.PreferredBackBufferWidth * 0.25f) - _buttonTexture.Width / 2, (graphics.PreferredBackBufferHeight / 2) - _buttonTexture.Height);
                    break;
            }

            _buttonRectangle = new Rectangle((int) _position.X, (int) _position.Y, _buttonTexture.Width, _buttonTexture.Height);

            Difficulty = myDifficulty;

            _currentMouseState = Mouse.GetState();
            Clicked = false;

        }

        public void Update()
        {

            _previousMouseState = _currentMouseState;
            _currentMouseState = Mouse.GetState();

            Rectangle mouseRect = new Rectangle(_currentMouseState.X, _currentMouseState.Y, 1, 1);

            if (mouseRect.Intersects(_buttonRectangle))
            {
                if (_currentMouseState.LeftButton == ButtonState.Released && _previousMouseState.LeftButton == ButtonState.Pressed)
                {
                    Clicked = true;
                }
            }

        }

        public void Draw(SpriteBatch spriteBatch)
        {
            spriteBatch.Draw(_buttonTexture, _buttonRectangle, Color.White);
        }

    }
}

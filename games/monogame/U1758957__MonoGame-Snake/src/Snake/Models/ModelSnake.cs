using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using System;
using System.Collections.Generic;
using System.Text;
using System.Timers;

namespace Snake.Models
{
    class ModelSnake
    {

        private readonly Texture2D[] _snakeTextures = new Texture2D[2];
        private Vector2 _headPosition;

        private float Speed;

        private int _direction; // 0, 1, 2, 3 = Left, Right, Up, Down

        private Rectangle[] _snakeBody;
        private int _snakeBodyIndex;

        private Timer _staggerTimer;
        private bool _stagger;

        public ModelSnake(ContentManager content, GraphicsDeviceManager graphics, ref int difficulty)
        {

            _snakeTextures[0] = content.Load<Texture2D>("snake_head");
            _snakeTextures[1] = content.Load<Texture2D>("snake_body");

            Speed = _snakeTextures[0].Width;

            _direction = 0;

            _snakeBody = new Rectangle[graphics.PreferredBackBufferWidth * graphics.PreferredBackBufferHeight];

            _headPosition = new Vector2(
                graphics.PreferredBackBufferWidth * 0.5f,
                graphics.PreferredBackBufferHeight * 0.5f);

            _snakeBody[0] = new Rectangle((int) _headPosition.X, (int) _headPosition.Y, _snakeTextures[0].Width, _snakeTextures[0].Height);
            _snakeBodyIndex = 1;

            Collided = false;
            Dead = false;

            _staggerTimer = new Timer();
            _staggerTimer.Elapsed += new ElapsedEventHandler(OnStagger);
            
            switch (difficulty)
            {
                case 0:
                    _staggerTimer.Interval = 50;
                    break;
                case 1:
                    _staggerTimer.Interval = 100;
                    break;
                case 2:
                    _staggerTimer.Interval = 150;
                    break;
            }

            _stagger = false;
            _staggerTimer.Enabled = true;

        }

        public bool Collided { get; private set; }

        public Rectangle RectBiscuit { private get; set; }

        public bool Dead { get; private set; }

        private void OnStagger(object source, ElapsedEventArgs e)
        {
            _stagger ^= true;
        }

        public void Update(GameTime gameTime, GraphicsDeviceManager graphics)
        {

            KeyboardState keyState = Keyboard.GetState();

            if (keyState.IsKeyDown(Keys.Left)) _direction = 0;
            else if (keyState.IsKeyDown(Keys.Right)) _direction = 1;
            else if (keyState.IsKeyDown(Keys.Up)) _direction = 2;
            else if (keyState.IsKeyDown(Keys.Down)) _direction = 3;

            if (!_stagger)
            {

                int tmpX = _snakeBody[0].X;
                int tmpY = _snakeBody[0].Y;

                switch (_direction)
                {

                    case 0:
                        _snakeBody[0].Offset(-Speed + -_snakeBody[0].Width * (float) gameTime.ElapsedGameTime.TotalSeconds, 0);
                        break;
                    case 1:
                        _snakeBody[0].Offset(Speed + _snakeBody[0].Width * (float) gameTime.ElapsedGameTime.TotalSeconds, 0);
                        break;
                    case 2:
                        _snakeBody[0].Offset(0, -Speed + -_snakeBody[0].Height * (float) gameTime.ElapsedGameTime.TotalSeconds);
                        break;
                    case 3:
                        _snakeBody[0].Offset(0, Speed + _snakeBody[0].Height * (float) gameTime.ElapsedGameTime.TotalSeconds);
                        break;
                }

                if (_snakeBody[0].X <= -_snakeTextures[0].Width || _snakeBody[0].X >= graphics.PreferredBackBufferWidth || _snakeBody[0].Y <= -_snakeTextures[0].Height || _snakeBody[0].Y >= graphics.PreferredBackBufferHeight) Dead = true;

                if (_snakeBody[0].Intersects(RectBiscuit))
                {
                    _snakeBody[_snakeBodyIndex] = new Rectangle(0, 0, _snakeTextures[1].Width, _snakeTextures[1].Height);
                    _snakeBodyIndex++;

                    Collided = true;
                }

                for (int i = 1; i < _snakeBodyIndex; i++)
                {
                    int segTmpX = _snakeBody[i].X;
                    int segTmpY = _snakeBody[i].Y;
                    _snakeBody[i].X = tmpX;
                    _snakeBody[i].Y = tmpY;
                    tmpX = segTmpX;
                    tmpY = segTmpY;
                }


                for (int i = 1; i < _snakeBodyIndex; i++)
                {
                    if (_snakeBody[0].Intersects(_snakeBody[i])) Dead = true;
                }

                _stagger ^= true;

            }

        }

        public void Draw(SpriteBatch spriteBatch)
        {

            Collided = false;

            Vector2 currentPos;

            for (int i = 0; i < _snakeBodyIndex; i++)
            {
                currentPos = new Vector2(_snakeBody[i].X, _snakeBody[i].Y);
                spriteBatch.Draw(i > 0 ? _snakeTextures[1] : _snakeTextures[0], currentPos, Color.White);
            }

        }

    }
}

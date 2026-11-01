using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using Snake.Controllers;
using Snake.Models;

namespace Snake
{
    public class GameLoop : Game
    {
        private GraphicsDeviceManager _graphics;
        private SpriteBatch _spriteBatch;

        private ControllerSnake _controllerSnake;
        private ControllerBiscuit _controllerBiscuit;
        private readonly ModelDifficultyButton[] _difficultyButtons = new ModelDifficultyButton[3];

        private SpriteFont _font;
        private SpriteFont _fontDead;
        private const string _DeadText = "Dead :(";
        private int _deadTextWidth;
        private int _deadTextHeight;

        private double _timeCounter = 0.0d;
        private bool _showFPS = true;
        private double _frameRate;
        private double _avgFrameRate;
        private readonly double[] _frameRates = new double[32];
        private int _frameRatesIndex;

        private int _score;
        private bool _dead = false;
        private bool _menu = true;
        private int _difficulty = 1; // 0, 1, 2 = Hard, Medium, Easy

        public GameLoop()
        {
            _graphics = new GraphicsDeviceManager(this);
            Content.RootDirectory = "Content";
            IsMouseVisible = true;

            _graphics.SynchronizeWithVerticalRetrace = false;
            IsFixedTimeStep = false;

        }

        protected override void Initialize()
        {

            _graphics.PreferredBackBufferWidth = 1024;
            _graphics.PreferredBackBufferHeight = 1024;
            _graphics.ApplyChanges();

            _difficultyButtons[0] = new ModelDifficultyButton(Content, _graphics, 0);
            _difficultyButtons[1] = new ModelDifficultyButton(Content, _graphics, 1);
            _difficultyButtons[2] = new ModelDifficultyButton(Content, _graphics, 2);

            base.Initialize();

        }

        protected override void LoadContent()
        {

            _font = Content.Load<SpriteFont>("Font");
            _fontDead = Content.Load<SpriteFont>("Font_Death");

            _deadTextWidth = (int)_fontDead.MeasureString(_DeadText).X / 2;
            _deadTextHeight = (int)_fontDead.MeasureString(_DeadText).Y / 2;

            _spriteBatch = new SpriteBatch(GraphicsDevice);

        }

        protected override void Update(GameTime gameTime)
        {
            if (GamePad.GetState(PlayerIndex.One).Buttons.Back == ButtonState.Pressed || Keyboard.GetState().IsKeyDown(Keys.Escape))
            {
                Content.Unload();
                Content.Dispose();
                Exit();
            } 
            else if (Keyboard.GetState().IsKeyDown(Keys.F))
            {
                _showFPS ^= true;
            } 
 
            if (!_dead && !_menu)
            {

                _controllerSnake.Update(gameTime, _graphics);
                _controllerBiscuit.Update(gameTime, _graphics);

                _score = _controllerBiscuit.Score;
                _dead = _controllerSnake.Dead;

            }

            if (_menu)
            {
                foreach (ModelDifficultyButton difficultyButton in _difficultyButtons)
                {
                    difficultyButton.Update();

                    if (difficultyButton.Clicked)
                    {
                        _difficulty = difficultyButton.Difficulty;
                        _controllerSnake = new ControllerSnake(Content, _graphics, ref _difficulty);
                        _controllerBiscuit = new ControllerBiscuit(Content, _graphics);
                        _controllerSnake.setControllerBiscuit(ref _controllerBiscuit);
                        _controllerBiscuit.setControllerSnake(ref _controllerSnake);
                        _menu = false;
                    }

                }
            }

            base.Update(gameTime);
        }

        protected override void Draw(GameTime gameTime)
        {
            GraphicsDevice.Clear(Color.Black);

            _spriteBatch.Begin();

            if (_showFPS)
            {

                _timeCounter += gameTime.ElapsedGameTime.TotalMilliseconds;

                if (_timeCounter >= 100)

                {
                    _frameRate = 1 / (float) gameTime.ElapsedGameTime.TotalSeconds;
                    _frameRates[_frameRatesIndex++] = _frameRate;

                    if (_frameRatesIndex == _frameRates.Length)
                    {
                        _frameRatesIndex = 0;

                        double frameRateSum = 0.0d;

                        foreach (double frameRate in _frameRates) frameRateSum += frameRate;

                        _avgFrameRate = frameRateSum / _frameRates.Length;
                    }

                    _timeCounter = 0.0d;
                }

                _spriteBatch.DrawString(_font, $"FPS: {_frameRate}", new Vector2(0, 0), Color.White);
                _spriteBatch.DrawString(_font, $"Avg FPS: {_avgFrameRate}", new Vector2(0, _font.LineSpacing), Color.White);

            }

            if (!_menu)

            {

                _spriteBatch.DrawString(!_dead ? _font : _fontDead, $"Score: {_score}", new Vector2(0, _graphics.PreferredBackBufferWidth - (!_dead ? _font.LineSpacing : _fontDead.LineSpacing)), Color.Gold);

                if (!_dead)
                {
                    _controllerSnake.Draw(_spriteBatch);
                    _controllerBiscuit.Draw(_spriteBatch);
                }
                else
                {
                    _spriteBatch.DrawString(_fontDead, _DeadText, new Vector2((_graphics.PreferredBackBufferWidth / 2) - _deadTextWidth, (_graphics.PreferredBackBufferHeight / 2) - _deadTextHeight), Color.Red);
                }

            } 
            else
            {
                _spriteBatch.DrawString(_fontDead, "Difficulty", new Vector2((_graphics.PreferredBackBufferWidth / 2) - _deadTextWidth, (_graphics.PreferredBackBufferHeight / 4) - _deadTextHeight), Color.White);
                foreach (ModelDifficultyButton difficultyButton in _difficultyButtons) difficultyButton.Draw(_spriteBatch);
            }

            _spriteBatch.End();

            base.Draw(gameTime);
        }
    }
}

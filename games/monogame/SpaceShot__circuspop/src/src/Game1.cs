using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Audio;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using Microsoft.Xna.Framework.Media;
using System;
using System.Collections.Generic;

namespace CircusPop
{
    public class Game1 : Game
    {
        private GraphicsDeviceManager _graphics;
        private SpriteBatch _spriteBatch;

        private Sprite _clown;
        private Texture2D clownTexture;
        private Texture2D trampolineTexture;
        private Vector2 trampolinePosition;

        private bool _isGameStarted = false;

        private SpriteFont _textFont;
        private SoundEffect bounce;
        private SoundEffect pop;

        Texture2D balloonTexture;
        List<Balloon> balloons = new List<Balloon>();

        Animation clownAnimation;
        Texture2D clownSpriteSheet;

        Animation backgroundAnimation;
        Texture2D backgroundTexture;

        Rectangle displaySize;

        Song caliope;

        int score = 0;

        KeyboardState previousKeyboardState;

        public Game1()
        {
            _graphics = new GraphicsDeviceManager(this);

            _graphics.PreferredBackBufferWidth = 800;
            _graphics.PreferredBackBufferHeight = 600;

            Content.RootDirectory = "Content";
            IsMouseVisible = true;
        }

        protected override void Initialize()
        {
            _clown = new(new Vector2(100.0f, 120.0f), Vector2.Zero);

            this.Services.AddService(typeof(IMovingObject), _clown);
            this.Components.Add(new VelocityDisplay(this));

            SetupBalloons();

            previousKeyboardState = Keyboard.GetState();

            base.Initialize();
        }

        protected override void LoadContent()
        {
            _spriteBatch = new SpriteBatch(GraphicsDevice);

            clownTexture = Content.Load<Texture2D>("clown");
            _clown.Texture = clownTexture;

            trampolineTexture = Content.Load<Texture2D>("trampoline");

            _textFont = Content.Load<SpriteFont>("font");

            bounce = Content.Load<SoundEffect>("bounce");

            balloonTexture = Content.Load<Texture2D>("balloon");

            pop = Content.Load<SoundEffect>("pop");

            backgroundTexture = Content.Load<Texture2D>("background");
            backgroundAnimation = new Animation(backgroundTexture, 500, 640, 480);
            displaySize = new Rectangle(0, 0, GraphicsDevice.Viewport.Width, GraphicsDevice.Viewport.Height);

            clownSpriteSheet = Content.Load<Texture2D>("clownSpriteSheet");
            clownAnimation = new Animation(clownSpriteSheet, 200, 58, 64);

            caliope = Content.Load<Song>("caliope");
        }

        protected override void Update(GameTime gameTime)
        {
            KeyboardState keyboardState = Keyboard.GetState();

            // Exit the game when Back is pressed on GamePad or Escape is pressed on Keyboard
            if (GamePad.GetState(PlayerIndex.One).Buttons.Back == ButtonState.Pressed || Keyboard.GetState().IsKeyDown(Keys.Escape))
            {
                Exit();
            }

            // Skip updating if the game has not "started"
            if (GamePad.GetState(PlayerIndex.One).Buttons.Start == ButtonState.Pressed || Keyboard.GetState().IsKeyDown(Keys.Space))
            {
                _isGameStarted = true;

                if (MediaPlayer.State != MediaState.Playing)
                {
                    MediaPlayer.Play(caliope);
                }
            }

            if (!_isGameStarted)
            {
                trampolinePosition = new Vector2(100.0f, (float)(GraphicsDevice.Viewport.Height - trampolineTexture.Height));

                base.Update(gameTime);
                previousKeyboardState = keyboardState;
                return;
            }

            // detect toggling music playback
            if (keyboardState.IsKeyDown(Keys.M) && previousKeyboardState.IsKeyUp(Keys.M))
            {
                if (MediaPlayer.State == MediaState.Playing)
                {
                    MediaPlayer.Pause();
                }
                else
                {
                    MediaPlayer.Play(caliope);
                    MediaPlayer.IsRepeating = true;
                }
            }

            // use keyboard to move trampoline
            KeyboardState keyState = Keyboard.GetState();
            if (keyState.IsKeyDown(Keys.Left))
            {
                trampolinePosition.X -= 10.0f;
            }
            if (keyState.IsKeyDown(Keys.Right))
            {
                trampolinePosition.X += 10.0f;
            }
            
            //use gamepad to move trampoline
            GamePadState padState = GamePad.GetState(PlayerIndex.One);
            trampolinePosition.X += padState.ThumbSticks.Left.X * 15.0f;
            // Clamp trampoline position to screen bounds
            trampolinePosition.X = MathHelper.Clamp(trampolinePosition.X, 0, GraphicsDevice.Viewport.Width - trampolineTexture.Width);

            //_clownPosition += _clownVelocity * (float)gameTime.ElapsedGameTime.TotalSeconds;
            _clown.Position += _clown.Velocity * (float)gameTime.ElapsedGameTime.TotalSeconds;

            int MaxX = GraphicsDevice.Viewport.Width - _clown.Width;
            int MinX = 0;
            int MaxY = GraphicsDevice.Viewport.Height - _clown.Height;
            int MinY = 0;

            if (_clown.Position.X > MaxX)
            {
                // We've hit the right side, reverse to create a bounce
                _clown.Velocity.X *= -1;
                _clown.Position.X = MaxX;
            }

            else if (_clown.Position.X < MinX)
            {
                // We've hit the left side, reverse to create a bounce
                _clown.Velocity.X *= -1;
                _clown.Position.X = MinX;
            }

            if (_clown.Position.Y > MaxY)
            {
                // the _clown has hit the ground and would "lose"

                // for testing, force a "soft" 90 degree bounce
                float newY = 750 * (float)Math.Sin(MathHelper.ToRadians(90.0f));
                float newX = 750 * (float)Math.Cos(MathHelper.ToRadians(90.0f));
                _clown.Velocity.X = newX;
                _clown.Velocity.Y = newY;

                _clown.Velocity.Y *= -1;
                _clown.Position.Y = MaxY;
            }

            // Check for collision with trampoline
            Rectangle trampolineRectangle = new Rectangle((int)trampolinePosition.X, (int)trampolinePosition.Y,
                trampolineTexture.Width, trampolineTexture.Height);

            Rectangle clownRectangle = new Rectangle((int)_clown.Position.X, (int)_clown.Position.Y,
                _clown.Width, _clown.Height);


            if (trampolineRectangle.Intersects(clownRectangle))
            {
                // bounce the clown here

                // calculate bounce based on distance from clown center to trampoline center
                int angle = trampolineRectangle.Center.X - clownRectangle.Center.X + 90;

                float factor = 980.0f;
                if (angle < 45 || angle > 135)
                {
                    factor = 750.0f;
                }

                float newY = factor * (float)Math.Sin(MathHelper.ToRadians((float)(angle)));
                float newX = factor * (float)Math.Cos(MathHelper.ToRadians((float)(angle)));
                _clown.Velocity.X = newX;
                _clown.Velocity.Y = newY;

                _clown.Velocity.Y *= -1;
                _clown.Position.Y = trampolinePosition.Y - _clown.Height;

                bounce.Play();
            }

            // update balloons
            for (int i = 0; i < balloons.Count; i++)
            {
                if (clownRectangle.Intersects(balloons[i].BoundingBox))
                {
                    score += balloons[i].Color * 10 + 10;
                    balloons.RemoveAt(i);
                    _clown.Velocity.X *= -1;
                    _clown.Velocity.Y *= -1;

                    _clown.Velocity.X += new Random().Next(-15, 15);

                    pop.Play();

                    // you can only kill off one balloon per frame
                    // this is to prevent problems with our List index
                    // after calling RemoveAt()
                    break;
                }
            }

            Balloon.UpdateAnimation(gameTime);

            backgroundAnimation.Update(gameTime);
            clownAnimation.Update(gameTime);

            _clown.Velocity.Y += 16.0f;

            base.Update(gameTime);
            previousKeyboardState = keyboardState;
        }

        protected override void Draw(GameTime gameTime)
        {
            GraphicsDevice.Clear(Color.CornflowerBlue);

            _spriteBatch.Begin();

            _spriteBatch.Draw(backgroundTexture, displaySize, backgroundAnimation.CurrentFrame, Color.White);
            //_spriteBatch.Draw(_clown.Texture, _clown.Position, Color.White);
            _spriteBatch.Draw(clownSpriteSheet, _clown.Position, clownAnimation.CurrentFrame, Color.White);
            _spriteBatch.Draw(trampolineTexture, trampolinePosition, Color.White);

            foreach (Balloon b in balloons)
            {
                _spriteBatch.Draw(balloonTexture,
                    b.Position,
                    new Rectangle(Balloon.State * 32, b.Color * 32, 32, 32),
                    Color.White);
            }

            if (!_isGameStarted)
            {
                _spriteBatch.DrawString(_textFont, "Press <Space> To Start", new Vector2(80.0f, 225.0f), Color.DarkBlue);
            }

            _spriteBatch.DrawString(_textFont, "Score: " + score.ToString(), new Vector2(550.0f, 180.0f), Color.DarkBlue);

            _spriteBatch.End();

            base.Draw(gameTime);
        }

        private void SetupBalloons()
        {
            balloons.Clear();

            int rows = 3;
            int columns = 21;
            int columnSpacing = 36;
            int rowSpacing = 40;
            int leftMargin = 20;

            for (int i = 0; i < rows; i++)
            {
                for (int j = 0; j < columns; j++)
                {
                    balloons.Add(new Balloon { Color = i, Position = new Vector2((j * columnSpacing) + leftMargin, i * rowSpacing) });
                }
            }

            //balloonTexture = Content.Load<Texture2D>("balloon");

            //int rows = 3;
            //int balloonsPerRow = 8;
            //int horizontalSpacing = GraphicsDevice.Viewport.Width / (balloonsPerRow + 1);
            //int verticalSpacing = 60;
            //int startY = 50;

            //for (int row = 0; row < rows; row++)
            //{
            //    for (int col = 0; col < balloonsPerRow; col++)
            //    {
            //        float x = (col + 1) * horizontalSpacing;
            //        float y = startY + (row * verticalSpacing);
            //        balloons.Add(new Balloon(new Vector2(x, y)));
            //    }
            //}
        }
    }
}

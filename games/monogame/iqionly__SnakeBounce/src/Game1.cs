using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using MonoGameLibrary;
using MonoGameLibrary.Graphics;
using MonoGameLibrary.Input;
using System;
using System.Collections.Generic;

namespace SnakeBounce
{
    public class Game1 : Core
    {
        private AnimatedSprite _snake;
        private AnimatedSprite _apple;

        // Tracks the position of the slime.
        private Vector2 _snakePosition;

        // Tracks the position of the apple.
        private Vector2 _applePosition;

        private Vector2 _appleVelocity;

        // Speed multiplier when moving.
        private const float MOVEMENT_SPEED = 5.0f;

        // Use a queue directly for input buffering
        private Queue<Vector2> _inputBuffer;
        private const int MAX_BUFFER_SIZE = 2;

        private Vector2 _lastDirection = Vector2.UnitY;

        public Game1() : base("SnakeBounce", 1280, 720, false)
        {

        }

        protected override void Initialize()
        {
            base.Initialize();

            _inputBuffer = new Queue<Vector2>(MAX_BUFFER_SIZE);

            _snakePosition = new Vector2(
                GraphicsDevice.PresentationParameters.BackBufferWidth * 0.5f,
                GraphicsDevice.PresentationParameters.BackBufferHeight * 0.5f);

            _applePosition = new Vector2(_snake.Width + 10, 0);

            // Assign the initial random velocity to the bat.
            AssignRandomBatVelocity();
        }

        protected override void LoadContent()
        {
            // Create the texture atlas from the XML configuration file
            TextureAtlas atlas = TextureAtlas.FromFile(Content, "images/atlas-definition.xml");

            _snake = atlas.CreateAnimatedSprite("snake-animation");

            _apple = atlas.CreateAnimatedSprite("apple-animation");
        }

        protected override void Update(GameTime gameTime)
        {
            if (GamePad.GetState(PlayerIndex.One).Buttons.Back == ButtonState.Pressed || Keyboard.GetState().IsKeyDown(Keys.Escape))
                Exit();

            // Update apple animations
            _apple.Update(gameTime);

            // Update snake animations
            _snake.Update(gameTime);

            // Create a bounding rectangle for the screen.
            Rectangle screenBounds = new Rectangle(
                0,
                0,
                GraphicsDevice.PresentationParameters.BackBufferWidth,
                GraphicsDevice.PresentationParameters.BackBufferHeight
            );

            // Creating a bounding circle for the slime
            Circle slimeBounds = new Circle(
                (int)(_snakePosition.X + (_snake.Width * 0.5f)),
                (int)(_snakePosition.Y + (_snake.Height * 0.5f)),
                (int)(_snake.Width * 0.5f)
            );

            // Use distance based checks to determine if the slime is within the
            // bounds of the game screen, and if it is outside that screen edge,
            // move it back inside.
            if (slimeBounds.Left < screenBounds.Left)
            {
                _snakePosition.X = screenBounds.Left;
            }
            else if (slimeBounds.Right > screenBounds.Right)
            {
                _snakePosition.X = screenBounds.Right - _snake.Width;
            }

            if (slimeBounds.Top < screenBounds.Top)
            {
                _snakePosition.Y = screenBounds.Top;
            }
            else if (slimeBounds.Bottom > screenBounds.Bottom)
            {
                _snakePosition.Y = screenBounds.Bottom - _snake.Height;
            }

            // Calculate the new position of the bat based on the velocity.
            Vector2 newBatPosition = _applePosition + _appleVelocity;

            // Create a bounding circle for the bat.
            Circle batBounds = new Circle(
                (int)(newBatPosition.X + (_apple.Width * 0.5f)),
                (int)(newBatPosition.Y + (_apple.Height * 0.5f)),
                (int)(_apple.Width * 0.5f)
            );

            Vector2 normal = Vector2.Zero;

            // Use distance based checks to determine if the bat is within the
            // bounds of the game screen, and if it is outside that screen edge,
            // reflect it about the screen edge normal.
            if (batBounds.Left < screenBounds.Left)
            {
                normal.X = Vector2.UnitX.X;
                newBatPosition.X = screenBounds.Left;
            }
            else if (batBounds.Right > screenBounds.Right)
            {
                normal.X = -Vector2.UnitX.X;
                newBatPosition.X = screenBounds.Right - _apple.Width;
            }

            if (batBounds.Top < screenBounds.Top)
            {
                normal.Y = Vector2.UnitY.Y;
                newBatPosition.Y = screenBounds.Top;
            }
            else if (batBounds.Bottom > screenBounds.Bottom)
            {
                normal.Y = -Vector2.UnitY.Y;
                newBatPosition.Y = screenBounds.Bottom - _apple.Height;
            }

            // If the normal is anything but Vector2.Zero, this means the bat had
            // moved outside the screen edge so we should reflect it about the
            // normal.
            if (normal != Vector2.Zero)
            {
                normal.Normalize();
                _appleVelocity = Vector2.Reflect(_appleVelocity, normal);
            }

            _applePosition = newBatPosition;

            if (slimeBounds.Intersects(batBounds))
            {
                // Divide the width  and height of the screen into equal columns and
                // rows based on the width and height of the bat.
                int totalColumns = GraphicsDevice.PresentationParameters.BackBufferWidth / (int)_apple.Width;
                int totalRows = GraphicsDevice.PresentationParameters.BackBufferHeight / (int)_apple.Height;

                // Choose a random row and column based on the total number of each
                int column = Random.Shared.Next(0, totalColumns);
                int row = Random.Shared.Next(0, totalRows);

                // Change the bat position by setting the x and y values equal to
                // the column and row multiplied by the width and height.
                _applePosition = new Vector2(column * _apple.Width, row * _apple.Height);

                // Assign a new random velocity to the bat
                AssignRandomBatVelocity();
            }

            CheckKeyboardInputBuffer();

            base.Update(gameTime);
        }

        private void CheckKeyboardInput()
        {
            float speed = MOVEMENT_SPEED;
            if (Input.Keyboard.IsKeyDown(Keys.Space))
            {
                speed *= 1.5f;
            }

            if (Input.Keyboard.IsKeyDown(Keys.W) || Input.Keyboard.IsKeyDown(Keys.Up))
            {
                _snakePosition.Y -= speed;
            }
            else if (Input.Keyboard.IsKeyDown(Keys.D) || Input.Keyboard.IsKeyDown(Keys.Right))
            {
                _snakePosition.X += speed;
            }
            else if (Input.Keyboard.IsKeyDown(Keys.S) || Input.Keyboard.IsKeyDown(Keys.Down))
            {
                _snakePosition.Y += speed;
            }
            else if (Input.Keyboard.IsKeyDown(Keys.A) || Input.Keyboard.IsKeyDown(Keys.Left))
            {
                _snakePosition.X -= speed;
            }
        }

        private void CheckGamePadInput()
        {
            GamePadInfo gamePadOne = Input.GamePads[(int)PlayerIndex.One];

            // If the A button is held down, the movement speed increases by 1.5
            // and the gamepad vibrates as feedback to the player.
            float speed = MOVEMENT_SPEED;
            if (gamePadOne.IsButtonDown(Buttons.A))
            {
                speed *= 1.5f;
                gamePadOne.SetVibration(1.0f, TimeSpan.FromSeconds(1));
            }
            else
            {
                gamePadOne.StopVibration();
            }

            // Check thumbstick first since it has priority over which gamepad input
            // is movement.  It has priority since the thumbstick values provide a
            // more granular analog value that can be used for movement.
            if (gamePadOne.LeftThumbStick != Vector2.Zero)
            {
                _snakePosition.X += gamePadOne.LeftThumbStick.X * speed;
                _snakePosition.Y -= gamePadOne.LeftThumbStick.Y * speed;
            }
            else
            {
                // If DPadUp is down, move the slime up on the screen.
                if (gamePadOne.IsButtonDown(Buttons.DPadUp))
                {
                    _snakePosition.Y -= speed;
                }

                // If DPadDown is down, move the slime down on the screen.
                if (gamePadOne.IsButtonDown(Buttons.DPadDown))
                {
                    _snakePosition.Y += speed;
                }

                // If DPapLeft is down, move the slime left on the screen.
                if (gamePadOne.IsButtonDown(Buttons.DPadLeft))
                {
                    _snakePosition.X -= speed;
                }

                // If DPadRight is down, move the slime right on the screen.
                if (gamePadOne.IsButtonDown(Buttons.DPadRight))
                {
                    _snakePosition.X += speed;
                }
            }
        }

        private void CheckKeyboardInputBuffer()
        {
            // In the input handling code:
            Vector2 newDirection = Vector2.Zero;

            float speed = MOVEMENT_SPEED;
            if (Input.Keyboard.IsKeyDown(Keys.Space))
            {
                speed *= 1.5f;
            }

            if (_lastDirection != Vector2.UnitY && (Input.Keyboard.IsKeyDown(Keys.W) || Input.Keyboard.IsKeyDown(Keys.Up)))
            {
                newDirection = -Vector2.UnitY;
            }
            else if (_lastDirection != -Vector2.UnitY && (Input.Keyboard.IsKeyDown(Keys.S) || Input.Keyboard.IsKeyDown(Keys.Down)))
            {
                newDirection = Vector2.UnitY;
            }
            else if (_lastDirection != Vector2.UnitX && (Input.Keyboard.IsKeyDown(Keys.A) || Input.Keyboard.IsKeyDown(Keys.Left)))
            {
                newDirection = -Vector2.UnitX;
            }
            else if (_lastDirection != -Vector2.UnitX && (Input.Keyboard.IsKeyDown(Keys.D) || Input.Keyboard.IsKeyDown(Keys.Right)))
            {
                newDirection = Vector2.UnitX;
            }

            // Only add if a valid direction and does not exceed the buffer size.
            if (newDirection != Vector2.Zero && _inputBuffer.Count < MAX_BUFFER_SIZE)
            {
                _inputBuffer.Enqueue(newDirection);
            }

            // In movement update code.
            if (_inputBuffer.Count > 1)
            {
                _lastDirection = _inputBuffer.Dequeue();
            }
            _snakePosition += _lastDirection * speed;
        }

        private void AssignRandomBatVelocity()
        {
            // Generate a random angle.
            float angle = (float)(Random.Shared.NextDouble() * Math.PI * 2);

            // Convert angle to a direction vector.
            float x = (float)Math.Cos(angle);
            float y = (float)Math.Sin(angle);
            Vector2 direction = new Vector2(x, y);

            // Multiply the direction vector by the movement speed.
            _appleVelocity = direction * MOVEMENT_SPEED;
        }

        protected override void Draw(GameTime gameTime)
        {
            GraphicsDevice.Clear(Color.CornflowerBlue);

            // Begin the sprite batch to prepare for rendering.
            SpriteBatch.Begin(SpriteSortMode.BackToFront);

            // Draw the slime sprite.
            _snake.Draw(SpriteBatch, _snakePosition);

            // Draw the bat sprite 10px to the right of the slime.
            _apple.Draw(SpriteBatch, _applePosition);

            // Always end the sprite batch when finished.
            SpriteBatch.End();

            base.Draw(gameTime);
        }
    }
}

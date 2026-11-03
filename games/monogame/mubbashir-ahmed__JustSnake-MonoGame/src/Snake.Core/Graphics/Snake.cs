using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using Snake.Core.Collisions;
using Snake.Core.Common;
using Snake.Core.Inputs;
using System;
using System.Collections.Generic;
using System.Linq;

namespace Snake.Core.Graphics
{
    public class Snake
    {
        /// <summary>
        /// The movement time in milliseconds.
        /// </summary>
        private const int MovementTimeMilliseconds = 200;

        /// <summary>
        /// The initial number of body segments.
        /// </summary>
        private const int InitialBodySegments = 3;
     
        /// <summary>
        /// The half size factor.
        /// </summary>
        private const float HalfSizeFactor = 0.5f;

        /// <summary>
        /// The movement time.
        /// </summary>
        private static readonly TimeSpan MovementTime = TimeSpan.FromMilliseconds(MovementTimeMilliseconds);

        /// <summary>
        /// The segments of the snake.
        /// </summary>
        private readonly List<SnakeSegment> segments = new List<SnakeSegment>();

        /// <summary>
        /// The current head sprite.
        /// </summary>
        private AnimatedSprite currentHeadSprite;

        /// <summary>
        /// The head up sprite.
        /// </summary>
        private readonly AnimatedSprite headUpSprite;

        /// <summary>
        /// The head down sprite.
        /// </summary>
        private readonly AnimatedSprite headDownSprite;

        /// <summary>
        /// The head left sprite.
        /// </summary>
        private readonly AnimatedSprite headLeftSprite;

        /// <summary>
        /// The head right sprite.
        /// </summary>
        private readonly AnimatedSprite headRightSprite;

        /// <summary>
        /// The body sprite.
        /// </summary>
        private readonly AnimatedSprite bodySprite;
        
        /// <summary>
        /// The movement speed.
        /// </summary>
        private readonly float movementSpeed;

        /// <summary>
        /// The movement timer.
        /// </summary>
        private TimeSpan movementTimer;

        /// <summary>
        /// The movement progress.
        /// </summary>
        private float movementProgress;
        
        /// <summary>
        /// The next direction.
        /// </summary>
        private Vector2 nextDirection;

        /// <summary>
        /// The just shrunk flag.
        /// </summary>
        private bool justShrunk;

        /// <summary>
        /// The has self collided this move flag.
        /// </summary>
        private bool hasSelfCollidedThisMove;

        /// <summary>
        /// The body collision event.
        /// </summary>
        private event EventHandler BodyCollision;

        /// <summary>
        /// Gets the head segment.
        /// </summary>
        public SnakeSegment HeadSegment => segments[0];

        /// <summary>
        /// Gets the body segments (excluding the head).
        /// </summary>
        public List<SnakeSegment> BodySegments
        {
            get
            {
                var body = new List<SnakeSegment>(segments.Count - 1);
                for (int i = 1; i < segments.Count; i++)
                {
                    body.Add(segments[i]);
                }
                return body;
            }
        }

        /// <summary>
        /// Gets whether the snake has collided with itself this move.
        /// </summary>
        public bool HasSelfCollidedThisMove => hasSelfCollidedThisMove;

        /// <summary>
        /// Initializes a new instance of the Snake class.
        /// </summary>
        /// <param name="headUpSprite">The sprite for the snake's head up.</param>
        /// <param name="headDownSprite">The sprite for the snake's head down.</param>
        /// <param name="headLeftSprite">The sprite for the snake's head left.</param>
        /// <param name="headRightSprite">The sprite for the snake's head right.</param>
        /// <param name="bodySprite">The sprite for the snake's body segments.</param>
        /// <param name="tilemap">The tilemap to spawn the snake on.</param>
        public Snake(
            AnimatedSprite headUpSprite, 
            AnimatedSprite headDownSprite, 
            AnimatedSprite headLeftSprite, 
            AnimatedSprite headRightSprite, 
            AnimatedSprite bodySprite, 
            Tilemap tilemap
        )
        {
            ArgumentNullException.ThrowIfNull(headUpSprite);
            ArgumentNullException.ThrowIfNull(headDownSprite);
            ArgumentNullException.ThrowIfNull(headLeftSprite);
            ArgumentNullException.ThrowIfNull(headRightSprite);
            ArgumentNullException.ThrowIfNull(bodySprite);
            ArgumentNullException.ThrowIfNull(tilemap);

            // Set the head and body sprites
            this.headUpSprite = headUpSprite;
            this.headDownSprite = headDownSprite;
            this.headLeftSprite = headLeftSprite;
            this.headRightSprite = headRightSprite;
            this.currentHeadSprite = headRightSprite;
            this.bodySprite = bodySprite;

            // Set the movement speed
            this.movementSpeed = tilemap.TileSize;

            // Get a random position on the tilemap
            Vector2 position = Helper.GetRandomVector2(tilemap);

            // Create the head segment
            SnakeSegment head = new SnakeSegment
            {
                At = position,
                To = position + new Vector2(movementSpeed, 0),
                Direction = Vector2.UnitX
            };

            // Create the body segments
            for (int i = 1; i <= InitialBodySegments; i++)
            {
                SnakeSegment body = new SnakeSegment
                {
                    At = position - new Vector2(i * movementSpeed, 0),
                    To = position + new Vector2(movementSpeed, 0),
                    Direction = Vector2.UnitX
                };

                segments.Add(body);
            }

            segments.Add(head);

            // Set the next direction and movement timer
            nextDirection = head.Direction;
            movementTimer = TimeSpan.Zero;
            
            // Initialize the head sprite based on initial direction
            UpdateHeadSprite(head.Direction);
        }

        /// <summary>
        /// Handles input to change the snake's direction.
        /// </summary>
        /// <param name="inputState">The current input state.</param>
        public void HandleInput(InputState inputState)
        {
            ArgumentNullException.ThrowIfNull(inputState);

            // Get the current keyboard and gamepad states
            Vector2 newDirection = nextDirection;
            var keyboardState = inputState.CurrentKeyboardStates[0];
            var gamePadState = inputState.CurrentGamePadStates[0];

            // Check if the up key is pressed and set the new direction
            if (keyboardState.IsKeyDown(Keys.Up) || keyboardState.IsKeyDown(Keys.W) ||
                gamePadState.IsButtonDown(Buttons.DPadUp) || gamePadState.IsButtonDown(Buttons.LeftThumbstickUp))
            {
                newDirection = -Vector2.UnitY;
            }
            // Check if the down key is pressed and set the new direction
            else if (keyboardState.IsKeyDown(Keys.Down) || keyboardState.IsKeyDown(Keys.S) ||
                     gamePadState.IsButtonDown(Buttons.DPadDown) || gamePadState.IsButtonDown(Buttons.LeftThumbstickDown))
            {
                newDirection = Vector2.UnitY;
            }
            // Check if the left key is pressed and set the new direction
            else if (keyboardState.IsKeyDown(Keys.Left) || keyboardState.IsKeyDown(Keys.A) ||
                     gamePadState.IsButtonDown(Buttons.DPadLeft) || gamePadState.IsButtonDown(Buttons.LeftThumbstickLeft))
            {
                newDirection = -Vector2.UnitX;
            }
            // Check if the right key is pressed and set the new direction
            else if (keyboardState.IsKeyDown(Keys.Right) || keyboardState.IsKeyDown(Keys.D) ||
                     gamePadState.IsButtonDown(Buttons.DPadRight) || gamePadState.IsButtonDown(Buttons.LeftThumbstickRight))
            {
                newDirection = Vector2.UnitX;
            }

            // Check if the new direction is valid and set the next direction
            float dot = Vector2.Dot(newDirection, segments[0].Direction);
            if (dot >= 0)
            {
                nextDirection = newDirection;
                UpdateHeadSprite(nextDirection);
            }
        }

        /// <summary>
        /// Moves the snake forward one step.
        /// </summary>
        public void Move()
        {
            // Reset the has self collided this move and just shrunk flags
            hasSelfCollidedThisMove = false;
            justShrunk = false;

            // Get the head segment
            SnakeSegment head = segments[0];

            // Set the direction of the head segment
            head.Direction = nextDirection;
            
            // Update the head sprite based on direction
            UpdateHeadSprite(head.Direction);

            // Set the position of the head segment
            head.At = head.To;

            // Set the target position of the head segment
            head.To = head.At + head.Direction * movementSpeed;

            // Insert the head segment at the beginning of the segments list
            segments.Insert(0, head);

            // Remove the last segment from the segments list
            segments.RemoveAt(segments.Count - 1);

            // Check if the head segment has collided with any other segment
            for (int i = 2; i < segments.Count; i++)
            {
                if (head.At == segments[i].At) 
                {
                    // Set the has self collided this move flag and invoke the body collision event
                    hasSelfCollidedThisMove = true;
                    BodyCollision?.Invoke(this, EventArgs.Empty);
                    return;
                }
            }
        }

        /// <summary>
        /// Grows the snake by adding a new tail segment.
        /// </summary>
        /// <returns>True if the snake grew successfully.</returns>
        public bool Grow()
        {
            // Get the tail segment
            SnakeSegment tail = segments[segments.Count - 1];

            // Create a new tail segment
            SnakeSegment newTail = new SnakeSegment
            {
                At = tail.To + tail.ReverseDirection * movementSpeed,
                To = tail.At,
                Direction = Vector2.Normalize(tail.At - (tail.To + tail.ReverseDirection * movementSpeed))
            };

            // Add the new tail segment to the segments list
            segments.Add(newTail);
            return true;
        }

        /// <summary>
        /// Shrinks the snake by removing the last segment.
        /// </summary>
        /// <returns>True if the snake shrank successfully.</returns>
        public bool Shrink()
        {
            // Check if the snake has just shrunk or has less than 2 segments and return false
            if (justShrunk || segments.Count <= 1) return false;

            // Remove the last segment from the segments list
            segments.RemoveAt(segments.Count - 1);

            // Set the just shrunk flag
            justShrunk = true;
            return true;
        }

        /// <summary>
        /// Updates the head sprite based on the current direction.
        /// </summary>
        /// <param name="direction">The current direction vector.</param>
        private void UpdateHeadSprite(Vector2 direction)
        {
            // Check if the direction is up and set the current head sprite
            if (direction == -Vector2.UnitY)
            {
                currentHeadSprite = headUpSprite;
            }
            // Check if the direction is down and set the current head sprite
            else if (direction == Vector2.UnitY)
            {
                currentHeadSprite = headDownSprite;
            }
            // Check if the direction is left and set the current head sprite
            else if (direction == -Vector2.UnitX)
            {
                currentHeadSprite = headLeftSprite;
            }
            // Check if the direction is right and set the current head sprite
            else if (direction == Vector2.UnitX)
            {
                currentHeadSprite = headRightSprite;
            }
        }

        /// <summary>
        /// Gets the collision bounds for a snake segment.
        /// </summary>
        /// <param name="segment">The segment to get bounds for.</param>
        /// <returns>A circle representing the collision bounds.</returns>
        public Circle GetBounds(SnakeSegment segment)
        {
            // Calculate the position of the segment
            Vector2 pos = Vector2.Lerp(segment.At, segment.To, movementProgress);

            // Calculate the radius of the segment
            //float radius = headSprite.Width * HalfSizeFactor;
            float radius = currentHeadSprite.Width * HalfSizeFactor;
            
            // Return the collision bounds for the segment
            return new Circle(
                (int)(pos.X + radius),
                (int)(pos.Y + radius),
                (int)radius
            );
        }

        /// <summary>
        /// Draws the snake to the sprite batch.
        /// </summary>
        /// <param name="spriteBatch">The sprite batch to draw to.</param>
        public void Draw(SpriteBatch spriteBatch)
        {
            // Draw each segment of the snake
            for (int i = 0; i < segments.Count; i++)
            {
                // Calculate the position of the segment
                Vector2 position = Vector2.Lerp(segments[i].At, segments[i].To, movementProgress);

                // Check if the segment is the head and draw it
                if (i == 0)
                {
                    currentHeadSprite.Position = position;
                    currentHeadSprite.Draw(spriteBatch);
                }
                else
                {
                    bodySprite.Position = position;
                    bodySprite.Draw(spriteBatch);
                }
            }
        }

        /// <summary>
        /// Updates the snake's animation and movement.
        /// </summary>
        /// <param name="gameTime">The game time.</param>
        public void Update(GameTime gameTime)
        {
            // Update the head sprite
            currentHeadSprite.Update(gameTime);
            
            // Update the body sprite
            bodySprite.Update(gameTime);

            // Update the movement timer
            movementTimer += gameTime.ElapsedGameTime;

            // Check if the movement timer is greater than or equal to the movement time and move the snake
            if (movementTimer >= MovementTime)
            {
                movementTimer -= MovementTime;
                Move();
            }

            movementProgress = (float)(movementTimer.TotalSeconds / MovementTime.TotalSeconds);
        }
    }
}

using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Audio;
using Microsoft.Xna.Framework.Graphics;
using System;

namespace TiltMaze
{
    public class Enemy
    {
        // Static sound effect for wall bounces (shared among all instances)
        private static SoundEffect wallBounceSound;
        private static SoundEffectInstance wallBounceInstance;
        
        // Flag to ensure we only initialize static members once
        //private static bool isInitialized = false;
        public Vector2 Position { get; private set; }
        public Vector2 Direction { get; private set; }
        private Random random;
        private float speed = 100f; 
        private float cellSize;
        private Color color;
        private float size = 10f; 

        public Enemy(Vector2 startPosition, float cellSize)
        {
            this.cellSize = cellSize;
            random = new Random(Guid.NewGuid().GetHashCode());
            Position = startPosition * cellSize + new Vector2(cellSize/2 - size/2, cellSize/2 - size/2);
            
            // Initialize static sound effect if not already done
            //if (!isInitialized && Game1.ContentLoaded)
            {
                try
                {
                    wallBounceSound = Game1.ContentManager.Load<SoundEffect>("wall_bounce");
                    wallBounceInstance = wallBounceSound.CreateInstance();
                    //isInitialized = true;
                }
                catch (Exception ex)
                {
                    // If sound loading fails, the game can still continue
                    System.Diagnostics.Debug.WriteLine($"Failed to load sound effect: {ex.Message}");
                    //isInitialized = true; // Don't try to load again
                }
            }
            
            SetRandomDiagonalDirection();
            
            color = new Color(
                (float)random.NextDouble(),
                (float)random.NextDouble(),
                (float)random.NextDouble()
            );
        }

        public Enemy(Vector2 enemyStartPos)
        {
            this.Position = enemyStartPos;
        }

        private void SetRandomDiagonalDirection()
        {
            float angle = (float)(random.NextDouble() * Math.PI * 2);
            Direction = new Vector2((float)Math.Cos(angle), (float)Math.Sin(angle));
            
            if (Direction != Vector2.Zero)
                Direction.Normalize();
        }

        public void Update(GameTime gameTime, MazeGrid mazeGrid, float cellSize)
        {
            float deltaTime = (float)gameTime.ElapsedGameTime.TotalSeconds;
            Vector2 nextPosition = Position + Direction * speed * deltaTime;

            bool bounced = false;

            int currentCellX = (int)(Position.X / cellSize);
            int currentCellY = (int)(Position.Y / cellSize);

            if (nextPosition.X < 0 || nextPosition.X + size > mazeGrid.Width * cellSize)
            {
                Direction = new Vector2(-Direction.X, Direction.Y);
                bounced = true;
            }
            if (nextPosition.Y < 0 || nextPosition.Y + size > mazeGrid.Height * cellSize)
            {
                Direction = new Vector2(Direction.X, -Direction.Y);
                bounced = true;
            }

            if (currentCellX >= 0 && currentCellX < mazeGrid.Width && 
                currentCellY >= 0 && currentCellY < mazeGrid.Height)
            {
                MazeCell cell = mazeGrid.Cells[currentCellX, currentCellY];
                float nextCellX = nextPosition.X / cellSize;
                float nextCellY = nextPosition.Y / cellSize;

                if (Direction.X < 0 && cell.HasLeft && nextPosition.X < currentCellX * cellSize + 2)
                {
                    Direction = new Vector2(-Direction.X, Direction.Y);
                    bounced = true;
                }
                else if (Direction.X > 0 && cell.HasRight && nextPosition.X + size > (currentCellX + 1) * cellSize - 2)
                {
                    Direction = new Vector2(-Direction.X, Direction.Y);
                    bounced = true;
                }

                if (Direction.Y < 0 && cell.HasTop && nextPosition.Y < currentCellY * cellSize + 2)
                {
                    Direction = new Vector2(Direction.X, -Direction.Y);
                    bounced = true;
                }
                else if (Direction.Y > 0 && cell.HasBottom && nextPosition.Y + size > (currentCellY + 1) * cellSize - 2)
                {
                    Direction = new Vector2(Direction.X, -Direction.Y);
                    bounced = true;
                }
            }

            if (bounced)
            {
                // Play wall bounce sound if available
                if (wallBounceInstance != null && wallBounceInstance.State != SoundState.Playing)
                {
                    wallBounceInstance.Stop();
                    wallBounceInstance.Play();                    
                }
                
                // Add a small random angle when bouncing
                float angle = (float)(Math.Atan2(Direction.Y, Direction.X) + (random.NextDouble() - 0.5) * 0.5);
                Direction = new Vector2((float)Math.Cos(angle), (float)Math.Sin(angle));
                Direction.Normalize();
            }
            else
            {
                Position = nextPosition;
            }
        }

        public void Draw(SpriteBatch spriteBatch, Texture2D texture)
        {
            spriteBatch.Draw(
                texture, 
                new Rectangle(
                    (int)Position.X, 
                    (int)Position.Y, 
                    (int)size, 
                    (int)size
                ), 
                color
            );
        }
    }
}
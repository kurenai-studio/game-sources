using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using System.Collections.Generic;
using System;
using Windows.Devices.Sensors;
using Microsoft.Xna.Framework.Input;
using System.Diagnostics;
using Microsoft.Xna.Framework.Audio;
using Microsoft.Xna.Framework.Media;
using Microsoft.Xna.Framework.Input.Touch;

namespace TiltMaze
{
    public class Game1 : Game
    {
        // Static properties for content management
        public static bool ContentLoaded { get; private set; } = false;
        public static Microsoft.Xna.Framework.Content.ContentManager ContentManager { get; private set; }
        GraphicsDeviceManager graphics;
        SpriteBatch spriteBatch;
        public const int startLevel = 1;
        public const int levelsCount = 25; 
        private MazeGrid mazeGrid;
        private Vector2 playerPosition;
        private Texture2D playerTexture;
        private Texture2D enemyTexture;
        private Texture2D wallTexture;
        private Texture2D exitTexture;
        private List<Enemy> enemies;
        private int currentLevel;
        private TimeSpan totalGameTime;
        private SpriteFont font;
        private Accelerometer _accelerometer;
        private bool gameWon = false;
        private Vector2 movement = Vector2.Zero;
        private const float playerSpeed = 6f;
        
        // Touch input handling
        private Vector2? touchStartPosition = null;
        private const float minSwipeDistance = 30f; // Minimum distance in pixels to consider it a swipe 
        public float cellSize = 60f; 

        private SoundEffect wallBounceSound;
        private SoundEffect playerHitSound;
        private SoundEffect coinSound;
        private SoundEffect levelcompleteSound;
        private SoundEffect youwinSound;

        private SoundEffectInstance wallBounceInstance;
        private SoundEffectInstance playerHitInstance;
        private SoundEffectInstance coinInstance;
        private SoundEffectInstance levelcompleteInstance;
        private SoundEffectInstance youwinInstance;

        public static Song Music { get; private set; }


        public Game1()
        {
            graphics = new GraphicsDeviceManager(this);
            Content.RootDirectory = "Content";
            ContentManager = Content; // Set static reference to content manager
            
            // Set up the game to scale to the device's screen
            graphics.PreferredBackBufferWidth = GraphicsAdapter.DefaultAdapter.CurrentDisplayMode.Width;
            graphics.PreferredBackBufferHeight = GraphicsAdapter.DefaultAdapter.CurrentDisplayMode.Height;
            graphics.IsFullScreen = true;
                    
            // Enable mouse for touch input
            IsMouseVisible = true;

            // Calculate cell size based on screen dimensions and desired maze size
            int mazeWidth = 10; // Number of cells wide
            int mazeHeight = 10; // Number of cells tall
            
            // Calculate maximum possible cell size that fits the screen
            float maxCellWidth = (float)graphics.PreferredBackBufferWidth / mazeWidth;
            float maxCellHeight = (float)graphics.PreferredBackBufferHeight / mazeHeight;
            cellSize = Math.Min(maxCellWidth, maxCellHeight) * 0.9f; // 90% of max to add some padding
            
            // Initialize maze grid with calculated cell size
            mazeGrid = new MazeGrid(mazeWidth, mazeHeight);
            
            // Center the game area on screen
            float gameAreaWidth = mazeGrid.Width * cellSize;
            float gameAreaHeight = mazeGrid.Height * cellSize;
            gameAreaOffset = new Vector2(
                (graphics.PreferredBackBufferWidth - gameAreaWidth) / 2,
                (graphics.PreferredBackBufferHeight - gameAreaHeight) / 2
            );

            
            _accelerometer = Accelerometer.GetDefault();
            if (_accelerometer != null)
            {
               
                uint minReportInterval = _accelerometer.MinimumReportInterval;
                uint desiredReportInterval = minReportInterval > 16 ? minReportInterval : 16; // ~60 FPS
                _accelerometer.ReportInterval = desiredReportInterval;
            }
        }

        // Game area offset for centering
        private Vector2 gameAreaOffset = Vector2.Zero;
        
        // Scale matrix for drawing
        private Matrix scaleMatrix;
        
        protected override void Initialize()
        {
            // Enable touch panel for touch input
            TouchPanel.EnabledGestures = GestureType.None; // We'll handle raw touch input
            TouchPanel.EnableMouseTouchPoint = true; // For testing on PC with mouse
            
            currentLevel = startLevel;
            totalGameTime = TimeSpan.Zero;            

            // Calculate scale matrix for proper drawing
            float scaleX = (float)graphics.PreferredBackBufferWidth / (mazeGrid.Width * cellSize);
            float scaleY = (float)graphics.PreferredBackBufferHeight / (mazeGrid.Height * cellSize);
            float scale = Math.Min(scaleX, scaleY) * 0.9f; // 90% of scale to add padding
            
            // Calculate offset to center the game area
            float offsetX = (graphics.PreferredBackBufferWidth - (mazeGrid.Width * cellSize * scale)) / 2;
            float offsetY = (graphics.PreferredBackBufferHeight - (mazeGrid.Height * cellSize * scale)) / 2;
            
            // Create scale and translation matrix
            scaleMatrix = Matrix.CreateScale(scale, scale, 1.0f) * 
                         Matrix.CreateTranslation(offsetX, offsetY, 0);
            
            
            ContentLoaded = true; // Mark content as loaded for static initialization
            
            base.Initialize();

            InitializeLevel(currentLevel);
        }

        private void InitializeLevel(int level)
        {
            mazeGrid.GenerateMaze();

            // Get the start cell position and set player to its center
            playerPosition = new Vector2(
                 (int)mazeGrid.GetStartCellPosition().X,
                 (int)mazeGrid.GetStartCellPosition().Y
             );

            // Adjust player position to center in the cell
            playerPosition = new Vector2(
                        playerPosition.X + 25, // Adjust for player size
                        playerPosition.Y + 25
                    ); // Center player in cell

            // Play or restart level music
            if (MediaPlayer.State == MediaState.Playing)
            {
                MediaPlayer.Stop();
            }
            MediaPlayer.Play(Music);

            enemies = new List<Enemy>();
            for (int i = 0; i < level; i++)
            {
                Point enemyCell = new Point((int)mazeGrid.GetRandomCellPosition().X, (int)mazeGrid.GetRandomCellPosition().Y);
                enemies.Add(new Enemy(new Vector2(enemyCell.X, enemyCell.Y), cellSize));
            }
        }

        protected override void LoadContent()
        {
            spriteBatch = new SpriteBatch(GraphicsDevice);

            // wall
            wallTexture = new Texture2D(GraphicsDevice, 1, 1);
            wallTexture.SetData(new[] { Color.LimeGreen });

            // player
            playerTexture = new Texture2D(GraphicsDevice, 1, 1);
            playerTexture.SetData(new[] { Color.Red });

            // Create exit texture (white 1x1 pixel, will be scaled)
            exitTexture = new Texture2D(GraphicsDevice, 1, 1);
            exitTexture.SetData(new[] { Color.White });
            
            // Create enemy texture (white 1x1 pixel, will be colored when drawn)
            enemyTexture = new Texture2D(GraphicsDevice, 1, 1);
            enemyTexture.SetData(new[] { Color.White });
            
            // Load sound effects and music
            wallBounceSound = Content.Load<SoundEffect>("wall_bounce");
            playerHitSound = Content.Load<SoundEffect>("player_hit");
            levelcompleteSound = Content.Load<SoundEffect>("level_complete");
            youwinSound = Content.Load<SoundEffect>("you_win");
            Music = Content.Load<Song>("Music");

            // Create sound instances for better control
            wallBounceInstance = wallBounceSound.CreateInstance();
            playerHitInstance = playerHitSound.CreateInstance();
            levelcompleteInstance = levelcompleteSound.CreateInstance();
            youwinInstance = youwinSound.CreateInstance();
            
            // Set music to loop
            MediaPlayer.IsRepeating = true;


            font = Content.Load<SpriteFont>("font");         // You need to add a 'font.spritefont' to your Content
        }

        protected override void UnloadContent()
        {
            // TODO: Unload any non ContentManager content here
        }

        protected override void Update(GameTime gameTime)
        {
            // *** Experimental **********************
            // Calculate scale matrix for proper drawing
            /*
            float scaleX = (float)graphics.PreferredBackBufferWidth / (mazeGrid.Width * cellSize);
            float scaleY = (float)graphics.PreferredBackBufferHeight / (mazeGrid.Height * cellSize);
            float scale = Math.Min(scaleX, scaleY) * 0.9f; // 90% of scale to add padding

            // Calculate offset to center the game area
            float offsetX = (graphics.PreferredBackBufferWidth - (mazeGrid.Width * cellSize * scale)) / 2;
            float offsetY = (graphics.PreferredBackBufferHeight - (mazeGrid.Height * cellSize * scale)) / 2;

            // Create scale and translation matrix
            scaleMatrix = Matrix.CreateScale(scale, scale, 1.0f) *
                         Matrix.CreateTranslation(offsetX, offsetY, 0);
            */
            // ***************************************

            totalGameTime += gameTime.ElapsedGameTime;


            // Game controls
            movement = Vector2.Zero;
            
            // Handle touch input
            var touchState = TouchPanel.GetState();
            if (touchState.Count > 0)
            {
                var touch = touchState[0];
                
                switch (touch.State)
                {
                    case TouchLocationState.Pressed:
                        touchStartPosition = touch.Position;
                        break;
                        
                    case TouchLocationState.Moved:
                        if (touchStartPosition.HasValue)
                        {
                            Vector2 delta = touch.Position - touchStartPosition.Value;
                            
                            // Check if the touch has moved enough to be considered a swipe
                            if (delta.Length() > minSwipeDistance)
                            {
                                // Determine the primary direction of the swipe
                                if (Math.Abs(delta.X) > Math.Abs(delta.Y))
                                {
                                    // Horizontal swipe
                                    movement.X = Math.Sign(delta.X);
                                }
                                else
                                {
                                    // Vertical swipe
                                    movement.Y = Math.Sign(delta.Y);
                                }
                                
                                // Reset start position to allow continuous movement
                                touchStartPosition = touch.Position;
                            }
                        }
                        break;
                        
                    case TouchLocationState.Released:
                        touchStartPosition = null;
                        break;
                }
            }
            
            // Fall back to keyboard controls if no touch input
            if (movement == Vector2.Zero)
            {
                var keyboardState = Keyboard.GetState();

                if (keyboardState.IsKeyDown(Keys.Left) || keyboardState.IsKeyDown(Keys.A)) movement.X -= 1;
                if (keyboardState.IsKeyDown(Keys.Right) || keyboardState.IsKeyDown(Keys.D)) movement.X += 1;
                if (keyboardState.IsKeyDown(Keys.Up) || keyboardState.IsKeyDown(Keys.W)) movement.Y -= 1;
                if (keyboardState.IsKeyDown(Keys.Down) || keyboardState.IsKeyDown(Keys.S)) movement.Y += 1;
            }   
            
            // Normalize diagonal movement
            if (movement != Vector2.Zero)
            {

                if (gameWon)
                {
                    //gameWon = false;
                    //currentLevel = 1;
                    //playerPosition = new Vector2(
                    //       (int)mazeGrid.GetStartCellPosition().X,
                    //       (int)mazeGrid.GetStartCellPosition().Y
                    //   );

                    // Adjust player position to center in the cell
                    //playerPosition = new Vector2(
                    //            playerPosition.X + 25, // Adjust for player size
                    //            playerPosition.Y + 25
                    //        ); // Center player in cell
                    return;
                }

                movement.Normalize();
                Vector2 newPosition = playerPosition + movement * playerSpeed;
                    
                // Check wall collisions
                if (!IsWallCollision(newPosition, /*cellSize / 2*/ 5))
                {
                    playerPosition = newPosition;
                }
            }
                
            // Keep player within bounds (not needed for closed contour of labyrinth)
            //playerPosition.X = MathHelper.Clamp(playerPosition.X, 0, graphics.PreferredBackBufferWidth - 10);
            //playerPosition.Y = MathHelper.Clamp(playerPosition.Y, 0, graphics.PreferredBackBufferHeight - 10);
           

            // Обновление врагов
            foreach (var enemy in enemies)
            {
                enemy.Update(gameTime, mazeGrid, cellSize);

               
                float playerRadius = 5f; 
                float enemyRadius = 5f; 
                float minDistance = playerRadius + enemyRadius;

                if (!gameWon)
                {
                    if (Vector2.Distance(playerPosition + new Vector2(playerRadius),
                                       enemy.Position + new Vector2(enemyRadius)) < minDistance)
                    {
                        // Play player hit sound and reset position
                        // Play wall bounce sound if available
                        if (playerHitInstance != null && playerHitInstance.State != SoundState.Playing)
                        {
                            playerHitInstance.Stop();
                            playerHitInstance.Play();
                        }

                        // Adjust player position to center in the cell 
                        playerPosition = new Vector2(
                            (int)mazeGrid.GetStartCellPosition().X,
                            (int)mazeGrid.GetStartCellPosition().Y);
                        playerPosition = new Vector2(playerPosition.X + 25, playerPosition.Y + 25);
                    }
                }
            }

            // Check if player reached exit
            if (!gameWon)
            {
                int exitSize = 20;
                int exitX = (int)((mazeGrid.Width - 1) * cellSize + (cellSize - exitSize) / 2);
                int exitY = (int)((mazeGrid.Height - 1) * cellSize + (cellSize - exitSize) / 2);
                Rectangle exitRect = new Rectangle(exitX, exitY, exitSize, exitSize);
                Rectangle playerRect = new Rectangle((int)playerPosition.X, (int)playerPosition.Y, 10, 10);
                
                if (exitRect.Intersects(playerRect))
                {
                    if (currentLevel >= levelsCount)
                    {

                        // Play you win sound 
                        // Play wall bounce sound if available
                        if (youwinInstance != null && youwinInstance.State != SoundState.Playing)
                        {
                            youwinInstance.Stop();
                            youwinInstance.Play();
                        }
                        // Game won!
                        gameWon = true;
                    }
                    else
                    {
                        // Play level complete sound
                        // // Play wall bounce sound if available
                        if (levelcompleteInstance != null && levelcompleteInstance.State != SoundState.Playing)
                        {
                            levelcompleteInstance.Stop();
                            levelcompleteInstance.Play();
                        }

                        // increase level 
                        currentLevel++;
                        InitializeLevel(currentLevel);
                    }
                }
            }

            base.Update(gameTime);
        }

        protected override void Draw(GameTime gameTime)
        {
            GraphicsDevice.Clear(Color.Black);

            // Apply scaling and translation
            // Note: We handle the scaling in the transformation matrix, so we don't need to scale positions manually
            spriteBatch.Begin(SpriteSortMode.Deferred, null, null, null, null, null, scaleMatrix);

            // Draw maze
            mazeGrid.Draw(spriteBatch, GraphicsDevice, wallTexture, this.cellSize);
            
            // Draw exit (gray square in bottom-right cell)
            if (!gameWon)
            {
                int exitSize = 20;
                int exitX = (int)((mazeGrid.Width - 1) * cellSize + (cellSize - exitSize) / 2);
                int exitY = (int)((mazeGrid.Height - 1) * cellSize + (cellSize - exitSize) / 2);
                
                // Draw exit as an unfilled gray square
                Rectangle exitRect = new Rectangle(exitX, exitY, exitSize, exitSize);
                spriteBatch.Draw(exitTexture, exitRect, Color.Gray);
                
                // Draw exit border
                Rectangle exitBorder = new Rectangle(exitX - 1, exitY - 1, exitSize + 2, exitSize + 2);
                spriteBatch.Draw(exitTexture, exitBorder, Color.White);
            }

            // Draw player (red)
            int playerSize = 10; 
            int playerHalfSize = playerSize / 2;
            
            
            spriteBatch.Draw(
                playerTexture,
                new Rectangle(
                    (int)playerPosition.X,
                    (int)playerPosition.Y,
                    playerSize,
                    playerSize
                ),
                Color.Red
            );

            // Draw enemies 
            foreach (var enemy in enemies)
            {
                enemy.Draw(spriteBatch, enemyTexture);
            }

            // Draw UI (Level, Time, and Win Message)
            if (gameWon)
            {
                string winText = "You Win";
                Vector2 textSize = font.MeasureString(winText);
                Vector2 textPosition = new Vector2(
                    MathHelper.Clamp((graphics.PreferredBackBufferWidth - textSize.X) / 2, 50, 250),
                    MathHelper.Clamp((graphics.PreferredBackBufferHeight - textSize.Y) / 2, 50, 250)
                );
                spriteBatch.DrawString(font, winText, textPosition, Color.Cyan);
            }
            else
            {
                spriteBatch.DrawString(font, "Level " + currentLevel.ToString() + " of " + levelsCount.ToString(), 
                    new Vector2(2, 2), Color.White);
                //spriteBatch.DrawString(font, "Time " + totalGameTime.ToString(@"mm\:ss"), new Vector2(10, 40), Color.White);
            }

            spriteBatch.End();

            base.Draw(gameTime);
        }//

        private Vector2 CellToPixel(Point cell)
        {
            // Convert cell coordinates to pixel coordinates with proper scaling
            // Center the position in the cell (5 is half of player size)
            return new Vector2(
                cell.X * cellSize + cellSize/2 - 5, 
                cell.Y * cellSize + cellSize/2 - 5
            ) + gameAreaOffset;
        }
        
        private Vector2 GetCellCenter(Point cell)
        {
            // Get the center of a cell in screen coordinates
            return new Vector2(
                cell.X * cellSize + cellSize / 2,
                cell.Y * cellSize + cellSize / 2
            ) + gameAreaOffset;
        }
        
        private bool IsWallCollision(Vector2 position, float radius)
        {
            // Check if position is outside maze bounds
            if (position.X - radius < 0 || position.X + radius > graphics.PreferredBackBufferWidth ||
                position.Y - radius < 0 || position.Y + radius > graphics.PreferredBackBufferHeight)
            {
                return true;
            }
            
            // Get the cell at the position
            int cellX = (int)(position.X / cellSize);
            int cellY = (int)(position.Y / cellSize);
            
            // Check if cell is valid
            if (cellX < 0 || cellX >= mazeGrid.Width || cellY < 0 || cellY >= mazeGrid.Height)
                return true;
                
            MazeCell cell = mazeGrid.Cells[cellX, cellY];
            
            // Check wall collisions
            if (position.X - radius < cellX * cellSize + 2 && cell.HasLeft) return true;
            if (position.X + radius > (cellX + 1) * cellSize - 2 && cell.HasRight) return true;
            if (position.Y - radius < cellY * cellSize + 2 && cell.HasTop) return true;
            if (position.Y + radius > (cellY + 1) * cellSize - 2 && cell.HasBottom) return true;
            
            return false;
        }
    }
}
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using System;
using System.Collections.Generic;
using System.IO;

namespace BeeGameMaster
{
    /// <summary>
    /// This is the main type for your game.
    /// </summary>
    public class Game1 : Game
    {
        #region Fields


        GraphicsDeviceManager graphics;
        SpriteBatch spriteBatch;
        SpriteFont spriteFont;
        SpriteFont menuFont;

        private GameState gameState;

        //mouse and keyboard states
        private MouseState mState;
        private MouseState prevMState;
        private KeyboardState kbState;
        private KeyboardState prevKbState;

        //main menu textures
        private Texture2D Menu;
        private Texture2D buttonStart;
        //game over menu textures
        private Texture2D GameOver;
        private Texture2D buttonGameOverMainMenu;
        private Texture2D buttonPlayAgain;
        //win menu textures
        private Texture2D Win;

        //main menu rectangle locations
        private Rectangle MenuLoc;
        private Rectangle buttonStartLoc;
        //game over menu rectangle location
        private Rectangle GameOverLoc;
        private Rectangle buttonGameOverMenuMainLoc;
        private Rectangle buttonPlayAgainLoc;
        //win menu rectangle location
        private Rectangle WinLoc;

        //main menu button colors TEMPORARY
        private Color buttonStartColor;

        //game over button color TEMPORARY
        private Color buttonMenuColor;
        private Color buttonPlayAgainColor;

        //This enum keeps track of the possible game states.
        public enum GameState
        {
            Menu,
            Game,
            GameOver,
            Win,
            Pause
        }

        Texture2D playerTexture;
        Texture2D hiveTexture;
        Texture2D enemyTexture;
        Texture2D waspTexture;
        Texture2D yellowjacketTexture;
        Texture2D stingerTexture;
        Texture2D enemyStinger;
        //health
        Texture2D powerupTexture1;
        //ammo
        Texture2D powerupTexture2;
        //clock
        Texture2D powerupTexture3;
        //Player is static to allow it to be referenced in the enemy class for the slow time power up
        public static Player player;
        Hive hive;
        //Added blank list of enemies, started some collision code but I commented it out for now-Max
        List<Enemy> enemies = new List<Enemy>();
        List<Projectile> stingers = new List<Projectile>();
        List<Powerup> powerups = new List<Powerup>();
        int deadEnemies = 0;
        int currentWave = 1;
        Wasp enemy;
        int width;
        int height;
        Random rng = new Random();
        //used to compare health before and after check collision
        int hiveOldHealth = 0;
        double maxHiveHealth = 0;

        //rectangles for health bar
        Rectangle healthBarRec;
        Texture2D healthBar;
        Rectangle healthBarBgRec;
        Texture2D healthBarBg;

        //for measuring time
        bool hit = false;
        int delay = 5;

        //bullet power up counter
        int poweredShot = 0;

        #endregion

        public Game1()
        {
            graphics = new GraphicsDeviceManager(this);
            graphics.PreferredBackBufferWidth = 1600;
            graphics.PreferredBackBufferHeight = 1000;
            graphics.ApplyChanges();
            Content.RootDirectory = "Content";
        }

        /// <summary>
        /// Allows the game to perform any initialization it needs to before starting to run.
        /// This is where it can query for any required services and load any non-graphic
        /// related content.  Calling base.Initialize will enumerate through any components
        /// and initialize them as well.
        /// </summary>
        protected override void Initialize()
        {
            // TODO: Add your initialization logic here

            width = GraphicsDevice.Viewport.Width;
            height = GraphicsDevice.Viewport.Height;

            //menu
            MenuLoc = new Rectangle(width / 2 - width / 2, height / 2 - height / 2, width, height);
            buttonStartLoc = new Rectangle(width / 2 - (width / 8), height / 4, width / 4, height / 4);

            //game over
            GameOverLoc = new Rectangle(width / 2 - width / 2, height / 2 - height / 2, width, height);
            buttonGameOverMenuMainLoc = new Rectangle(width / 2 - (width / 8), 5 * height / 7, width / 4, height / 4);
            buttonPlayAgainLoc = new Rectangle(width / 2 - (width / 8), height / 2, width / 4, height / 4);

            //win
            WinLoc = new Rectangle(width / 2 - width / 2, height / 2 - height / 2, width, height);
            buttonMenuColor = Color.White;
            buttonMenuColor = Color.White;
            buttonStartColor = Color.White;

            //healthbar

            healthBarBgRec = new Rectangle(48, height - 148, 404, 34);
            healthBarRec = new Rectangle(50, height - 146, 400, 30);

            base.Initialize();
        }

        /// <summary>
        /// LoadContent will be called once per game and is the place to load
        /// all of your content.
        /// </summary>
        protected override void LoadContent()
        {
            // Create a new SpriteBatch, which can be used to draw textures.
            spriteBatch = new SpriteBatch(GraphicsDevice);
            // TODO: use this.Content to load your game content here
            spriteFont = Content.Load<SpriteFont>("SpriteFont1");
            menuFont = Content.Load<SpriteFont>("MenuFont");
            playerTexture = Content.Load<Texture2D>("bee");
            hiveTexture = Content.Load<Texture2D>("hive");
            //change stinger and enemy textures once we have texture for them
            stingerTexture = Content.Load<Texture2D>("Stinger");
            enemyStinger = Content.Load<Texture2D>("StingerEnemy");
            //enemyTexture = Content.Load<Texture2D>("bee");
            enemyTexture = Content.Load<Texture2D>("EnemyPlaceHolder");
            waspTexture = Content.Load<Texture2D>("wasp");
            yellowjacketTexture = Content.Load<Texture2D>("yellowjacket");
            player = new Player(playerTexture, 200, 800, width, height);
            //hive = new Hive(hiveTexture, 100, width, height);
            hive = new Hive(hiveTexture, width, height);
            enemy = new Wasp(enemyTexture, 100, 100, width, height, Color.Green, 1);

            //healthbars
            healthBar = Content.Load<Texture2D>("Green");
            healthBarBg = Content.Load<Texture2D>("Black");

            //powerups
            powerupTexture1 = Content.Load<Texture2D>("placeholder");
            powerupTexture2 = Content.Load<Texture2D>("dmgUp");
            powerupTexture3 = Content.Load<Texture2D>("clock");

            //UI
            Menu = Content.Load<Texture2D>("MenuNew");
            buttonStart = Content.Load<Texture2D>("ButtonNew");
            GameOver = Content.Load<Texture2D>("MenuNew");
            buttonGameOverMainMenu = Content.Load<Texture2D>("ButtonNew");
            buttonPlayAgain = Content.Load<Texture2D>("ButtonNew");
            Win = Content.Load<Texture2D>("MenuNew");

        }

        /// <summary>
        /// UnloadContent will be called once per game and is the place to unload
        /// game-specific content.
        /// </summary>
        protected override void UnloadContent()
        {
            // TODO: Unload any non ContentManager content here
        }

        /// <summary>
        /// Allows the game to run logic such as updating the world,
        /// checking for collisions, gathering input, and playing audio.
        /// </summary>
        /// <param name="gameTime">Provides a snapshot of timing values.</param>
        protected override void Update(GameTime gameTime)
        {
            if (GamePad.GetState(PlayerIndex.One).Buttons.Back == ButtonState.Pressed || Keyboard.GetState().IsKeyDown(Keys.Escape))
                Exit();

            //updates states for player input checks
            prevMState = mState;
            prevKbState = kbState;
            mState = Mouse.GetState();
            kbState = Keyboard.GetState();

            //update timer


            #region states
            switch (gameState)
            {
                #region Menu State
                case GameState.Menu:
                    if (buttonStartLoc.Contains(mState.Position))
                    {
                        if (prevMState.LeftButton == ButtonState.Pressed)
                        {
                            buttonStartColor = Color.DarkCyan;

                            if (mState.LeftButton == ButtonState.Released)
                            {
                                ResetLevel();
                                gameState = GameState.Game;
                            }
                        }
                        else
                        {
                            buttonStartColor = Color.DarkCyan;
                        }
                    }
                    else
                    {
                        buttonStartColor = Color.White;
                    }
                    break;
                #endregion
                #region Pause
                case GameState.Pause:
                    //if the menu button is pressed, the gamestate will update to menu
                    if (buttonGameOverMenuMainLoc.Contains(mState.Position))
                    {
                        if (prevMState.LeftButton == ButtonState.Pressed)
                        {
                            buttonMenuColor = Color.White;

                            if (mState.LeftButton == ButtonState.Released)
                            {
                                gameState = GameState.Menu;
                            }
                        }
                        else
                        {
                            buttonMenuColor = Color.DarkCyan;
                        }
                    }
                    else
                    {
                        buttonMenuColor = Color.White;
                    }
                    //If the play again button is pressed, the gamestate will update to game
                    if (buttonPlayAgainLoc.Contains(mState.Position))
                    {
                        if (prevMState.LeftButton == ButtonState.Pressed)
                        {
                            buttonPlayAgainColor = Color.White;

                            if (mState.LeftButton == ButtonState.Released)
                            {
                                ResetLevel();
                                gameState = GameState.Game;
                            }
                        }
                        else
                        {
                            buttonPlayAgainColor = Color.DarkCyan;
                        }
                    }
                    else
                    {
                        buttonPlayAgainColor = Color.White;
                    }
                    break;
                #endregion
                #region Game State
                case GameState.Game:
                    //save health in old health before it's updated in any way
                    hiveOldHealth = hive.Health;


                    player.Update(gameTime);

                    //Pauses game
                    if (SingleKeyPress(Keys.P))
                    {
                        gameState = GameState.Pause;
                    }

                    //Player projectile management
                    //while specialshots are active for player, bullets will be added 2 at a time
                    if (SingleKeyPress(Keys.Space) && player.SpecialShots == true)
                    {
                        Projectile spec1 = new Projectile(stingerTexture, player.X, player.Y, -9, player.Damage);
                        spec1.Special = true;
                        Projectile spec2 = new Projectile(stingerTexture, player.X, player.Y, -9, player.Damage);
                        spec2.Special = true;

                        player.Stingers.Add(spec1);
                        player.Stingers.Add(spec2);

                        poweredShot++;

                    }

                    else if (SingleKeyPress(Keys.Space))
                    {
                        player.Stingers.Add(new Projectile(stingerTexture, player.X, player.Y, -9, player.Damage));

                    }
                    //only 5 powershots allowed at a time
                    //implication: before you use up all 5 special bullets, you won't get any additional ones
                    //even if you get another bullet powerup
                    if (poweredShot >= 5)
                    {
                        player.SpecialShots = false;
                        poweredShot = 0;
                    }

                    if (player.Stingers.Count != 0)
                    {
                        for (int i = 0; i < player.Stingers.Count; i++)
                        {
                            if (player.Stingers[i] != null)
                            {
                                //for special bullets, one is shot to left one is shot to right
                                if (player.Stingers[i].Special == true)
                                {
                                    if (i % 2 == 0) { player.Stingers[i].UpdateSpecialLeft(player, gameTime); }
                                    if (i % 2 == 1) { player.Stingers[i].UpdateSpecialRight(player, gameTime); }
                                }
                                else { player.Stingers[i].Update(player, gameTime); }

                                for (int j = 0; j < enemies.Count; j++)
                                {
                                    //Collision with list of enemies
                                    player.Stingers[i].CheckCollision(enemies[j]);
                                }
                                for (int j = 0; j < stingers.Count; j++)
                                {
                                    if (stingers[j] != null)
                                    {
                                        player.Stingers[i].CheckCollision(stingers[j]);
                                    }
                                }
                                if (player.Stingers[i].Y <= 0 || player.Stingers[i].IsDead == true)
                                {
                                    player.Stingers.Remove(player.Stingers[i]);
                                }
                            }
                        }

                    }
                    //Enemy projectile management
                    if (stingers.Count != 0)
                    {
                        for (int i = 0; i < stingers.Count; i++)
                        {
                            if (stingers[i] != null)
                            {
                                { stingers[i].Update(player, gameTime); }
                                stingers[i].CheckCollision(hive);

                                if (stingers[i].Y >= height || stingers[i].IsDead == true)
                                {
                                    stingers.Remove(stingers[i]);
                                }
                            }
                        }
                    }

                    //Updates list of enemies
                    deadEnemies = 0;
                    for (int i = 0; i < enemies.Count; i++)
                    {
                        //Checks if enemy is dead, then updates it
                        if (enemies[i] != null)
                        {
                            enemies[i].CheckCollision(hive);
                            enemies[i].Update(gameTime, stingers);
                            if (enemies[i].IsDead == true)
                            {
                                enemies[i] = null;


                            }
                            hive.Update(gameTime);

                            if (hive.IsDead == true)
                            {
                                gameState = GameState.GameOver;
                            }
                        }
                        else
                        {
                            deadEnemies += 1;
                        }
                    }
                    //Checks if all other waves have been cleared yet
                    if (deadEnemies == enemies.Count && currentWave == 3)
                    {
                        gameState = GameState.Win;
                    }
                    //Otherwise load the next wave
                    else if (deadEnemies == enemies.Count && currentWave < 3)
                    {
                        currentWave++;
                        LoadWave($"wave{currentWave}");
                    }


                    //update powerups
                    if (powerups.Count == 0)
                    {
                        //randomly decides type of powerup
                        int randNum = rng.Next(3);
                        if (randNum == 0)
                        {

                            powerups.Add(new Powerup(Type.health, powerupTexture1, rng.Next(0, GraphicsDevice.Viewport.Width - 150), 5));
                        }
                        else if (randNum == 1)
                        {
                            powerups.Add(new Powerup(Type.time, powerupTexture3, rng.Next(0, GraphicsDevice.Viewport.Width - 150), 5));
                        }
                        else
                        {
                            powerups.Add(new Powerup(Type.bullet, powerupTexture2, rng.Next(0, GraphicsDevice.Viewport.Width - 150), 5));
                        }
                    }

                    for (int i = 0; i < powerups.Count; i++)
                    {
                        powerups[i].Update(gameTime);
                        powerups[i].CheckCollision(player, hive);
                        if (powerups[i].Y >= GraphicsDevice.Viewport.Height)
                        {
                            powerups[i].Active = false;
                        }
                        if (powerups[i].Active == false)
                        {
                            powerups.RemoveAt(0);
                        }


                    }
                    //update what color the hive should be
                    if (hiveOldHealth > hive.Health)
                    {
                        hit = true;
                    }
                    if (hit == true && delay > 0)
                    {
                        hit = true;
                        delay = delay - 1;
                    }
                    else
                    {
                        hit = false;
                        delay = 5;
                    }
                    //update health bar here
                    //max health width is 400
                    healthBarRec.Width = Convert.ToInt32((Convert.ToDouble(((Convert.ToDouble(hive.Health)) / maxHiveHealth) * (Convert.ToDouble(400)))));
                    // TODO: Add your update logic here

                    //gets keyboard input from the user and updates game state
                    kbState = Keyboard.GetState();
                    break;
                #endregion
                #region Gameover State
                case GameState.GameOver:
                    //if the menu button is pressed, the gamestate will update to menu
                    if (buttonGameOverMenuMainLoc.Contains(mState.Position))
                    {
                        if (prevMState.LeftButton == ButtonState.Pressed)
                        {
                            buttonMenuColor = Color.DarkGray;

                            if (mState.LeftButton == ButtonState.Released)
                            {
                                gameState = GameState.Menu;
                            }
                        }
                        else
                        {
                            buttonMenuColor = Color.DarkCyan;
                        }
                    }
                    else
                    {
                        buttonMenuColor = Color.White;
                    }
                    //If the play again button is pressed, the gamestate will update to game
                    if (buttonPlayAgainLoc.Contains(mState.Position))
                    {
                        if (prevMState.LeftButton == ButtonState.Pressed)
                        {
                            buttonPlayAgainColor = Color.DarkGray;

                            if (mState.LeftButton == ButtonState.Released)
                            {
                                ResetLevel();
                                gameState = GameState.Game;
                            }
                        }
                        else
                        {
                            buttonPlayAgainColor = Color.DarkCyan;
                        }
                    }
                    else
                    {
                        buttonPlayAgainColor = Color.White;
                    }
                    break;
                #endregion
                #region Win State
                case GameState.Win:
                    //if the menu button is pressed, the gamestate will update to menu
                    if (buttonGameOverMenuMainLoc.Contains(mState.Position))
                    {
                        if (prevMState.LeftButton == ButtonState.Pressed)
                        {
                            buttonMenuColor = Color.DarkGray;

                            if (mState.LeftButton == ButtonState.Released)
                            {
                                gameState = GameState.Menu;
                            }
                        }
                        else
                        {
                            buttonMenuColor = Color.DarkCyan;
                        }
                    }
                    else
                    {
                        buttonMenuColor = Color.White;
                    }
                    //If the play again button is pressed, the gamestate will update to game
                    if (buttonPlayAgainLoc.Contains(mState.Position))
                    {
                        if (prevMState.LeftButton == ButtonState.Pressed)
                        {
                            buttonPlayAgainColor = Color.DarkGray;

                            if (mState.LeftButton == ButtonState.Released)
                            {
                                ResetLevel();
                                gameState = GameState.Game;
                            }
                        }
                        else
                        {
                            buttonPlayAgainColor = Color.DarkCyan;
                        }
                    }
                    else
                    {
                        buttonPlayAgainColor = Color.White;
                    }
                    break;
                    #endregion
            }
            base.Update(gameTime);
            #endregion
        }

        /// <summary>
        /// This is called when the game should draw itself.
        /// </summary>
        /// <param name="gameTime">Provides a snapshot of timing values.</param>
        protected override void Draw(GameTime gameTime)
        {
            GraphicsDevice.Clear(Color.CornflowerBlue);
            spriteBatch.Begin();



            switch (gameState)
            {
                #region Draw Menu State
                case GameState.Menu:
                    // TODO: GET MENU GRAPHICS
                    IsMouseVisible = true;
                    spriteBatch.Draw(Menu, MenuLoc, Color.White);
                    spriteBatch.Draw(buttonStart, buttonStartLoc, buttonStartColor);
                    spriteBatch.DrawString(menuFont, "Bee Game", new Vector2(width / 2 - (width / 8) + buttonStartLoc.Width / 3 - 70, height / 7), Color.Purple);
                    spriteBatch.DrawString(spriteFont, "Click here to start!", new Vector2(width / 2 - (width / 8) + buttonStartLoc.Width / 3, height / 4 + buttonStartLoc.Height / 2), Color.Purple);
                    break;
                #endregion
                #region Draw GameOver
                case GameState.GameOver:
                    IsMouseVisible = true;
                    // TODO: GET GAME OVER SCREEN GRAPHICS

                    spriteBatch.Draw(GameOver, GameOverLoc, Color.White);
                    spriteBatch.Draw(buttonGameOverMainMenu, buttonGameOverMenuMainLoc, buttonMenuColor);
                    spriteBatch.Draw(buttonPlayAgain, buttonPlayAgainLoc, buttonPlayAgainColor);
                    spriteBatch.DrawString(menuFont, "Game Over", new Vector2(width / 2 - (width / 8) + buttonStartLoc.Width / 3 - 70, height / 7), Color.Purple);
                    spriteBatch.DrawString(spriteFont, "Return to Main Menu", new Vector2(width / 2 - (width / 8) + 2 * buttonGameOverMenuMainLoc.Width / 7, 5 * height / 7 + buttonGameOverMenuMainLoc.Height / 2), Color.Purple);
                    spriteBatch.DrawString(spriteFont, "Play Again", new Vector2(width / 2 - (width / 8) + buttonStartLoc.Width / 3, height / 2 + buttonStartLoc.Height / 2), Color.Purple);
                    break;
                #endregion
                #region Draw Win
                case GameState.Win:
                    IsMouseVisible = true;
                    // TODO: GET GAME WIN SCREEN GRAPHICS

                    spriteBatch.Draw(Win, WinLoc, Color.White);
                    spriteBatch.Draw(buttonGameOverMainMenu, buttonGameOverMenuMainLoc, Color.White);
                    spriteBatch.Draw(buttonPlayAgain, buttonPlayAgainLoc, buttonPlayAgainColor);
                    spriteBatch.DrawString(menuFont, "You Win!", new Vector2(width / 2 - (width / 8) + buttonStartLoc.Width / 3 - 70, height / 7), Color.Purple);
                    spriteBatch.DrawString(spriteFont, "Return to Main Menu", new Vector2(width / 2 - (width / 8) + 2 * buttonGameOverMenuMainLoc.Width / 7, 5 * height / 7 + buttonGameOverMenuMainLoc.Height / 2), Color.Purple);
                    spriteBatch.DrawString(spriteFont, "Play Again", new Vector2(width / 2 - (width / 8) + buttonStartLoc.Width / 3, height / 2 + buttonStartLoc.Height / 2), Color.Purple);
                    break;
                #endregion
                #region Draw Pause
                case GameState.Pause:
                    spriteBatch.Draw(Menu, MenuLoc, Color.White);
                    spriteBatch.DrawString(menuFont, "Game Paused", new Vector2(width / 2 - (width / 8) + buttonStartLoc.Width / 3 - 70, height / 7), Color.Purple);
                    spriteBatch.Draw(buttonGameOverMainMenu, buttonGameOverMenuMainLoc, buttonMenuColor);
                    spriteBatch.Draw(buttonPlayAgain, buttonPlayAgainLoc, buttonPlayAgainColor);
                    spriteBatch.DrawString(spriteFont, "Return to Main Menu", new Vector2(width / 2 - (width / 8) + 2 * buttonGameOverMenuMainLoc.Width / 7, 5 * height / 7 + buttonGameOverMenuMainLoc.Height / 2), Color.Purple);
                    spriteBatch.DrawString(spriteFont, "Continue", new Vector2(width / 2 - (width / 8) + buttonStartLoc.Width / 3, height / 2 + buttonStartLoc.Height / 2), Color.Purple);
                    break;
                #endregion
                #region Draw Game
                case GameState.Game:
                    //update timer
                    var timer = (float)gameTime.ElapsedGameTime.TotalSeconds;
                    spriteBatch.Draw(player.Texture, player.Rect, Color.White);
                    //draws player Projectiles-Max
                    if (player.Stingers.Count != 0)
                    {
                        for (int i = 0; i < player.Stingers.Count; i++)
                        {
                            if (player.Stingers[i] != null)
                            {
                                spriteBatch.Draw(player.Stingers[i].Texture, player.Stingers[i].Rect, Color.Red);
                            }
                        }
                    }

                    //draws projectiles
                    if (stingers.Count != 0)
                    {
                        for (int i = 0; i < stingers.Count; i++)
                        {
                            if (stingers[i] != null)
                            {
                                spriteBatch.Draw(enemyStinger, stingers[i].Rect, Color.Red);
                            }

                        }
                    }

                    //if health was previously higher (aka hive was hit), flash red

                    //if(hiveOldHealth>hive.Health)
                    if (hit == true)
                    {
                        spriteBatch.Draw(hive.Texture, hive.Rect, Color.Red);
                    }
                    else
                    {
                        spriteBatch.Draw(hive.Texture, hive.Rect, Color.White);
                    }

                    //Draws list of enemies
                    for (int i = 0; i < enemies.Count; i++)
                    {
                        if (enemies[i] != null)
                        {
                            spriteBatch.Draw(enemies[i].Texture, enemies[i].Rect, enemies[i].Color);
                        }
                    }

                    spriteBatch.DrawString(spriteFont, "Test", new Vector2(0, 0), Color.White);
                    //draws powerups
                    for (int i = 0; i < powerups.Count; i++)
                    {
                        if (powerups[i].Active == true)
                        {
                            spriteBatch.Draw(powerups[i].Texture, powerups[i].Rect, Color.White);
                        }
                    }

                    //draws healthbar
                    spriteBatch.Draw(healthBarBg, healthBarBgRec, Color.White);
                    spriteBatch.Draw(healthBar, healthBarRec, Color.White);
                    #endregion
                    break;
            }

            spriteBatch.End();
            base.Draw(gameTime);
        }

        //checks for key presses
        public bool SingleKeyPress(Keys key)
        {
            bool r = false;
            kbState = Keyboard.GetState();
            if (kbState.IsKeyDown(key) == true && prevKbState.IsKeyDown(key) == false)
            {
                r = true;
            }
            else
            {
                r = false;
            }
            return r;
        }

        //Resets level
        public void ResetLevel()
        {
            player = new Player(playerTexture, 200, height - (player.Rect.Height * 3), width, height);
            enemies.Clear();
            stingers.Clear();
            powerups.Clear();
            currentWave = 1;
            LoadWave($"wave{currentWave}");
            hive.Health = enemies.Count;
            maxHiveHealth = hive.Health;
            hive.IsDead = false;
        }

        //Load a wave
        public void LoadWave(string file)
        {
            using (StreamReader reader = new StreamReader($"..\\..\\..\\..\\waves\\{file}.txt"))
            {
                string line;

                while ((line = reader.ReadLine()) != null)
                {
                    if (line == "")
                    {
                        continue;
                    }

                    try
                    {
                        //Store the line data
                        string[] lineData = line.Split(',');
                        switch (lineData[1])
                        {
                            case "wasp":
                                enemies.Add(new Wasp(waspTexture, int.Parse(lineData[3]), int.Parse(lineData[4]), width, height, Color.White, int.Parse(lineData[6])));
                                break;
                            case "yellowjacket":
                                enemies.Add(new Yellowjacket(yellowjacketTexture, int.Parse(lineData[3]), int.Parse(lineData[4]), height, Color.White, int.Parse(lineData[6])));
                                break;
                            case "base":
                            default:
                                enemies.Add(new Enemy(enemyTexture, int.Parse(lineData[3]), int.Parse(lineData[4]), height, Color.White, int.Parse(lineData[6])));
                                break;
                        }
                    }
                    catch (IOException)
                    {
                        continue;
                    }
                }
            }
        }
    }
}

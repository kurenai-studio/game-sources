using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Audio;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using Snake.Core.Common;
using Snake.Core.Events;
using Snake.Core.Graphics;
using Snake.Core.Inputs;
using Snake.Core.Localization;
using Snake.Core.Managers;
using Snake.Core.Settings;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;

namespace Snake.Core.Screens
{
    /// <summary>
    /// The main gameplay screen where the snake game is played.
    /// </summary>
    public class GameplayScreen : GameScreen
    {
        /// <summary>
        /// The pause alpha increment.
        /// </summary>
        private const float PauseAlphaIncrement = 1f / 32f;

        /// <summary>
        /// The pause alpha max.
        /// </summary>
        private const float PauseAlphaMax = 1f;

        /// <summary>
        /// The pause alpha min.
        /// </summary>
        private const float PauseAlphaMin = 0f;

        /// <summary>
        /// The fade lerp factor.
        /// </summary>
        private const float FadeLerpFactor = 0.5f;

        /// <summary>
        /// The sprite scale.
        /// </summary>
        private const float SpriteScale = 4.0f;


        /// <summary>
        /// The padding offset.
        /// </summary>
        private const int PaddingOffset = 8;

        /// <summary>
        /// The texture atlas path.
        /// </summary>
        private readonly string TextureAtlasPath = Path.Combine("Textures", "snake-definition.xml");

        /// <summary>
        /// The content manager.
        /// </summary>
        private ContentManager contentManager;

        /// <summary>
        /// The pause alpha.
        /// </summary>
        private float pauseAlpha;

        /// <summary>
        /// The tilemap manager.
        /// </summary>
        private TilemapManager tilemapManager;

        /// <summary>
        /// The collision manager.
        /// </summary>
        private CollisionManager collisionManager;

        /// <summary>
        /// The particle manager.
        /// </summary>
        private ParticleManager particleManager;

        /// <summary>
        /// The leaderboard manager.
        /// </summary>
        private LeaderboardManager<Leaderboard> leaderboardManager;

        /// <summary>
        /// The texture atlas.
        /// </summary>
        private TextureAtlas textureAtlas;

        /// <summary>
        /// The snake.
        /// </summary>
        private Graphics.Snake snake;

        /// <summary>
        /// The food.
        /// </summary>
        private Food food;

        /// <summary>
        /// The game over.
        /// </summary>
        private bool gameOver;

        /// <summary>
        /// The current points.
        /// </summary>
        private int currentPoints;

        /// <summary>
        /// The points text.
        /// </summary>
        private readonly Text pointsText;

        /// <summary>
        /// The random number generator for shake.
        /// </summary>
        private readonly Random random = new Random();

        /// <summary>
        /// The current shake offset.
        /// </summary>
        private Vector2 shakeOffset;

        /// <summary>
        /// The remaining shake duration.
        /// </summary>
        private float shakeDuration;

        /// <summary>
        /// The shake intensity in pixels.
        /// </summary>
        private const float ShakeIntensity = 15f;

        /// <summary>
        /// The shake duration in seconds.
        /// </summary>
        private const float ShakeDuration = 0.25f;

        /// <summary>
        /// The vibration duration in seconds.
        /// </summary>
        private const float VibrationDuration = 0.2f;

        /// <summary>
        /// The vibration timer.
        /// </summary>
        private float vibrationTimer;

        /// <summary>
        /// The power up music.
        /// </summary>
        private Music<SoundEffect> powerUpMusic;

        /// <summary>
        /// The power up music path.
        /// </summary>
        private readonly string powerUpMusicPath = Path.Combine("Audios", "power-up-sound");

        /// <summary>
        /// The hurt music.
        /// </summary>
        private Music<SoundEffect> hurtMusic;

        /// <summary>
        /// The hurt music path.
        /// </summary>
        private readonly string hurtMusicPath = Path.Combine("Audios", "hurt-sound");

        /// <summary>
        /// The game over music.
        /// </summary>
        private Music<SoundEffect> gameoverMusic;

        /// <summary>
        /// The game over music path.
        /// </summary>
        private readonly string gameoverMusicPath = Path.Combine("Audios", "gameover-sound");

        /// <summary>
        /// Initializes a new instance of the GameplayScreen class.
        /// </summary>
        /// <summary>
        /// Initializes a new instance of the GameplayScreen class.
        /// </summary>
        public GameplayScreen()
        {
            pointsText = new Text(Resources.PointsText);

            if (IsSoundEffectsEnabled())
            {
                powerUpMusic = new Music<SoundEffect>(powerUpMusicPath, false);
                hurtMusic = new Music<SoundEffect>(hurtMusicPath, false);
                gameoverMusic = new Music<SoundEffect>(gameoverMusicPath, false);
            }

            TransitionOnTime = TimeSpan.FromSeconds(DefaultTransitionTime);
            TransitionOffTime = TimeSpan.FromSeconds(DefaultTransitionTime);
        }

        /// <summary>
        /// Starts the camera shake effect.
        /// </summary>
        private void StartCameraShake()
        {
            shakeDuration = ShakeDuration;
            shakeOffset = Vector2.Zero;
        }

        /// <summary>
        /// Updates the camera shake effect.
        /// </summary>
        /// <param name="gameTime">The game time.</param>
        private void UpdateCameraShake(GameTime gameTime)
        {
            if (shakeDuration > 0)
            {
                float deltaTime = (float)gameTime.ElapsedGameTime.TotalSeconds;
                shakeDuration -= deltaTime;

                if (shakeDuration > 0)
                {
                    // Generate random shake offset that decreases over time
                    float progress = shakeDuration / ShakeDuration;
                    float shakeAmount = ShakeIntensity * progress;
                    shakeOffset = new Vector2(
                        (float)(random.NextDouble() * 2 - 1) * shakeAmount,
                        (float)(random.NextDouble() * 2 - 1) * shakeAmount
                    );
                }
                else
                {
                    shakeOffset = Vector2.Zero;
                    shakeDuration = 0;
                }
            }
        }

        /// <summary>
        /// Starts the vibration effect.
        /// </summary>
        private void StartVibration()
        {
            vibrationTimer = VibrationDuration;
            GamePad.SetVibration(PlayerIndex.One, 0.7f, 0.7f);
        }

        /// <summary>
        /// Loads the content for the gameplay screen.
        /// </summary>
        public override void LoadContent()
        {
            base.LoadContent();

            contentManager ??= new ContentManager(ScreenManager.Game.Services, "Content");

            if (IsSoundEffectsEnabled())
            {
                powerUpMusic.LoadContent(contentManager);
                hurtMusic.LoadContent(contentManager);
                gameoverMusic.LoadContent(contentManager);
            }

            tilemapManager = new TilemapManager();
            tilemapManager.LoadContent(contentManager);

            collisionManager = new CollisionManager();

            particleManager = new ParticleManager(ScreenManager.GraphicsDevice);

            leaderboardManager = ScreenManager.Game.Services.GetService<LeaderboardManager<Leaderboard>>();

            textureAtlas = TextureAtlas.FromFile(contentManager, TextureAtlasPath);
            Tilemap tilemap = tilemapManager.GetTilemap();

            AnimatedSprite snakeHeadUpSprite = textureAtlas.CreateAnimatedSprite("snake-head-up-animation");
            AnimatedSprite snakeHeadDownSprite = textureAtlas.CreateAnimatedSprite("snake-head-down-animation");
            AnimatedSprite snakeHeadLeftSprite = textureAtlas.CreateAnimatedSprite("snake-head-left-animation");
            AnimatedSprite snakeHeadRightSprite = textureAtlas.CreateAnimatedSprite("snake-head-right-animation");
            AnimatedSprite snakeBodySprite = textureAtlas.CreateAnimatedSprite("snake-body-animation");
            snakeHeadUpSprite.Scale = new Vector2(4.0f, 4.0f);
            snakeHeadDownSprite.Scale = new Vector2(4.0f, 4.0f);
            snakeHeadLeftSprite.Scale = new Vector2(4.0f, 4.0f);
            snakeHeadRightSprite.Scale = new Vector2(4.0f, 4.0f);
            snakeBodySprite.Scale = new Vector2(4.0f, 4.0f);
            snake = new Graphics.Snake(
                snakeHeadUpSprite, 
                snakeHeadDownSprite, 
                snakeHeadLeftSprite, 
                snakeHeadRightSprite,
                snakeBodySprite, 
                tilemap
            );

            AnimatedSprite redAppleSprite = textureAtlas.CreateAnimatedSprite("redApple-animation");
            AnimatedSprite goldenAppleSprite = textureAtlas.CreateAnimatedSprite("goldenApple-animation");
            AnimatedSprite redCherrySprite = textureAtlas.CreateAnimatedSprite("redCherry-animation");
            AnimatedSprite brownCookieSprite = textureAtlas.CreateAnimatedSprite("brownCookie-animation");
            AnimatedSprite greenAppleSprite = textureAtlas.CreateAnimatedSprite("greenApple-animation");
            
            Vector2 spriteScale = new Vector2(SpriteScale, SpriteScale);
            redAppleSprite.Scale = spriteScale;
            goldenAppleSprite.Scale = spriteScale;
            redCherrySprite.Scale = spriteScale;
            brownCookieSprite.Scale = spriteScale;
            greenAppleSprite.Scale = spriteScale;
            
            List<FoodType> foodTypes = new List<FoodType>
            {
                new FoodType(redAppleSprite, 5),
                new FoodType(goldenAppleSprite, 5),
                new FoodType(redCherrySprite, 15),
                new FoodType(brownCookieSprite, 10),
                new FoodType(greenAppleSprite, 5)
            };
            
            food = new Food(foodTypes, tilemap);

            ScreenManager.Game.ResetElapsedTime();
        }

        public override void UnloadContent()
        {
            // Stop vibration when unloading
            GamePad.SetVibration(PlayerIndex.One, 0f, 0f);
            contentManager.Unload();
        }

        public override void Update(GameTime gameTime, bool otherScreenHasFocus, bool coveredByOtherScreen)
        {
            base.Update(gameTime, otherScreenHasFocus, false);

            if (coveredByOtherScreen)
                pauseAlpha = Math.Min(pauseAlpha + PauseAlphaIncrement, PauseAlphaMax);
            else
                pauseAlpha = Math.Max(pauseAlpha - PauseAlphaIncrement, PauseAlphaMin);

            // Update camera shake even when not active (for visual feedback)
            UpdateCameraShake(gameTime);

            if (IsActive)
            {
                snake.Update(gameTime);

                food.Update(gameTime);

                particleManager.Update(gameTime);

                // Update camera shake
                UpdateCameraShake(gameTime);

                // Update vibration
                if (vibrationTimer > 0)
                {
                    float deltaTime = (float)gameTime.ElapsedGameTime.TotalSeconds;
                    vibrationTimer -= deltaTime;

                    if (vibrationTimer <= 0)
                    {
                        GamePad.SetVibration(PlayerIndex.One, 0f, 0f);
                        vibrationTimer = 0;
                    }
                }

                Tilemap tilemap = tilemapManager.GetTilemap();
                if (collisionManager.IsSnakeCollideWithWall(snake, tilemap) && !gameOver)
                {
                    if (IsSoundEffectsEnabled()) 
                    {
                        hurtMusic.Play();
                        gameoverMusic.Play();
                    }
                    
                    StartCameraShake();
                    
                    StartVibration();

                    // Add score to leaderboard
                    leaderboardManager?.AddScore(currentPoints);

                    gameOver = true;
                    string message = Resources.GameOverText;
                    string totalPointsSubMessage = $"{Resources.TotalScoreMenuText} {currentPoints}";

                    MessageBoxScreen confirmExitMessageBox = new MessageBoxScreen(
                        message, 
                        totalPointsSubMessage,
                        true, 
                        new Dictionary<string, EventHandler<PlayerIndexEventArgs>>()
                        {
                            { Resources.StartAgainMenuText, ConfirmStartAgainMessageBoxAccepted },
                            { Resources.ExitMenuText, ConfirmExitMessageBoxAccepted }
                        });
                    confirmExitMessageBox.Accepted += ConfirmStartAgainMessageBoxAccepted;
                    confirmExitMessageBox.Cancelled += ConfirmExitMessageBoxAccepted;

                    ScreenManager.AddScreen(confirmExitMessageBox, null);
                }

                if (collisionManager.IsSnakeCollideWithFood(snake, food))
                {
                    particleManager.Spawn(25, food.GetPosition());

                    if (snake.Grow())
                    {
                        if (IsSoundEffectsEnabled())
                            powerUpMusic.Play();
                     
                        currentPoints += food.GetPoints();

                        food.Reposition(tilemap, snake);
                    }
                }

                if (snake.HasSelfCollidedThisMove && snake.BodySegments.Count > 0)
                {
                    if (snake.Shrink())
                    {
                        if (IsSoundEffectsEnabled())
                            hurtMusic.Play();

                        StartCameraShake();

                        StartVibration();

                        currentPoints -= 5;// food.GetPoints();

                        particleManager.Spawn(25, snake.BodySegments.Last().At);
                    }
                }
            }
        }

        private void ConfirmStartAgainMessageBoxAccepted(object sender, PlayerIndexEventArgs e)
        {
            ExitScreen();
            ScreenManager.AddScreen(new GameplayScreen(), null);
        }

        private void ConfirmExitMessageBoxAccepted(object sender, PlayerIndexEventArgs e)
        {
            ExitScreen();
            ScreenManager.AddScreen(new BackgroundScreen(), null);
            ScreenManager.AddScreen(new MainMenuScreen(), null);
        }

        public override void HandleInput(GameTime gameTime, InputState inputState)
        {
            ArgumentNullException.ThrowIfNull(inputState);

            if (gameOver)
            {
                return;
            }

            base.HandleInput(gameTime, inputState);

            snake.HandleInput(inputState);

            if ((inputState.IsPauseGame(ControllingPlayer, null)))
            {
                ScreenManager.AddScreen(new PauseScreen(), ControllingPlayer);
            }
        }

        public override void Draw(GameTime gameTime)
        {
            ScreenManager.GraphicsDevice.Clear(ClearOptions.Target, Color.Black, 0, 0);
            
            GraphicsDevice graphicsDevice = ScreenManager.GraphicsDevice;
            SpriteBatch spriteBatch = ScreenManager.SpriteBatch;
            SpriteFont font = ScreenManager.Font;

            // Apply camera shake to transformation (shake in screen space, after scaling)
            // Matrix multiplication order: apply scale first, then translation (shake)
            Matrix shakeTranslation = Matrix.CreateTranslation(shakeOffset.X, shakeOffset.Y, 0);
            Matrix finalTransformation = ScreenManager.GlobalTransformation * shakeTranslation;

            spriteBatch.Begin(SpriteSortMode.Deferred, BlendState.AlphaBlend, SamplerState.PointClamp, null, null, null, finalTransformation);

            tilemapManager.Draw(spriteBatch);

            snake.Draw(spriteBatch);

            food.Draw(spriteBatch);

            particleManager.Draw(spriteBatch);

            string pointsMessage = $"{Resources.PointsText} {currentPoints}";
            Vector2 textSize = font.MeasureString(pointsMessage);
            Tilemap tilemap = tilemapManager.GetTilemap();
            Vector2 position = Helper.GetTopLeftVector2(graphicsDevice, textSize, tilemap.TileWidth + PaddingOffset, tilemap.TileHeight + PaddingOffset);

            pointsText.SpriteFont = font;
            pointsText.TextString = pointsMessage;
            pointsText.Position = position;
            pointsText.Color = Color.White;
            pointsText.Scale = Vector2.One;
            pointsText.Origin = Vector2.Zero;
            pointsText.Draw(spriteBatch);

            spriteBatch.End();

            base.Draw(gameTime);

            if (TransitionPosition > 0 || pauseAlpha > 0)
            {
                float alpha = MathHelper.Lerp(1f - TransitionAlpha, 1f, pauseAlpha * FadeLerpFactor);
                ScreenManager.FadeBackBufferToBlack(alpha);
            }
        }

        /// <summary>
        /// Updates the sound effects state based on the sound effects enabled setting.
        /// </summary>
        private bool IsSoundEffectsEnabled()
        {
            return SnakeGame.SettingsManager.Settings.SoundEffectsEnabled;
        }
    }
}

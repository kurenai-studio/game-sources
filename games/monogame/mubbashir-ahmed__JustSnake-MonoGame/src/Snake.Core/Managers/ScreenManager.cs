using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input.Touch;
using Snake.Core.Enums;
using Snake.Core.Inputs;
using Snake.Core.Screens;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;

namespace Snake.Core.Managers
{
    /// <summary>
    /// Manages the screens in the game.
    /// </summary>
    public class ScreenManager : DrawableGameComponent
    {
        /// <summary>
        /// The list of screens in the game.
        /// </summary>
        private readonly List<GameScreen> screens = new List<GameScreen>();

        /// <summary>
        /// The list of screens to update.
        /// </summary>
        private readonly List<GameScreen> screensToUpdate = new List<GameScreen>();

        /// <summary>
        /// The input state for the game.
        /// </summary>
        private readonly InputState inputState = new InputState();
        
        /// <summary>
        /// The sprite batch for the game.
        /// </summary>
        private SpriteBatch spriteBatch;
        
        /// <summary>
        /// The font for the game.
        /// </summary>
        private SpriteFont font;

        /// <summary>
        /// The blank texture for the game.
        /// </summary>
        private Texture2D blankTexture;

        /// <summary>
        /// Indicates if the game is initialized.
        /// </summary>
        private bool isInitialized;

        /// <summary>
        /// The width of the backbuffer.
        /// </summary>
        public int BackbufferWidth { get; set; }

        /// <summary>
        /// The height of the backbuffer.
        /// </summary>
        public int BackbufferHeight { get; set; }

        /// <summary>
        /// The base screen size.
        /// </summary>
        public Vector2 BaseScreenSize { get; set; } = new Vector2(800, 480);

        /// <summary>
        /// The global transformation.
        /// </summary>
        public Matrix GlobalTransformation { get; set; }

        /// <summary>
        /// The sprite batch.
        /// </summary>
        public SpriteBatch SpriteBatch => spriteBatch;

        /// <summary>
        /// The font.
        /// </summary>
        public SpriteFont Font => font;

        /// <summary>
        /// The blank texture path.
        /// </summary>
        private readonly string BlankTexturePath = Path.Combine("Textures", "blank");

        /// <summary>
        /// The font path.
        /// </summary>
        private readonly string FontPath = Path.Combine("Fonts", "Hud");

        /// <summary>
        /// Initializes a new instance of the <see cref="ScreenManager"/> class.
        /// </summary>
        /// <param name="game">The game instance.</param>
        public ScreenManager(Game game) : base(game)
        {
            // Set the enabled gestures to none
            TouchPanel.EnabledGestures = GestureType.None;
        }

        /// <summary>
        /// Initializes the screen manager.
        /// </summary>
        public override void Initialize()
        {
            // Initialize the base
            base.Initialize();

            // Set the initialized flag to true
            isInitialized = true;
        }

        /// <summary>
        /// Loads the content for the screen manager.
        /// </summary>
        protected override void LoadContent()
        {
            // Get the content manager
            ContentManager content = Game.Content;

            // Create a new sprite batch
            spriteBatch = new SpriteBatch(GraphicsDevice);
            font = content.Load<SpriteFont>(FontPath);

            // Load the blank texture
            blankTexture = content.Load<Texture2D>(BlankTexturePath);

            // Loop through the screens
            foreach (GameScreen screen in screens)
            {
                screen.LoadContent();
            }
        }

        /// <summary>
        /// Unloads the content for the screen manager.
        /// </summary>
        protected override void UnloadContent()
        {
            // Loop through the screens
            foreach (GameScreen screen in screens)
            {
                // Unload the content for the screen
                screen.UnloadContent();
            }
        }

        /// <summary>
        /// Updates the screen manager.
        /// </summary>
        /// <param name="gameTime">The game time.</param>
        public override void Update(GameTime gameTime)
        {
            // Update the input state
            inputState.Update(gameTime, GraphicsDevice.Viewport);

            // Clear the screens to update
            screensToUpdate.Clear();

            // Add the screens to the screens to update
            screensToUpdate.AddRange(screens);

            // Check if the game is active
            bool otherScreenHasFocus = !Game.IsActive;
            bool coveredByOtherScreen = false;

            // Loop through the screens to update
            while (screensToUpdate.Count > 0)
            {
                // Get the last screen in the screens to update
                GameScreen screen = screensToUpdate[^1];

                // Remove the last screen from the screens to update
                screensToUpdate.RemoveAt(screensToUpdate.Count - 1);

                screen.Update(gameTime, otherScreenHasFocus, coveredByOtherScreen);

                // Check if the screen is transitioning on or active
                if (screen.ScreenState == ScreenState.TransitionOn || screen.ScreenState == ScreenState.Active)
                {
                    // Check if another screen has focus
                    if (!otherScreenHasFocus)
                    {
                        // Handle the input for the screen
                        screen.HandleInput(gameTime, inputState);

                        // Set the other screen has focus to true
                        otherScreenHasFocus = true;
                    }

                    // Check if the screen is not a popup
                    if (!screen.IsPopup)
                        coveredByOtherScreen = true;
                }
            }
        }

        /// <summary>
        /// Draws the screen manager.
        /// </summary>
        /// <param name="gameTime">The game time.</param>
        public override void Draw(GameTime gameTime)
        {
            // Loop through the screens
            foreach (var screen in screens)
            {
                // Check if the screen is not hidden
                if (screen.ScreenState != ScreenState.Hidden)
                {
                    // Draw the screen
                    screen.Draw(gameTime);
                }
            }
        }

        /// <summary>
        /// Disposes of the screen manager.
        /// </summary>
        /// <param name="disposing">True if the screen manager is being disposed, false otherwise.</param>
        protected override void Dispose(bool disposing)
        {
            // Try to dispose of the screen manager
            try
            {
                // Check if the screen manager is being disposed
                if (disposing)
                {
                    // Dispose of the sprite batch
                    spriteBatch?.Dispose();
                }
            }
            finally
            {
                // Dispose of the base
                base.Dispose(disposing);
            }
        }

        /// <summary>
        /// Adds a screen to the screen manager.
        /// </summary>
        /// <param name="screen">The screen to add.</param>
        /// <param name="controllingPlayer">The player index of the controlling player.</param>
        public void AddScreen(GameScreen screen, PlayerIndex? controllingPlayer)
        {
            // Set the controlling player for the screen
            screen.ControllingPlayer = controllingPlayer;

            // Set the screen manager for the screen
            screen.ScreenManager = this;

            // Set the is exiting flag for the screen
            screen.IsExiting = false;

            // Check if the screen manager is initialized
            if (isInitialized)
            {
                // Load the content for the screen
                screen.LoadContent();
            }

            // Add the screen to the screens
            screens.Add(screen);

            // Set the enabled gestures for the touch panel
            TouchPanel.EnabledGestures = screen.EnabledGestures;
        }

        /// <summary>
        /// Removes a screen from the screen manager.
        /// </summary>
        /// <param name="screen">The screen to remove.</param>
        public void RemoveScreen(GameScreen screen)
        {
            // Check if the screen manager is initialized
            if (isInitialized)
            {
                // Unload the content for the screen
                screen.UnloadContent();
            }

            // Remove the screen from the screens
            screens.Remove(screen);

            // Remove the screen from the screens to update
            screensToUpdate.Remove(screen);

            // Check if there are screens
            if (screens.Count > 0)
            {
                // Set the enabled gestures for the touch panel
                TouchPanel.EnabledGestures = screens[^1].EnabledGestures;
            }
        }

        /// <summary>
        /// Gets the screens in the screen manager.
        /// </summary>
        /// <returns>The screens in the screen manager.</returns>
        public GameScreen[] GetScreens()
        {
            // Return the screens in the screen manager
            return screens.ToArray();
        }

        /// <summary>
        /// Fades the back buffer to black.
        /// </summary>
        /// <param name="alpha">The alpha value.</param>
        public void FadeBackBufferToBlack(float alpha)
        {
            // Get the viewport
            Viewport viewport = GraphicsDevice.Viewport;

            // Begin the sprite batch
            spriteBatch.Begin(SpriteSortMode.Deferred, BlendState.AlphaBlend, SamplerState.PointClamp, null, null, null, GlobalTransformation);

            // Draw the blank texture
            spriteBatch.Draw(blankTexture,
                             new Rectangle(0, 0, viewport.Width, viewport.Height),
                             Color.Black * alpha);

            // End the sprite batch
            spriteBatch.End();
        }

        /// <summary>
        /// Scales the presentation area.
        /// </summary>
        public void ScalePresentationArea()
        {
            // Check if the graphics device is null or the base screen size is less than or equal to zero and throw an exception
            if (GraphicsDevice == null || BaseScreenSize.X <= 0 || BaseScreenSize.Y <= 0)
            {
                throw new InvalidOperationException("Invalid graphics configuration");
            }

            // Set the backbuffer width and height
            BackbufferWidth = GraphicsDevice.PresentationParameters.BackBufferWidth;
            BackbufferHeight = GraphicsDevice.PresentationParameters.BackBufferHeight;

            // Check if the backbuffer height or base screen size y is zero and return
            if (BackbufferHeight == 0 || BaseScreenSize.Y == 0)
            {
                return;
            }

            // Calculate the base aspect ratio and screen aspect ratio
            float baseAspectRatio = BaseScreenSize.X / BaseScreenSize.Y;
            float screenAspectRatio = BackbufferWidth / (float)BackbufferHeight;

            // Calculate the scaling factor
            float scalingFactor = screenAspectRatio > baseAspectRatio
                ? BackbufferHeight / BaseScreenSize.Y
                : BackbufferWidth / BaseScreenSize.X;

            // Set the global transformation
            GlobalTransformation = Matrix.CreateScale(scalingFactor);

            // Update the input transformation
            inputState.UpdateInputTransformation(Matrix.Invert(GlobalTransformation));
        }
    }
}

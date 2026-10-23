using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using System;

namespace Pong
{
    /// <summary>
    /// This is the main type for your game.
    /// </summary>
    public class Game1 : Game
    {
        GraphicsDeviceManager graphics;
        SpriteBatch spriteBatch;
        Ball ball;
        Paddle paddlel;
        Paddle paddler;
        KeyboardState key;


        public Game1()
        {
            graphics = new GraphicsDeviceManager(this);
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

            IsMouseVisible = true;
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
            ball = new Ball(Content.Load<Texture2D>("ball"));
            paddlel = new Paddle(new Vector2(17,100),Content.Load<Texture2D>("Paddle"));
            paddler = new Paddle(new Vector2(GraphicsDevice.Viewport.Width - 30,100),Content.Load<Texture2D>("Paddle"));

            // TODO: use this.Content to load your game content here
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
            key = Keyboard.GetState();

            if (Keyboard.GetState().IsKeyDown(Keys.Up))
            {
                paddler.MoveUp();
            }
          else if (Keyboard.GetState().IsKeyDown(Keys.Down))
            {
                paddler.MoveDown();
            }
            if (Keyboard.GetState().IsKeyDown(Keys.W))
            {
                paddlel.MoveUp();
            }
            else if (Keyboard.GetState().IsKeyDown(Keys.S))
            {
                paddlel.MoveDown();
            }

            ball.UpdateMovement(GraphicsDevice);
            paddlel.UpdateCollision(GraphicsDevice);
            paddler.UpdateCollision(GraphicsDevice);

            if (ball.Hitbox.Intersects(paddlel.Hitbox) || ball.Hitbox.Intersects(paddler.Hitbox))
            {
                ball.VelocityX = -ball.VelocityX;
                ball.VelocityY = -ball.VelocityY;
            }
      


            base.Update(gameTime);
        }

        /// <summary>
        /// This is called when the game should draw itself.
        /// </summary>
        /// <param name="gameTime">Provides a snapshot of timing values.</param>
        protected override void Draw(GameTime gameTime)
        {
            GraphicsDevice.Clear(Color.CornflowerBlue);
            spriteBatch.Begin();

            ball.Draw(spriteBatch);
            paddlel.Draw(spriteBatch);
            paddler.Draw(spriteBatch);
            spriteBatch.End();
            // TODO: Add your drawing code here

            base.Draw(gameTime);
        }
    }
}

// Copyright (c) Doug Swisher. All Rights Reserved.
// Licensed under the MIT License. See LICENSE in the project root for license information.

using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;

namespace Pong.Desktop;

public class Game1 : Game
{
    private SpriteFont font;
    private Paddle paddle1;
    private Paddle paddle2;
    private Ball ball;

    public Game1()
    {
        var graphics = new GraphicsDeviceManager(this);
        graphics.PreferredBackBufferWidth = Globals.Width;
        graphics.PreferredBackBufferHeight = Globals.Height;

        Content.RootDirectory = "Content";
        IsMouseVisible = true;
    }


    protected override void Initialize()
    {
        paddle1 = new Paddle(false);
        paddle2 = new Paddle(true);

        ball = new Ball();

        base.Initialize();
    }


    protected override void LoadContent()
    {
        Globals.SpriteBatch = new SpriteBatch(GraphicsDevice);

        Globals.Pixel = new Texture2D(GraphicsDevice, 1, 1);
        Globals.Pixel.SetData(new[] { Color.White });

        font = Content.Load<SpriteFont>("Score");
    }


    protected override void Update(GameTime gameTime)
    {
        if (Keyboard.GetState().IsKeyDown(Keys.Escape))
        {
            Exit();
        }

        paddle1.Update(gameTime);
        paddle2.Update(gameTime);

        ball.Update(gameTime, paddle1, paddle2);

        base.Update(gameTime);
    }


    protected override void Draw(GameTime gameTime)
    {
        GraphicsDevice.Clear(Color.Black);

        Globals.SpriteBatch.Begin();

        Globals.SpriteBatch.DrawString(font, Globals.Player1Score.ToString(), new Vector2(100, 50), Color.White);
        Globals.SpriteBatch.DrawString(font, Globals.Player2Score.ToString(), new Vector2(Globals.Width - 112, 50), Color.White);

        paddle1.Draw();
        paddle2.Draw();

        ball.Draw();

        Globals.SpriteBatch.End();

        base.Draw(gameTime);
    }
}

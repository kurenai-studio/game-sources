using Clong.Core.Domain.Const;
using Clong.Core.Domain.Enum;
using Clong.Kni.Adapter.Driven.Input;
using Clong.Kni.Adapter.Driven.Rendering;
using Clong.Kni.Adapter.Driven.Sound;
using Clong.Kni.Adapter.Driving;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Audio;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;

namespace Clong.Kni.Adapter;

public class MainGame : Game
{
    private readonly GraphicsDeviceManager _graphics;
    private SpriteBatch _spriteBatch;
    private GameController _gameController;

    public MainGame()
    {
        _graphics = new GraphicsDeviceManager(this);
        Content.RootDirectory = "Content";
        IsMouseVisible = true;
    }

    protected override void Initialize()
    {
        _graphics.IsFullScreen = false;
        _graphics.PreferMultiSampling = false;
        _graphics.PreferredBackBufferWidth = Resolution.DesignWidth;
        _graphics.PreferredBackBufferHeight = Resolution.DesignHeight;
        _graphics.SynchronizeWithVerticalRetrace = true;
        _graphics.ApplyChanges();

        base.Initialize();
    }

    protected override void LoadContent()
    {
        var font = Content.Load<SpriteFont>("Fonts/Font1");
        var textureMap = new TextureMap {
            [TextureId.Ball] = Content.Load<Texture2D>("Textures/ball"),
            [TextureId.PaddleL] = Content.Load<Texture2D>("Textures/paddle1"),
            [TextureId.PaddleR] = Content.Load<Texture2D>("Textures/paddle2"),
            [TextureId.Star] = Content.Load<Texture2D>("Textures/star")
        };
        var soundMap = new SoundMap {
            [SoundId.BallHitPaddle] = Content.Load<SoundEffect>("Sounds/blip01"),
            [SoundId.BallLeftPlayField] = Content.Load<SoundEffect>("Sounds/blip02"),
            [SoundId.BallHitWall] = Content.Load<SoundEffect>("Sounds/blip04")
        };

        _spriteBatch = new SpriteBatch(GraphicsDevice);
        _gameController = new GameController(
            new Core.Domain.Clong(
                new InputReader(),
                new Renderer(_spriteBatch, textureMap, font),
                new SoundEffectPlayer(soundMap)
            )
        );
    }

    protected override void Update(GameTime gameTime)
    {
        if (GamePad.GetState(PlayerIndex.One).Buttons.Back == ButtonState.Pressed || Keyboard.GetState().IsKeyDown(Keys.Escape)) {
            Exit();
        }

        _gameController.Update(gameTime);

        base.Update(gameTime);
    }

    protected override void Draw(GameTime gameTime)
    {
        GraphicsDevice.Clear(Color.Black);

        _spriteBatch.Begin(samplerState: SamplerState.PointClamp);
        _gameController.Draw();
        _spriteBatch.End();

        base.Draw(gameTime);
    }
}
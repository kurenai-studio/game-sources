using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using MineDirt.Src;
using System;
using System.Threading;

namespace MineDirt;

public class MineDirtGame : Game
{
    MineDirt.Src.Debug debug = new();

    public static MineDirtGame Instance;
    public static GraphicsDeviceManager Graphics;
    public static bool IsMouseCursorVisible = false;

    public static Camera Camera; 

    public static Texture2D TextureAtlas;
    public static Texture2D Crosshair;
    public static Vector2 CrosshairPosition;

    private SpriteBatch _spriteBatch;

    public static FastNoiseLite Noise = new(1234);

    private RenderTarget2D _renderTarget;

    private BasicEffect effect;
    public Effect blockShader;
    public Effect skyboxshader;
    
    private Effect underwaterShader;
    private EffectParameter isUnderwaterParam;

    private EffectParameter timeParameter;

    public MineDirtGame()
    {
        Graphics = new GraphicsDeviceManager(this);
        Content.RootDirectory = "Content";
        IsMouseVisible = IsMouseCursorVisible;

        // Uncap FPS
        Graphics.SynchronizeWithVerticalRetrace = false;
        IsFixedTimeStep = false;

        // Set to fullscreen
        Graphics.HardwareModeSwitch = false; //don't change the monitor resolution
        Graphics.IsFullScreen = true;

        // Set the resolution for fullscreen mode
        Graphics.PreferredBackBufferWidth = GraphicsAdapter.DefaultAdapter.CurrentDisplayMode.Width;//2560; // Set your preferred width
        Graphics.PreferredBackBufferHeight = GraphicsAdapter.DefaultAdapter.CurrentDisplayMode.Height;//1440; // Set your preferred height
        Graphics.ApplyChanges();

        Instance = this;
    }

    protected override void Initialize()
    {
        Camera = new Camera(GraphicsDevice, Window);

        // Set noise parameters
        Noise.SetNoiseType(FastNoiseLite.NoiseType.Perlin);
        Noise.SetFrequency(0.02f);
        Noise.SetFractalType(FastNoiseLite.FractalType.FBm);
        Noise.SetFractalOctaves(5);
        Noise.SetFractalLacunarity(2.0f);
        Noise.SetFractalGain(0.1f);
        Noise.SetFractalWeightedStrength(0.2f);

        debug.Initialize();
        base.Initialize();
    }

    protected override void LoadContent()
    {
        _spriteBatch = new SpriteBatch(GraphicsDevice);

        blockShader = Content.Load<Effect>("Shaders/BlockShader");
        underwaterShader = Content.Load<Effect>("Shaders/UnderwaterShader");
        skyboxshader = Content.Load<Effect>("Shaders/Sky");

        isUnderwaterParam = underwaterShader.Parameters["IsUnderwater"];
        timeParameter = underwaterShader.Parameters["Time"];

        TextureAtlas = Content.Load<Texture2D>("Textures/Blocks");
        Crosshair = Content.Load<Texture2D>("Textures/Crosshair");
        CrosshairPosition = new Vector2(
            GraphicsDevice.Viewport.Width / 2 - Crosshair.Width / 2,
            GraphicsDevice.Viewport.Height / 2 - Crosshair.Height / 2
        );

        // Initialize the BasicEffect
        effect = new BasicEffect(GraphicsDevice)
        {
            VertexColorEnabled = false, // Disable color shading
            TextureEnabled = true, // Enable texture mapping
            Texture = TextureAtlas, // Set the loaded texture
            View = Matrix.CreateLookAt(new Vector3(0, 0, 0), Vector3.Zero, Vector3.Up),
            Projection = Matrix.CreatePerspectiveFieldOfView(
                MathHelper.PiOver4,
                GraphicsDevice.Viewport.AspectRatio,
                0.1f,
                100f
            ),
        };

        blockShader
            .Parameters["WorldViewProjection"]
            .SetValue(
                Matrix.CreatePerspectiveFieldOfView(
                    MathHelper.PiOver4,
                    GraphicsDevice.Viewport.AspectRatio,
                    0.1f,
                    100f
                )
            );
        blockShader.Parameters["TextureAtlas"].SetValue(TextureAtlas);

        // Load the block textures
        BlockRendering.Load(BlockType.Dirt, [2]);
        BlockRendering.Load(BlockType.Grass, [1, 0, 2]);
        BlockRendering.Load(BlockType.Cobblestone, [3]);
        BlockRendering.Load(BlockType.Bedrock, [4]);
        BlockRendering.Load(BlockType.Stone, [5]);
        BlockRendering.Load(BlockType.Glass, [34]);
        BlockRendering.Load(BlockType.Water, [35]);
        BlockRendering.Load(BlockType.Sand, [8]);

        var pp = GraphicsDevice.PresentationParameters;
        _renderTarget = new RenderTarget2D(GraphicsDevice, pp.BackBufferWidth, pp.BackBufferHeight, false, pp.BackBufferFormat, pp.DepthStencilFormat);

        World.Initialize();
        debug.LoadContent();
    }

    protected override void Update(GameTime gameTime)
    {
        if (
            GamePad.GetState(PlayerIndex.One).Buttons.Back == ButtonState.Pressed
            || Keyboard.GetState().IsKeyDown(Keys.Escape)
        )
            Exit();

        KeyboardState keyboardState = Keyboard.GetState();
        MouseState mouseState = Mouse.GetState();

        Camera.Update(gameTime);
        IsMouseVisible = IsMouseCursorVisible;
        
        World.Update();

        debug.Update(gameTime);
        base.Update(gameTime);
    }

    protected override void Draw(GameTime gameTime)
    {
        debug.BeginDraw(gameTime);

        GraphicsDevice.SetRenderTarget(_renderTarget);
        GraphicsDevice.Clear(Color.White);

        GraphicsDevice.SamplerStates[0] = SamplerState.PointClamp;
        GraphicsDevice.BlendState = BlendState.Opaque; // Use Opaque for the first pass!

        effect.View = Camera.View;
        effect.Projection = Camera.Projection;
        World.Sky.Draw(GraphicsDevice,skyboxshader,Camera);

        blockShader.Parameters["WorldViewProjection"].SetValue(Camera.View * Camera.Projection);

        World.DrawChunksOpaque(blockShader);
        GraphicsDevice.BlendState = BlendState.AlphaBlend;
        World.DrawChunksTransparent(blockShader);

        if (Camera.PointedBlock.Type != BlockType.Air && Camera.PointedBlock.Type != BlockType.Water)
        {
            BoundingBox box = new(Camera.PointedBlockPosition, Camera.PointedBlockPosition + Vector3.One);
            BoundingBoxRenderer.DrawHighlightBox(box, GraphicsDevice, effect);
        }

        GraphicsDevice.SetRenderTarget(null);
        GraphicsDevice.Clear(Color.Black);

        isUnderwaterParam.SetValue(Camera.IsUnderwater);
        timeParameter.SetValue((float)gameTime.TotalGameTime.TotalSeconds);

        _spriteBatch.Begin(effect: underwaterShader);
        _spriteBatch.Draw(_renderTarget, Vector2.Zero, Color.White);
        _spriteBatch.End();

        _spriteBatch.Begin(); 
        _spriteBatch.Draw(Crosshair, CrosshairPosition, Color.White);
        _spriteBatch.End();

        base.Draw(gameTime); 

        debug.EndDraw(gameTime);
    }

    protected override void OnExiting(object sender, ExitingEventArgs args)
    {
        World.MeshThreadPool.Stop();

        base.OnExiting(sender, args);
    }
}

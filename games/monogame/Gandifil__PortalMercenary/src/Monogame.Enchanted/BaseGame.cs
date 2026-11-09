using System.Diagnostics;
using Coroutine;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Monogame.Enchanted.Debug;
using MonoGame.Extended;
using MonoGame.Extended.Input;
using MonoGame.Extended.Screens;

namespace Monogame.Enchanted;

public abstract class BaseGame: Game
{
    public GraphicsDeviceManager Graphics { get; }
    
    public SpriteBatch SpriteBatch  { get; private set; }
    
    public ScreenManager ScreenManager  { get; private set; }
    
    public BaseGame(string title, int width, int height, bool fullScreen)
    {
        Graphics = new GraphicsDeviceManager(this);
        Graphics.PreferredBackBufferWidth = width;
        Graphics.PreferredBackBufferHeight = height;
        Graphics.IsFullScreen = fullScreen;
        Graphics.ApplyChanges();
        
        Content.RootDirectory = "Content";
        Window.Title = title;
        Window.AllowUserResizing = true;
        IsMouseVisible = true;
        
        Components.ComponentAdded += (_, e) => Log.Info("Added Component " + e.GameComponent.GetType().Name);
    }

    protected override void Initialize()
    {
        AddDebug();
        SpriteBatch = new SpriteBatch(GraphicsDevice);
        ScreenManager = Components.Add<ScreenManager>();
        ScreenManager.DrawOrder = -1;
        base.Initialize();
    }

    protected override void Update(GameTime gameTime)
    {
        base.Update(gameTime);
        CoroutineHandler.Tick(gameTime.ElapsedGameTime.TotalSeconds);
        KeyboardExtended.Update();
    }

    [Conditional("DEBUG")]
    private void AddDebug()
    {
        Components.Add(new DebugGameComponent(this));
    }
}
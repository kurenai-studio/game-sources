using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using MonoGameLibrary.Systems;
using MonoGameLibrary.Systems.Infrastructure;
using MonoGameLibrary.UI;
using MonoGameLibrary.World;

namespace MonoGameLibrary
{
    public abstract class Core : Game
    {
        protected GraphicsDeviceManager Graphics { get; private set; }
        protected SpriteBatch? SpriteBatch { get; private set; }
        protected GameWorld World { get; private set; }
        protected UserInterfaceManager UserInterfaceManager { get; private set; }
        protected SystemScheduler SystemScheduler { get; private set; }

        /// <summary>
        /// Creates a new Core instance.
        /// </summary>
        /// <param name="title">The title to display in the title bar of the game window.</param>
        /// <param name="width">The initial width, in pixels, of the game window.</param>
        /// <param name="height">The initial height, in pixels, of the game window.</param>
        /// <param name="fullscreen">Indicates if the game should start in fullscreen mode.</param>
        public Core(string title, int width, int height, bool fullscreen)
        {
            Graphics = new GraphicsDeviceManager(this)
            {
                PreferredBackBufferWidth = width,
                PreferredBackBufferHeight = height,
                IsFullScreen = fullscreen,
                HardwareModeSwitch = false,
            };
            Graphics.ApplyChanges();

            Window.Title = title;
            Content.RootDirectory = "Content";
            IsMouseVisible = true;

            World = InitializeGameWorld();
            UserInterfaceManager = new UserInterfaceManager();
            SystemScheduler = new SystemScheduler();
        }
        protected abstract GameWorld InitializeGameWorld();

        protected sealed override void Initialize()
        {
            SpriteBatch = new SpriteBatch(GraphicsDevice);

            SystemScheduler.Add(World, new Renderer());
            SystemScheduler.Add(World, new TimerSystem());
            OnInitialize();
            base.Initialize();
        }
        protected abstract void OnInitialize();

        protected sealed override void Update(GameTime gameTime)
        {
            UserInterfaceManager.Update(GraphicsDevice.Viewport.Bounds, gameTime);

            SystemScheduler.Update(World, gameTime);
            OnUpdate(gameTime);
            base.Update(gameTime);
        }
        protected abstract void OnUpdate(GameTime gameTime);

        protected sealed override void Draw(GameTime gameTime)
        {
            OnDraw(gameTime);
            if (SpriteBatch != null)
            {
                SystemScheduler.Draw(SpriteBatch, UserInterfaceManager, World);
            }
            base.Draw(gameTime);
        }
        protected abstract void OnDraw(GameTime gameTime);
    }
}

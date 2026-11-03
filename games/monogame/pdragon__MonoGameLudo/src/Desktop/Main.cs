using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using MonoLudo.Shared;
using MonoLudo.Core;
using static MonoLudo.Core.Config;
using System;
using Microsoft.Xna.Framework.Content;

namespace MonoLudo.Desktop
{
    public class Main : Game
    {
        public GraphicsDeviceManager Graphics;
        public SpriteBatch SpriteBatch { get; private set; }
        private float _targetAspectRatio = 1.0f; // 1:1 (квадрат)
        public static GameTime GameTime = new GameTime();
        private MonoLudo.Shared.Main SharedMain;
        private Point _lastWindowPosition;
        private bool FirstFrameWithWindow = true;
        private bool _isResizing = false;
        private bool _matrixNeedsUpdate = true;
        private SpriteFont _font;

        public Main()
        {
            Graphics = new GraphicsDeviceManager(this);
            Window.AllowUserResizing = true;
            Content.RootDirectory = "Content";
            IsMouseVisible = true;
            
            //Window.ClientSizeChanged += OnWindowResized;
            Window.ClientSizeChanged += (s, e) =>
            {
                // Минимальный размер окна
                if (Window.ClientBounds.Width < 800 || Window.ClientBounds.Height < 600)
                {
                    Graphics.PreferredBackBufferWidth = 800;
                    Graphics.PreferredBackBufferHeight = 600;
                    Graphics.ApplyChanges();
                    SharedMain.UpdateScaleMatrix();
                }
            };
        }

        protected override void Initialize()
        {
            base.Initialize();
            new Input(Window);
            try
            {
                SharedMain = new MonoLudo.Shared.Main(Window, GraphicsDevice, Graphics, Content);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Ошибка инициализации: {ex}");
                Exit(); // Завершить игру при ошибке
            }
            SharedMain.LoadContent(GraphicsDevice, Content);
        }

        protected override void LoadContent()
        {
            //SharedMain.LoadContent(GraphicsDevice, Content);
            //SharedMain = new MonoLudo.Shared.Main();
            SpriteBatch = new SpriteBatch(GraphicsDevice);
            MonoLudo.Shared.Main.SetSpriteBatch(SpriteBatch);


            _font = Content.Load<SpriteFont>("Shafarik-Regular"); // Имя файла .spritefont без расширения
        }

        protected override void Update(GameTime gameTime)
        {
            
            if (Window.Position != _lastWindowPosition)
            {
                _matrixNeedsUpdate = true;
                _lastWindowPosition = Window.Position;
            }
            Config.DeltaTime = gameTime.ElapsedGameTime.TotalSeconds;
            if (GamePad.GetState(PlayerIndex.One).Buttons.Back == ButtonState.Pressed || Keyboard.GetState().IsKeyDown(Keys.Escape))
                Exit();

            base.Update(gameTime);
            Input.Update();
            SharedMain.Update(gameTime);
            if (FirstFrameWithWindow && GraphicsDevice != null)
            {
                FirstFrameWithWindow = false;
                SharedMain.UpdateScaleMatrix();
            }
        }

        private void OnWindowResized(object sender, EventArgs e)
        {
            // Фиксируем соотношение сторон (например, 16:9)
            float targetAspectRatio = 16f / 9f;
            int newWidth = Window.ClientBounds.Width;
            int newHeight = (int)(newWidth / targetAspectRatio);

            // Применяем новые размеры
            Graphics.PreferredBackBufferWidth = newWidth;
            Graphics.PreferredBackBufferHeight = newHeight;
            Graphics.ApplyChanges();
        }

        protected override void Draw(GameTime gameTime)
        {
            GraphicsDevice.Clear(Color.CornflowerBlue);
            SharedMain.Draw(GraphicsDevice, gameTime, Window);


            Debug.MousePos();
            // TODO: Add your drawing code here

            base.Draw(gameTime);
            
        }


    }
}

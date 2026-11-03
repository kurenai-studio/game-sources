using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using MonoLudo.Core;
using MonoLudo.Shared.Scenes;
using MonoLudo.Shared.Scenes.Game;
using System;
using System.Collections.Generic;
using System.Reflection.Metadata;

namespace MonoLudo.Shared
{
    public class Main 
    {
        private GraphicsDeviceManager _graphics;
        private static ContentManager Content;
        public static SpriteBatch SpriteBatch { get; private set; }
        public static string AssetDirectory { get; private set; }
        public static List<Config.ColorIndex> PlayersAvailable = new();
        public static Texture2D PixelTexture { get; private set; }
        private Board GameBoard = new Board();
        private GraphicsDevice GraphicsDevice;
        public static GameWindow Window { get; private set; }
        public GraphicsDeviceManager Graphics { get; private set; }
        private bool _matrixNeedsUpdate = true;
        private MainGameScene MainGameScene = new MainGameScene();


        private Vector2 _virtualResolution = new Vector2(1920, 1080); // Базовое разрешение
        public static Matrix ScaleMatrix { get; private set; } // Матрица масштабирования
        private Viewport _viewport; // Активная область отрисовки
        private bool _needsMatrixUpdate = true;

        public static void SetSpriteBatch(SpriteBatch spriteBatch)
        {
            SpriteBatch = spriteBatch;
        }

        public enum GameStage : short
        {
            MainMenu,
            MainLoop,
            GameOver
        }
        private static GameStage Stage = GameStage.MainLoop;
        public Main(GameWindow window, GraphicsDevice graphics, GraphicsDeviceManager gdm, ContentManager content)
        //public Main()
        {
            Console.WriteLine("Shared.Main constructor started"); // Лог в консоль
            Content = content;
            Window = window;
            GraphicsDevice = graphics;
            //UpdateScaleMatrix();
            Window.ClientSizeChanged += OnWindowSizeChanged;
            //Window.ClientSizeChanged += (s, e) => _needsMatrixUpdate = true;


            //gdm.DeviceCreated += OnDeviceCreated;

            Console.WriteLine("Shared.Main constructor finished");
        }

        public void LoadContent(GraphicsDevice graphicsDevice, ContentManager content)
        {
            this.GraphicsDevice = graphicsDevice;
            SpriteBatch = new SpriteBatch(graphicsDevice);

            PixelTexture = new Texture2D(graphicsDevice, 1, 1);
            PixelTexture.SetData(new[] { Color.White }); // Заливаем белым цветом

            // TODO: use this.Content to load your game content here
            var init = new Init();
            for (var colorIndex = 0; colorIndex < Config.PlayerColors.Length; colorIndex++)
            {
                Config.CircleTexture[colorIndex] = init.LoadTokenTexture(graphicsDevice, Config.PlayerColors[colorIndex]);
            }
            Config.BackgroundTexture = content.Load<Texture2D>("background"); // Имя файла без расширения
            init.LoadSettings();
        }

        public void Update(GameTime gameTime)
        {
            switch (Stage)
            {
                // TODO: Add your update logic here
                case GameStage.MainMenu:
                //MainMenuScene.Draw();
                //if (!mainMenuScene.Update())
                //{
                //    Stage = GameStage.MainLoop;
                //    mainGameScene = new MainGameScene();
                //}
                break;
            case GameStage.MainLoop:
                if (MainGameScene == null)
                {
                    throw new Exception("Main menu skipped");
                }
                if (MainGameScene != null && MainGameScene.Update())
                {
                    Stage = GameStage.GameOver;
                    //gameOverScene = new GameOverScene();

                }
                //Graphics.DrawText(Game.MainText, 50, (int)GameConfig.ScreenHeight - 30, 20, Color.Beige);
                break;
            case GameStage.GameOver:
                //Graphics.ClearBackground(new Color(40, 45, 52, 255));
                //if (!gameOverScene?.Update() ?? false)
                //{
                //    Stage = GameStage.MainMenu;
                //}

                break;
            }

        }

        public void Draw(GraphicsDevice graphicsDevice, GameTime gameTime, GameWindow window)
        {
            graphicsDevice.Clear(Color.CornflowerBlue);
            // TODO: Add your drawing code here

            if (SpriteBatch != null)
            {
                SpriteBatch.Begin();
                SpriteBatch.Draw(
                    Config.BackgroundTexture,
                    new Rectangle(0, 0, window.ClientBounds.Width, window.ClientBounds.Height), // Растянуть на весь экран
                    Color.White
                );
                if (Stage == GameStage.MainLoop)
                {
                    Dice.OnScreenDraw();
                }
                SpriteBatch.End();
                SpriteBatch.Begin(transformMatrix: ScaleMatrix);
                switch (Stage)
                {
                    // TODO: Add your update logic here
                    case GameStage.MainMenu:

                        break;
                    case GameStage.MainLoop:
                        MainGameScene.Draw();
                        
                        break;
                    case GameStage.GameOver:


                        break;
                }

                SpriteBatch.End();
            }
        }

        public static Vector2 ToVirtual(Vector2 screenPos) => Vector2.Transform(screenPos, Matrix.Invert(ScaleMatrix));
        public static Vector2 ToScreen(Vector2 virtualPos) => Vector2.Transform(virtualPos, ScaleMatrix);

        //private void OnDeviceCreated(object sender, EventArgs e) => UpdateScaleMatrix();
        private void OnWindowSizeChanged(object sender, EventArgs e) => UpdateScaleMatrix();

        public void UpdateScaleMatrix()
        {
            int screenWidth = Window.ClientBounds.Width;
            int screenHeight = Window.ClientBounds.Height;

            // Отдельные масштабы для X и Y (вызовет искажение!)
            float scaleX = screenWidth / _virtualResolution.X;
            float scaleY = screenHeight / _virtualResolution.Y;

            ScaleMatrix = Matrix.CreateScale(scaleX, scaleY, 1);

            //_needsMatrixUpdate = false;
        }

        public static void Text(string text, Vector2 position,  Color color)
        {
            SpriteBatch.DrawString(
            Content.Load<SpriteFont>("Fonts/Shafarik-Regular"), // Путь без .spritefont
            text,
            position,
            Board.Fade(color, 1)
        );
        }
    }
}

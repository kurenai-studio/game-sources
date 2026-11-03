using Desktop;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using MonoLudo.Core;
using MonoLudo.Shared.Actions;
using MonoLudo.Shared.Scenes.Game;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MonoLudo.Desktop
{
    public class Input
    {
        private static MouseState _prevState;
        private static MouseState _currentState;
        private static char? _lastCharPressed = null;
        private static Keys? _lastKeyPressed = null;

        public Input(GameWindow window)
        {
            window.TextInput += OnTextInput;
        }

        private void OnTextInput(object sender, TextInputEventArgs e)
        {
            _lastCharPressed = e.Character;
            _lastKeyPressed = e.Key;
        }

        public static void Update()
        {
            _prevState = _currentState;
            _currentState = Mouse.GetState();
        }

        public static bool IsLeftButtonReleased()
        {
            return _prevState.LeftButton == ButtonState.Pressed &&
                   _currentState.LeftButton == ButtonState.Released;
        }

        // Проверка отпускания ПРАВОЙ кнопки
        public static bool IsRightButtonReleased()
        {
            return _prevState.RightButton == ButtonState.Pressed &&
                   _currentState.RightButton == ButtonState.Released;
        }

        public static bool IsMiddleButtonReleased()
        {
            return _prevState.MiddleButton == ButtonState.Pressed &&
                   _currentState.MiddleButton == ButtonState.Released;
        }

        public static Point GetMousePosition() => new Point(_currentState.X, _currentState.Y);
        
        // Пример масштабирования под виртуальное разрешение 1920x1080
        static readonly GraphicsDeviceManager graphics;

        public static Vector2 GetScaledMousePosition()
        {
            MouseState mouseState = Mouse.GetState();
            float scaleX = (float)graphics.PreferredBackBufferWidth / 1920;
            float scaleY = (float)graphics.PreferredBackBufferHeight / 1080;
            return new Vector2(mouseState.X / scaleX, mouseState.Y / scaleY);
        }

        public static char? GetCharPressed()
        {
            return _lastCharPressed;
        }

        public static Keys? GetKeyPressed()
        {
            return _lastKeyPressed;
        }

        // Пример для 2D-камеры
        // Для проекций с камерой или матрицей вида
        // Этот метод учитывает трансформации камеры (https://community.monogame.net/t/solved-how-can-i-get-the-world-coords-of-the-mouse-2d/11263)
        //Matrix viewMatrix = Matrix.CreateLookAt(...);
        //Matrix projectionMatrix = Matrix.CreateOrthographicOffCenter(...);

        //Vector2 GetWorldMousePosition()
        //{
        //    MouseState mouseState = Mouse.GetState();
        //    Vector3 nearPoint = GraphicsDevice.Viewport.Unproject(
        //        new Vector3(mouseState.X, mouseState.Y, 0),
        //        projectionMatrix,
        //        viewMatrix,
        //        Matrix.Identity
        //    );
        //    return new Vector2(nearPoint.X, nearPoint.Y);
        //}

        public static void ProcessInput()
        {
            // Обработка клика по кубику
            if (Input.IsLeftButtonReleased())
            {
                Point mousePos = Input.GetMousePosition();
                Rectangle diceBounds = Config.GetDiceBounds();
                Debug.LastMouseClickedPosition = mousePos;

                // Бросаем кубик
                //if (ShapeHelper.CheckCollisionPointRec(mousePos, diceBounds))
                //{
                //    GameManager.Dice.Roll();
                //}
            }

            short chKey = (short)(Input.GetCharPressed() ?? 0);
            if (chKey != 0 && chKey >= 49 && chKey <= 54)
            {
                Console.WriteLine(chKey - 48);
                Dice.Cheat((short)(chKey - 48));
                if (MonoLudo.Shared.Scenes.Game.Game.Players![MonoLudo.Shared.Scenes.Game.Game.CurrentPlayerIndex] != null)
                {
                    MonoLudo.Shared.Scenes.Game.Game.Players![MonoLudo.Shared.Scenes.Game.Game.CurrentPlayerIndex].CurrentState = Player.State.AwaitToPlayerMove;
                }
            }


            var keyPressed = Input.GetKeyPressed();
            switch (keyPressed)
            {
                case 0:
                    break;
                case Keys.End:
                    MonoLudo.Shared.Scenes.Game.Game.Players![MonoLudo.Shared.Scenes.Game.Game.CurrentPlayerIndex].CurrentState = Player.State.AwaitToPlayerMove;
                    MonoLudo.Shared.Scenes.Game.Game.Players![MonoLudo.Shared.Scenes.Game.Game.CurrentPlayerIndex].CheatsTokensToPreHome();
                    break;
                case Keys.Home:
                    Console.WriteLine("End game");
                    MonoLudo.Shared.Scenes.Game.Game.Players![MonoLudo.Shared.Scenes.Game.Game.CurrentPlayerIndex].CurrentState = Player.State.AwaitToPlayerMove;
                    MonoLudo.Shared.Scenes.Game.Game.Players![MonoLudo.Shared.Scenes.Game.Game.CurrentPlayerIndex].CheatsTokensToHome();
                    break;

            }
        }

        public static Tile PlayerMoveHandler(SelectObjectAction.Object needSelectTo)
        {
            if (Input.IsLeftButtonReleased())
            {
                Point mousePos = Input.GetMousePosition();
                foreach (var tile in Board.Tiles)
                {
                    if (tile.Value != null)
                    {
                        if (Shape.CheckCollisionPointRec(mousePos, tile.Value.GetRectangle()))
                        {
                            if (needSelectTo.Player?.ColorName == tile.Value.Color || tile.Value.Color == Config.ColorIndex.Neutral)
                            {
                                return tile.Value ?? new Tile();
                            }
                        }
                    }
                }
            }
            return null;
        }

        public static bool PlayerClickBaseTokensHandler(Player player)
        {
            if (Input.IsLeftButtonReleased())
            {
                for (int i = 0; i < Config.TokensPerPlayer; i++)
                {
                    Point mousePos = Input.GetMousePosition();
                    var basePos = Board.GetTokenStartPosition((Board.TokenBasePositionName)i, (Config.ColorIndex)player.Id);
                    if (Shape.CheckCollisionPointRec(mousePos, new Rectangle((int)basePos.X, (int)basePos.Y, Config.CellSize.X, Config.CellSize.Y)))
                    {
                        Console.WriteLine(mousePos);
                        return true;
                    }
                }
            }
            return false;
        }

        public static Vector2 GetVirtualMousePosition(Matrix scaleMatrix)
        {
            var mouseState = Mouse.GetState();
            return Vector2.Transform(
                new Vector2(mouseState.X, mouseState.Y),
                Matrix.Invert(scaleMatrix)
            );
        }
    }
}

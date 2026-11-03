using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Input;

namespace DungeonExplorer.Core
{
    /// <summary>
    /// Gestisce tutti gli input del gioco (tastiera, mouse)
    /// </summary>
    public class InputManager
    {
        private KeyboardState _currentKeyboardState;
        private KeyboardState _previousKeyboardState;
        private MouseState _currentMouseState;
        private MouseState _previousMouseState;

        public Vector2 MousePosition => _currentMouseState.Position.ToVector2();
        public Vector2 MouseWorldPosition { get; private set; }

        public InputManager()
        {
            _currentKeyboardState = Keyboard.GetState();
            _previousKeyboardState = _currentKeyboardState;
            _currentMouseState = Mouse.GetState();
            _previousMouseState = _currentMouseState;
        }

        /// <summary>
        /// Aggiorna gli stati di input
        /// </summary>
        public void Update()
        {
            _previousKeyboardState = _currentKeyboardState;
            _currentKeyboardState = Keyboard.GetState();
            
            _previousMouseState = _currentMouseState;
            _currentMouseState = Mouse.GetState();
        }

        /// <summary>
        /// Aggiorna la posizione del mouse nel mondo (considerando la camera)
        /// </summary>
        public void UpdateMouseWorldPosition(Matrix cameraTransform)
        {
            Vector2 mouseScreen = MousePosition;
            Matrix invertedTransform = Matrix.Invert(cameraTransform);
            MouseWorldPosition = Vector2.Transform(mouseScreen, invertedTransform);
        }

        #region Keyboard Input

        /// <summary>
        /// Controlla se un tasto è attualmente premuto
        /// </summary>
        public bool IsKeyDown(Keys key)
        {
            return _currentKeyboardState.IsKeyDown(key);
        }

        /// <summary>
        /// Controlla se un tasto è stato appena premuto (non era premuto nel frame precedente)
        /// </summary>
        public bool IsKeyPressed(Keys key)
        {
            return _currentKeyboardState.IsKeyDown(key) && !_previousKeyboardState.IsKeyDown(key);
        }

        /// <summary>
        /// Controlla se un tasto è stato appena rilasciato
        /// </summary>
        public bool IsKeyReleased(Keys key)
        {
            return !_currentKeyboardState.IsKeyDown(key) && _previousKeyboardState.IsKeyDown(key);
        }

        /// <summary>
        /// Ottiene la direzione di movimento basata sui tasti WASD
        /// </summary>
        public Vector2 GetMovementDirection()
        {
            Vector2 direction = Vector2.Zero;

            if (IsKeyDown(Keys.W) || IsKeyDown(Keys.Up))
                direction.Y -= 1;
            if (IsKeyDown(Keys.S) || IsKeyDown(Keys.Down))
                direction.Y += 1;
            if (IsKeyDown(Keys.A) || IsKeyDown(Keys.Left))
                direction.X -= 1;
            if (IsKeyDown(Keys.D) || IsKeyDown(Keys.Right))
                direction.X += 1;

            // Normalizza per movimento diagonale uniforme
            if (direction != Vector2.Zero)
                direction.Normalize();

            return direction;
        }

        /// <summary>
        /// Controlla se vengono premuti tasti di movimento
        /// </summary>
        public bool IsMoving()
        {
            return IsKeyDown(Keys.W) || IsKeyDown(Keys.A) || 
                   IsKeyDown(Keys.S) || IsKeyDown(Keys.D) ||
                   IsKeyDown(Keys.Up) || IsKeyDown(Keys.Down) ||
                   IsKeyDown(Keys.Left) || IsKeyDown(Keys.Right);
        }

        #endregion

        #region Mouse Input

        /// <summary>
        /// Controlla se un pulsante del mouse è premuto
        /// </summary>
        public bool IsMouseButtonDown(MouseButton button)
        {
            return button switch
            {
                MouseButton.Left => _currentMouseState.LeftButton == ButtonState.Pressed,
                MouseButton.Right => _currentMouseState.RightButton == ButtonState.Pressed,
                MouseButton.Middle => _currentMouseState.MiddleButton == ButtonState.Pressed,
                _ => false
            };
        }

        /// <summary>
        /// Controlla se un pulsante del mouse è stato appena premuto
        /// </summary>
        public bool IsMouseButtonPressed(MouseButton button)
        {
            bool currentPressed = IsMouseButtonDown(button);
            bool previousPressed = button switch
            {
                MouseButton.Left => _previousMouseState.LeftButton == ButtonState.Pressed,
                MouseButton.Right => _previousMouseState.RightButton == ButtonState.Pressed,
                MouseButton.Middle => _previousMouseState.MiddleButton == ButtonState.Pressed,
                _ => false
            };

            return currentPressed && !previousPressed;
        }

        /// <summary>
        /// Controlla se un pulsante del mouse è stato appena rilasciato
        /// </summary>
        public bool IsMouseButtonReleased(MouseButton button)
        {
            bool currentPressed = IsMouseButtonDown(button);
            bool previousPressed = button switch
            {
                MouseButton.Left => _previousMouseState.LeftButton == ButtonState.Pressed,
                MouseButton.Right => _previousMouseState.RightButton == ButtonState.Pressed,
                MouseButton.Middle => _previousMouseState.MiddleButton == ButtonState.Pressed,
                _ => false
            };

            return !currentPressed && previousPressed;
        }

        /// <summary>
        /// Ottiene il movimento della rotella del mouse
        /// </summary>
        public int GetMouseWheelDelta()
        {
            return _currentMouseState.ScrollWheelValue - _previousMouseState.ScrollWheelValue;
        }

        /// <summary>
        /// Ottiene il movimento del mouse tra i frame
        /// </summary>
        public Vector2 GetMouseDelta()
        {
            return MousePosition - _previousMouseState.Position.ToVector2();
        }

        #endregion
    }

    /// <summary>
    /// Enumerazione per i pulsanti del mouse
    /// </summary>
    public enum MouseButton
    {
        Left,
        Right,
        Middle
    }
}
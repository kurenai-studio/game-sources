namespace MonoGameLibrary.Input
{
    public class InputManager
    {
        public KeyboardInfo KeyboardInfo { get; } = new KeyboardInfo();
        public MouseInfo MouseInfo { get; } = new MouseInfo();

        public static InputManager Instance { get; } = new InputManager();

        private InputManager() {}

        internal void Update()
        {
            KeyboardInfo.Update();
            MouseInfo.Update();
        }
    }
}
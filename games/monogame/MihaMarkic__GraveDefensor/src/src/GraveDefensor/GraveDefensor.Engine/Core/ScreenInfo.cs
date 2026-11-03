namespace GraveDefensor.Engine.Core
{
    public class ScreenInfo
    {
        public static ScreenInfo Default { get; set; }
        public int Width { get; }
        public int Height { get; }
        public bool HasMouse { get; }
        public bool IsFullScreen { get; }

        public ScreenInfo(int width, int height, bool hasMouse, bool isFullScreen)
        {
            Width = width;
            Height = height;
            HasMouse = hasMouse;
            IsFullScreen = isFullScreen;
        }
        public static ScreenInfo FullScreen(bool hasMouse) => new ScreenInfo(0, 0, hasMouse, true);
        public static ScreenInfo Window(int width, int height, bool hasMouse) => new ScreenInfo(width, height, hasMouse, false);
    }
}

using Microsoft.Xna.Framework.Input;

namespace Microsoft.Xna.Framework.Input
{
    public static class MouseStateExtensions
    {
        public static MouseState OffsetHorizontallyAndScale(this MouseState mouseState, int offset, float scale)
        {
            return new MouseState(
                (int)((mouseState.X + offset) / scale), (int)(mouseState.Y / scale), 
                mouseState.ScrollWheelValue,
                mouseState.LeftButton, mouseState.MiddleButton, mouseState.RightButton, mouseState.XButton1, mouseState.XButton2);
        }
        public static Point AsPoint(this MouseState mouseState) => new Point(mouseState.X, mouseState.Y);
    }
}

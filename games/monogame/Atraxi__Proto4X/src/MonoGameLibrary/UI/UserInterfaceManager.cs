using Microsoft.Xna.Framework;
using MonoGameLibrary.Input;
using MonoGameLibrary.Utils;

namespace MonoGameLibrary.UI
{
    public class UserInterfaceManager()
    {
        private Rectangle currentViewport = Rectangle.Empty;

        public Camera Camera { get; internal set; } = new();

        public void Update(Rectangle viewportBounds, GameTime gameTime)
        {
            InputManager.Instance.Update();
            currentViewport = viewportBounds;

            Camera.Update(viewportBounds, gameTime);
        }

        public Rectangle GetViewport()
        {
            return new Rectangle(
                currentViewport.X,
                currentViewport.Y,
                currentViewport.Width,
                currentViewport.Height);
        }

        public Rectangle GetVisibleScreenBoundsAABB()
        {
            var viewportPoints = new Vector2[] {
                currentViewport.Location.ToVector2(),
                new(currentViewport.Right, currentViewport.Top),
                new(currentViewport.Right, currentViewport.Bottom),
                new(currentViewport.Left, currentViewport.Bottom)
            }.Transform(Matrix.Invert(Camera.GetCameraTransform()));

            return viewportPoints.ToAABB();
        }
    }
}

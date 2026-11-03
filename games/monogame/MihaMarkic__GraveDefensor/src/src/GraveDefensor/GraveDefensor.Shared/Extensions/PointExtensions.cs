using Settings = GraveDefensor.Engine.Settings;

namespace Microsoft.Xna.Framework
{
    public static class PointExtensions
    {
        public static Vector2 AsVector2(this Point point) => new Vector2(point.X, point.Y);
        public static Vector2 AsVector2(this Settings.Point point) => new Vector2(point.X, point.Y);
    }
}

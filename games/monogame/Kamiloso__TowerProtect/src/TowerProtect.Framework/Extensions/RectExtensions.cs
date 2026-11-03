using TowerProtect.Domain.Model.Vectors;

namespace TowerProtect.Framework.Extensions;

internal static class RectExtensions
{
    public static Rect ToRect(this RectangleF rectangle)
        => new(rectangle.Center.ToVec2(), new Vec2(rectangle.Width, rectangle.Height));

    public static RectangleF ToRectangleF(this Rect rect)
        => new((float)rect.CornerMain.x, (float)rect.CornerMain.y, (float)rect.Size.x, (float)rect.Size.y);
}

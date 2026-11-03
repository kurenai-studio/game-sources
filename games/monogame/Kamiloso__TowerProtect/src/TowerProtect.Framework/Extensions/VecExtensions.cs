using TowerProtect.Domain.Model.Vectors;

namespace TowerProtect.Framework.Extensions;

internal static class VecExtensions
{
    public static Vec2 ToVec2(this Vector2 position)
        => new(position.X, position.Y);

    public static Vector2 ToVector2(this Vec2 position)
        => new((float)position.x, (float)position.y);
}

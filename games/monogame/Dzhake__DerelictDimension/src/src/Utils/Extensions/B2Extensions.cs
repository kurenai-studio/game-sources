using Box2D.NET;
using System.Runtime.CompilerServices;

namespace DerelictDimension.Utils.Extensions;

public static class B2Extensions
{
    public static B2Vec2 ToB2(this Vector2 v)
    {
        return Unsafe.As<Vector2, B2Vec2>(ref v);
    }

    public static Vector2 ToXNA(this B2Vec2 v)
    {
        return Unsafe.As<B2Vec2, Vector2>(ref v);
    }

    public static Color ToXNA(this B2HexColor c) => new((byte)((int)c >> 16), (byte)((int)c >> 8), (byte)c);
}

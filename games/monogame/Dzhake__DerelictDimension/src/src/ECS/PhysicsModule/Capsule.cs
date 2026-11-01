using Box2D.NET;
using System.Runtime.CompilerServices;

namespace DerelictDimension.ECS.PhysicsModule;

public record struct Capsule
{
    /// <summary>
    /// Local center of the first semicircle
    /// </summary>
    public Vector2 Center1;

    /// <summary>
    /// Local center of the second semicircle
    /// </summary>
    public Vector2 Center2;

    /// <summary>
    /// The Radius of the semicircles
    /// </summary>
    public float Radius;

    public Capsule(Vector2 center1, Vector2 center2, float radius)
    {
        Center1 = center1;
        Center2 = center2;
        Radius = radius;
    }

    public readonly override string ToString() => $"Capsule {{Center1: {Center1}; Center2: {Center2}; Radius: {Radius}}}";

    public B2Capsule ToB2() => Unsafe.As<Capsule, B2Capsule>(ref this);
}

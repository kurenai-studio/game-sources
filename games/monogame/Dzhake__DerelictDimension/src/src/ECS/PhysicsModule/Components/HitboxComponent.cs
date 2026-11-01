using Box2D.NET;
using System;
using System.Runtime.InteropServices;

namespace DerelictDimension.ECS.PhysicsModule.Components;

[ComponentKey("HitboxComponent")]
[ComponentSymbol("H")]
[StructLayout(LayoutKind.Explicit)]
public record struct HitboxComponent : IComponent, IEquatable<HitboxComponent>
{
    [FieldOffset(0)]
    public bool Collidable = true;

    [FieldOffset(1)]
    public B2ShapeId ShapeId;

    [FieldOffset(9)]
    public bool PhysicsDirty = true;

    [FieldOffset(10)]
    public HitboxType Type = HitboxType.None;

    [FieldOffset(14)]
    public OrientedRect Rect;

    [FieldOffset(14)]
    public Capsule Capsule;

    public readonly override string? ToString() => $"Hitbox: {Rect}, Collidable: {Collidable}";

    public HitboxComponent(OrientedRect hitbox)
    {
        Rect = hitbox;
        Type = HitboxType.OrientedRect;
    }

    public HitboxComponent(Capsule hitbox)
    {
        Capsule = hitbox;
        Type = HitboxType.Capsule;
    }

    public static bool operator ==(in HitboxComponent h1, in HitboxComponent h2) => h1.Rect == h2.Rect && h1.Collidable == h2.Collidable;
    public static bool operator !=(in HitboxComponent h1, in HitboxComponent h2) => !(h1 == h2);

    public readonly override int GetHashCode() => Rect.GetHashCode();
    public readonly bool Equals(HitboxComponent other) => Rect == other.Rect && Collidable == other.Collidable;
}

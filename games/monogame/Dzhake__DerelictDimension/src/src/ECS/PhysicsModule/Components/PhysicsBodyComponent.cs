using Box2D.NET;
using DerelictDimension.Utils;
using Friflo.Json.Fliox;

namespace DerelictDimension.ECS.PhysicsModule.Components;

public record struct PhysicsBodyComponent : IAutoIndexedComponent<PhysicsBodyComponent, B2BodyId>
{
    public B2BodyType Type;

    /// <summary>
    /// If <see langword="true"/>, body rotation is locked, and cannot be modified by the box2d.
    /// </summary>
    public bool FixedRotation;

    public Vector2 LinearVelocity;
    public float AngularVelocity;

    public bool PhysicsDirty;

    [Ignore]
    private B2BodyId bodyId;

    /// <summary>
    /// Get <see cref="B2BodyId"/> associated with this body. Use <see cref="IAutoIndexedComponentExt.SetIndexedValue"/> to set this value.
    /// </summary>
    public readonly B2BodyId BodyId => bodyId;

    public PhysicsBodyComponent(B2BodyType type = B2BodyType.b2_dynamicBody, bool fixedRotation = false)
    {
        Type = type;
        FixedRotation = fixedRotation;
    }

    ///<inheritdoc/>
    public readonly B2BodyId GetIndexedValue() => bodyId;
    public void SetIndexedValueDIRECTLY(B2BodyId value) => bodyId = value;
}

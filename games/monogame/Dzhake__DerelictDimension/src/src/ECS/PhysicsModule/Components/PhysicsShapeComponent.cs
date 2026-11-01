using Box2D.NET;
using DerelictDimension.Utils;
using Friflo.Json.Fliox;

namespace DerelictDimension.ECS.PhysicsModule.Components;

public record struct PhysicsShapeComponent : IAutoIndexedComponent<PhysicsShapeComponent, B2ShapeId>
{
    public bool IsSensor;
    public float Density = 1f;
    public float Friction = 0.6f;
    public float Restitution = 0f;
    public CollisionLayer CollisionCategories = CollisionLayer.None;
    public CollisionLayer CollisionMask = CollisionLayer.All;

    public bool PhysicsDirty = true;

    [Ignore]
    private B2ShapeId shapeId;

    /// <summary>
    /// Get <see cref="B2ShapeId"/> associated with this shape. Use <see cref="IAutoIndexedComponentExt.SetIndexedValue"/> to set this value.
    /// </summary>
    public readonly B2ShapeId ShapeId => shapeId;

    public PhysicsShapeComponent() { }

    public PhysicsShapeComponent(float density = 1f, float friction = 0.3f, float restitution = 0f, bool isSensor = false, CollisionLayer categories = CollisionLayer.None, CollisionLayer mask = CollisionLayer.All)
    {
        Density = density;
        Friction = friction;
        Restitution = restitution;
        IsSensor = isSensor;
        CollisionCategories = categories;
        CollisionMask = mask;
    }

    public readonly void ApplyTo(ref B2ShapeDef shapeDef)
    {
        shapeDef.density = Density;
        shapeDef.material.friction = Friction;
        shapeDef.material.restitution = Restitution;
        shapeDef.isSensor = IsSensor;
        shapeDef.filter.categoryBits = (ulong)CollisionCategories;
        shapeDef.filter.maskBits = (ulong)CollisionMask;
    }

    ///<inheritdoc/>
    public readonly B2ShapeId GetIndexedValue() => shapeId;

    ///<inheritdoc/>
    public void SetIndexedValueDIRECTLY(B2ShapeId value) => shapeId = value;
}

using DerelictDimension.ECS.PhysicsModule.Components;
using Monod.Utils.Extensions;

namespace DerelictDimension.Utils.Extensions;

public static class EntityExtensions
{
    /// <summary>
    /// Set <see cref="HitboxComponent.PhysicsDirty"/> for the <paramref name="entity"/> and all of its child entities.
    /// </summary>
    public static void SetHitboxDirtyRecursive(this Entity entity) => entity.ApplyRecursive<HitboxComponent>((in entity, ref hitbox) => hitbox.PhysicsDirty = true);

    /// <summary>
    /// Set <see cref="PhysicsBodyComponent.PhysicsDirty"/> for the <paramref name="entity"/> and all of its child entities.
    /// </summary>
    public static void SetPhysicsBodyDirtyRecursive(this Entity entity) => entity.ApplyRecursive<PhysicsBodyComponent>((in entity, ref physicsBody) => physicsBody.PhysicsDirty = true);
}

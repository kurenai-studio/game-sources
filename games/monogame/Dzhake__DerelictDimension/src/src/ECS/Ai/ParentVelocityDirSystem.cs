using DerelictDimension.ECS.PhysicsModule.Components;
using Monod.ECS;
using Monod.ECS.DefaultComponents;
using Monod.Utils.Extensions;
using MonoGame.Extended;

namespace DerelictDimension.ECS.Ai;

public class ParentVelocityDirSystem : TagSystem<ParentVelocityDirTag>
{
    public CommandBuffer cb;

    protected override void OnAddStore(EntityStore store)
    {
        base.OnAddStore(store);
        cb = store.GetCommandBuffer();
        cb.ReuseBuffer = true;
    }

    protected override void OnRemoveStore(EntityStore store)
    {
        cb.ReturnBuffer();
        base.OnRemoveStore(store);
    }

    protected override void OnUpdateGroup()
    {
        foreach (var entity in Query.Entities)
        {
            var parent = entity.Parent;
            if (parent.IsNull || !parent.HasComponent<PhysicsBodyComponent>()) continue;
            var velocity = parent.GetComponent<PhysicsBodyComponent>().LinearVelocity;
            if (velocity == Vector2.Zero) continue;
            ref var transform = ref entity.Data.Ensure<Transform2D>(cb);
            transform.Rotation = velocity.ToAngle();
            entity.SetTransformDirtyRecursive();
        }
        base.OnUpdateGroup();
    }
}

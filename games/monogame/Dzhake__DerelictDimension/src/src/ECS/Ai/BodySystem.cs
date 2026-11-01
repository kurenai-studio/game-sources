using DerelictDimension.ECS.PhysicsModule.Components;
using Friflo.Engine.ECS.Systems;
using Monod.Graphics.ECS.Sprite;
using Monod.TimeModule;
using Monod.Utils.Extensions;
using System;

namespace DerelictDimension.ECS.Ai;

public class BodySystem : QuerySystem<BodyComponent>
{
    public CommandBuffer cb;

    protected override void OnAddStore(EntityStore store)
    {
        cb = store.GetCommandBuffer();
        cb.ReuseBuffer = true;
        base.OnAddStore(store);
    }

    protected override void OnRemoveStore(EntityStore store)
    {
        cb.ReturnBuffer();
        base.OnRemoveStore(store);
    }

    protected override void OnUpdate()
    {
        float dt = Time.DeltaTime;
        foreach (var entity in Query.Entities)
        {
            var parent = entity.Parent;
            if (parent.IsNull || !parent.HasComponent<PhysicsBodyComponent>()) continue;

            var velocity = parent.GetComponent<PhysicsBodyComponent>().LinearVelocity;
            if (MathF.Abs(velocity.X) < 0.1f && MathF.Abs(velocity.Y) < 0.1f) continue;

            var data = entity.Data;
            ref var sprite = ref data.Ensure<Sprite2D>(cb);
            ref var body = ref data.Get<BodyComponent>();
            float oldRotation = body.Rotation;
            body.TimeSinceStartingState = (body.TimeSinceStartingState + dt) % body.RotationTime;
            body.Rotation = MathF.Sin((float)(body.TimeSinceStartingState / body.RotationTime * MathF.PI * 2)) * body.MaxRotation;
            sprite.Rotation += body.Rotation - oldRotation;
        }
    }
}

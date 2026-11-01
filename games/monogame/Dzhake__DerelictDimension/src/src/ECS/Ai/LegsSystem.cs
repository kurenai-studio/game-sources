using DerelictDimension.ECS.Drawing;
using DerelictDimension.ECS.PhysicsModule.Components;
using Monod.ECS;

namespace DerelictDimension.ECS.Ai;


public class LegsSystem : TagSystem<LegsTag>
{
    protected override void OnUpdateGroup()
    {
        foreach (var entity in Query.Entities)
        {
            var parent = entity.Parent;
            if (parent.IsNull) continue;
            if (!entity.HasComponent<AnimatedSpriteComponent>()) continue;
            var velocity = parent.GetComponent<PhysicsBodyComponent>().LinearVelocity.Length();
            if (velocity > 0.1f)
                continue;
            ref var animatedSprite = ref entity.GetComponent<AnimatedSpriteComponent>();
            animatedSprite.Reset();
        }
    }
}

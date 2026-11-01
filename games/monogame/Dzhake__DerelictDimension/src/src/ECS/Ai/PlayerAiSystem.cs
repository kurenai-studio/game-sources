using Box2D.NET;
using DerelictDimension.ECS.PhysicsModule.Components;
using DerelictDimension.Utils.Extensions;
using Friflo.Engine.ECS.Systems;
using Monod.ECS.DefaultComponents;
using Monod.InputModule;
using Monod.TimeModule;
using Monod.Utils.Extensions;

namespace DerelictDimension.ECS.Ai;

public class PlayerAiSystem : QuerySystem<PlayerAi>
{
    protected override void OnUpdate()
    {
        Query.ForEachEntity(UpdatePlayer);
    }

    private void UpdatePlayer(ref PlayerAi player, Entity entity)
    {
        var data = entity.Data;
        ref var physicsBody = ref data.Ensure<PhysicsBodyComponent>(CommandBuffer);
        if (!B2Worlds.b2Body_IsValid(physicsBody.BodyId)) return;
        ref var transform = ref data.Ensure<Transform2D>(CommandBuffer);

        Vector2 velocity = B2Bodies.b2Body_GetLinearVelocity(physicsBody.BodyId).ToXNA();

        Vector2 targetDirection = Vector2.Zero;
        if (Input.ActionDown(InputActions.MoveLeft)) targetDirection.X--;
        if (Input.ActionDown(InputActions.MoveRight)) targetDirection.X++;
        if (Input.ActionDown(InputActions.MoveUp)) targetDirection.Y--;
        if (Input.ActionDown(InputActions.MoveDown)) targetDirection.Y++;

        targetDirection.NormalizeSafe();
        var targetVelocity = targetDirection * player.TargetVelocity;
        var velChange = targetVelocity - velocity;
        var velChangeLen = velChange.Length();
        if (velChangeLen < player.Acceleration * Time.DeltaTime)
        {
            velocity = targetVelocity;
        }
        else
        {
            velChange.NormalizeSafe();
            velChange *= player.Acceleration * Time.DeltaTime;
            velocity += velChange;
        }

        B2Bodies.b2Body_SetLinearVelocity(physicsBody.BodyId, velocity.ToB2());
    }
}

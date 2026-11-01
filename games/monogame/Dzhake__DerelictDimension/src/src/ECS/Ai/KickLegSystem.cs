using DerelictDimension.ECS.Drawing;
using DerelictDimension.ECS.PhysicsModule.Components;
using Friflo.Engine.ECS.Systems;
using Monod.Graphics.ECS.Sprite;
using Monod.InputModule;
using Monod.TimeModule;
using Monod.Utils.Extensions;

namespace DerelictDimension.ECS.Ai;

public class KickLegSystem : QuerySystem<KickLegComponent>
{
    public EntityStore Store;

    protected override void OnAddStore(EntityStore store)
    {
        Store = store;
        base.OnAddStore(store);
    }

    protected override void OnUpdate()
    {
        Query.ForEachEntity(UpdateKickLeg);
        CommandBuffer.Playback();
    }

    private void UpdateKickLeg(ref KickLegComponent kickLeg, Entity entity)
    {
        float dt = Time.DeltaTime;
        ref var kickLegHitbox = ref entity.Data.Ensure<HitboxComponent>(CommandBuffer);

        if (kickLeg.KickTimeRemaining > dt)
        {
            if (!kickLegHitbox.Collidable)
            {
                kickLegHitbox.Collidable = true;
                kickLegHitbox.PhysicsDirty = true;
            }
            kickLeg.KickTimeRemaining -= dt;
            return;
        }

        if (kickLegHitbox.Collidable)
        {
            kickLegHitbox.Collidable = false;
            kickLegHitbox.PhysicsDirty = true;
        }

        if (kickLeg.KickCooldownRemaining > dt)
        {
            kickLeg.KickCooldownRemaining -= dt;
            return;
        }
        else
        {
            kickLeg.KickCooldownRemaining = 0;
        }

        ref var kickLegAnim = ref entity.Data.Ensure<AnimatedSpriteComponent>(CommandBuffer);
        kickLegAnim.AnimationSpeedMultiplier = 0;
        kickLegAnim.Reset();

        if (kickLeg.KickTimeRemaining > 0)
        {
            EndKick(ref kickLeg, ref GetLegSprite(ref kickLeg));
            return;
        }

        if (Input.ActionPressed(InputActions.Kick))
        {
            StartKick(ref kickLeg, ref entity.Data.Ensure<AnimatedSpriteComponent>(CommandBuffer), ref GetLegSprite(ref kickLeg));
        }
    }

    private ref Sprite2D GetLegSprite(ref KickLegComponent kickLeg)
    {
        var leg = Store.GetEntityByPid(kickLeg.LegPid);
        var legData = leg.Data;
        return ref legData.Ensure<Sprite2D>(CommandBuffer);
    }

    private void StartKick(ref KickLegComponent kickLeg, ref AnimatedSpriteComponent kickLegAnim, ref Sprite2D legSprite)
    {
        kickLeg.KickTimeRemaining = kickLeg.KickTimeStarting;
        kickLegAnim.AnimationSpeedMultiplier = 1;
        kickLegAnim.Reset();
        legSprite.Visible = false;
    }

    private void EndKick(ref KickLegComponent kickLeg, ref Sprite2D legSprite)
    {
        kickLeg.KickTimeRemaining = 0;
        kickLeg.KickCooldownRemaining = kickLeg.KickCooldownStarting;
        legSprite.Visible = true;
    }
}

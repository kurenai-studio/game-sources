using DerelictDimension.ECS.Drawing;
using DerelictDimension.ECS.Links;
using DerelictDimension.ECS.PhysicsModule;
using DerelictDimension.ECS.PhysicsModule.Components;
using Friflo.Engine.ECS.Systems;
using Monod.MathModule;
using Monod.Shared.Exceptions;
using Monod.Utils.Extensions;

namespace DerelictDimension.ECS.Ai;

public class DamageSystem : BaseSystem
{
    public ArchetypeQuery Query;
    public CommandBuffer cb;

    protected override void OnAddStore(EntityStore store)
    {
        Query = store.QueryRelation<DamageRelation>();
        cb = store.GetCommandBuffer();
        cb.ReuseBuffer = true;
        base.OnAddStore(store);
    }

    protected override void OnUpdateGroup()
    {
        foreach (var victimEnt in Query.Entities)
        {
            var victimData = victimEnt.Data;
            if (victimData.Has<BodyComponent>())
            {
                var victimBodyLinks = victimEnt.GetIncomingLinks<HumanBody>();
                if (victimBodyLinks.Count != 1)
                {
                    Log.Warning("A entity with id '{Id}' and 'BodyComponent' but with {LinksAmount} (1 expected) incoming 'HumanBody' link was attacked", victimEnt.Id, victimBodyLinks.Count);
                    continue;
                }
                var victimBodyLink = victimBodyLinks[0];
                var victimBase = victimBodyLink.Entity;
                AttackHuman(in victimBase, in victimEnt);
            }
        }

        cb.Playback();
    }

    private void AttackHuman(in Entity victimBase, in Entity victimPart)
    {
        var victimBaseData = victimBase.Data;
        ref var mortal = ref victimBaseData.Ensure<MortalComponent>(cb);
        if (mortal.Dead) return;

        foreach (var relation in victimPart.GetRelations<DamageRelation>())
        {
            var damagerEnt = relation.Damager;
            var damagerData = damagerEnt.Data;
            if (damagerData.Has<KickLegComponent>())
            {
                damagerEnt.GetWorldPos(out float rotation);
                KillHuman(in victimBase, in victimBaseData, ref mortal, MathM.VectorFromRot(rotation));
            }
        }
    }

    private void KillHuman(in Entity victimBase, in EntityData victimBaseData, ref MortalComponent mortal, Vector2 direction)
    {
        if (!victimBaseData.Has<HumanBody>()) Guard.Exception($"Tried to kill a human without body, human id: {victimBase.Id}");
        var body = victimBaseData.Get<HumanBody>().Body;
        foreach (int childId in victimBase.ChildIds)
        {
            if (childId == body.Id) continue;
            cb.DeleteEntity(childId);
        }

        mortal.Dead = true;
        mortal.Hp = 0;

        ref var physicsBody = ref victimBaseData.Ensure<PhysicsBodyComponent>(cb);
        physicsBody.LinearVelocity = direction * 5;
        physicsBody.PhysicsDirty = true;
        ref var bodyAnim = ref body.Data.Ensure<AnimatedSpriteComponent>(cb);
        // TODO: bodyAnim.SetAnim(Animations.HumanDeath)
        ref var bodyShape = ref body.Data.Ensure<PhysicsShapeComponent>(cb);
        bodyShape.CollisionMask &= CollisionLayer.Walls;
        bodyShape.PhysicsDirty = true;
        Log.Information("Killed {Id}", victimBase.Id);
    }
}

using Friflo.Engine.ECS.Systems;

namespace DerelictDimension.ECS.Ai;

public class DamageCleaupSystem : BaseSystem
{
    public ArchetypeQuery Query;

    protected override void OnAddStore(EntityStore store)
    {
        Query = store.QueryRelation<DamageRelation>();
        base.OnAddStore(store);
    }

    protected override void OnUpdateGroup()
    {
        foreach (var entity in Query.Entities)
        {
            foreach (var relation in entity.GetRelations<DamageRelation>())
            {
                entity.RemoveRelation<DamageRelation, Entity>(relation.GetRelationKey());
            }
        }
    }
}

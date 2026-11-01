namespace DerelictDimension.ECS.Ai;

public record struct DamageRelation : ILinkRelation
{
    public readonly Entity Damager;
    public Entity GetRelationKey() => Damager;
    public DamageRelation(Entity damager)
    {
        Damager = damager;
    }
}

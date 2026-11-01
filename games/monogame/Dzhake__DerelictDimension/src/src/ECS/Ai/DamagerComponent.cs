namespace DerelictDimension.ECS.Ai;

public record struct DamagerComponent : IComponent
{
    public float Damage;
    public int OwnerId;
}

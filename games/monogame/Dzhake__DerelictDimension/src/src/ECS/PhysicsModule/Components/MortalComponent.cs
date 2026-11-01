namespace DerelictDimension.ECS.PhysicsModule.Components;

public record struct MortalComponent : IComponent
{
    public bool Dead;
    public float Hp;
    public float MaxHp;

    public MortalComponent()
    {
    }

    public override readonly string ToString() => $"Dead: {Dead}";
}

namespace DerelictDimension.ECS.PhysicsModule.Components;

public record struct MobileComponent : IComponent
{
    public Vector2 Velocity;
    public long SupportingEntityPid = -1;

    //probably don't need this one?
    public float HighestPoint = float.MaxValue;

    public readonly bool InAir => SupportingEntityPid < 0;
    public readonly bool Grounded => SupportingEntityPid >= 0;

    public MobileComponent()
    {
    }
}

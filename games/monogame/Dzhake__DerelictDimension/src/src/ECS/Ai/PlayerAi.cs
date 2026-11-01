namespace DerelictDimension.ECS.Ai;

public record struct PlayerAi : IComponent
{
    public static readonly float NormalWalkingSpeed = 4;

    public float TargetVelocity = NormalWalkingSpeed;
    public float Acceleration = 30;

    public PlayerAi()
    {
    }
}

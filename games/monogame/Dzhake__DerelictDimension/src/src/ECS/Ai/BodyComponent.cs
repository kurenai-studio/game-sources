namespace DerelictDimension.ECS.Ai;

public record struct BodyComponent : IComponent
{
    public float RotationTime = 1;
    public float MaxRotation = 0.2f;
    public float Rotation;

    public float TimeSinceStartingState;

    public BodyComponent() { }

    public BodyComponent(float rotationTime, float maxRotation)
    {
        RotationTime = rotationTime;
        MaxRotation = maxRotation;
    }
}

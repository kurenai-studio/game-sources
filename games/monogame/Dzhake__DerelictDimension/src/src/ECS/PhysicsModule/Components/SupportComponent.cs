namespace DerelictDimension.ECS.PhysicsModule.Components;

public record struct SupportComponent : IComponent
{
    /// <summary>
    /// Speed multiplier, applied to mobiles which are supported by this entity. Applied once per frame, at the beginning of physics update.
    /// </summary>
    public float Friction;

    /// <summary>
    /// Multiplier to X acceleration of mobiles which are supported by this entity.
    /// </summary>
    public float AccelerationMult = 1;

    //specify one argument to turn it into 'constructor with default arguments' instead of 'constructor without arguments'..
    public SupportComponent() : this(0) { }

    /// <summary>
    /// Create a new instance of support Component with the specified values.
    /// </summary>
    /// <param name="friction">Speed multiplier, applied to mobiles which are supported by this entity. Applied once per frame, at the beginning of physics update.</param>
    /// <param name="accelerationMult">Multiplier to X acceleration of mobiles which are supported by this entity.</param>
    public SupportComponent(float friction = 0, float accelerationMult = 1)
    {
        Friction = friction;
        AccelerationMult = accelerationMult;
    }
}

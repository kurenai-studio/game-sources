using TowerProtect.Domain.Model.Vectors;

namespace TowerProtect.Domain.Backend.Entities.Abstract.Dynamic;

internal abstract class DynamicEntity(Vec2 position, double rotation, byte health)
    : Entity(position, rotation, health)
{
    public abstract double MovementSpeed { get; }
    public abstract bool IsFlying { get; }

    protected virtual void MovementStep(double deltaTime)
    {
        Position += Vec2.Right.Rotate(Rotation) * MovementSpeed * deltaTime;
    }
}

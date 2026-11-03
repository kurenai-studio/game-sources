using TowerProtect.Domain.Inventions.Interfaces;
using TowerProtect.Domain.Model.Vectors;

namespace TowerProtect.Domain.Backend.Entities.Abstract.Dynamic.Shootable;

internal abstract class ShootableEntity(Vec2 position, double rotation)
    : DynamicEntity(position, rotation, 0), IUpdateAware
{
    public sealed override bool IsDamageable => false;
    public override bool IsFlying => false;

    public virtual void Update(double deltaTime)
    {
        MovementStep(deltaTime);
    }
}

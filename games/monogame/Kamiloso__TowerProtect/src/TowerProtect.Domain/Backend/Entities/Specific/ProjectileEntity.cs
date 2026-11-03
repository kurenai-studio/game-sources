using TowerProtect.Domain.Backend.Entities.Abstract.Dynamic.Shootable;
using TowerProtect.Domain.Inventions.Interfaces;
using TowerProtect.Domain.Model.Entities;
using TowerProtect.Domain.Model.Vectors;

namespace TowerProtect.Domain.Backend.Entities.Specific;

internal sealed class ProjectileEntity(Vec2 position, double rotation)
    : ShootableEntity(position, rotation), IUpdateAware
{
    public override EntityType Type => EntityType.Projectile;
    public override double MovementSpeed => 8.0;
}

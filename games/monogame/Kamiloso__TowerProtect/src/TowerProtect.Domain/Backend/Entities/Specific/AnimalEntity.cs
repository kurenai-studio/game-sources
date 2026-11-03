using TowerProtect.Domain.Backend.Entities.Abstract.Dynamic.Controllable;
using TowerProtect.Domain.Backend.Entities.Interactions.Input;
using TowerProtect.Domain.Inventions.Interfaces;
using TowerProtect.Domain.Model.Entities;
using TowerProtect.Domain.Model.Vectors;

namespace TowerProtect.Domain.Backend.Entities.Specific;

internal sealed class AnimalEntity(Vec2 position, IController controller)
    : MeleeEntity(position, health: 1, controller), IUpdateAware
{
    public override EntityType Type => EntityType.Animal;
    public override double MovementSpeed => 2.0;
}

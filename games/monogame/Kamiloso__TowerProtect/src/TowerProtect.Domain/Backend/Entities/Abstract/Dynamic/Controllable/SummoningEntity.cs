using System;
using TowerProtect.Domain.Backend.Entities.Interactions.Input;
using TowerProtect.Domain.Model.Vectors;

namespace TowerProtect.Domain.Backend.Entities.Abstract.Dynamic.Controllable;

internal abstract class SummoningEntity(Vec2 position, byte health, IController controller)
    : ControllableEntity(position, health, controller)
{
    protected override void ShootingStep(double deltaTime)
    {
        Console.WriteLine("TODO: implement summoning");
    }
}

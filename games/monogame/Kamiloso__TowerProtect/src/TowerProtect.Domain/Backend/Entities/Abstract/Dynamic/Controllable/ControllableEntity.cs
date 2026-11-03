using TowerProtect.Domain.Backend.Entities.Interactions.Input;
using TowerProtect.Domain.Inventions.Interfaces;
using TowerProtect.Domain.Model.Vectors;

namespace TowerProtect.Domain.Backend.Entities.Abstract.Dynamic.Controllable;

internal abstract class ControllableEntity(Vec2 position, byte health, IController controller)
    : DynamicEntity(position, 0f, health), IUpdateAware
{
    public override bool IsDamageable => true;
    public override bool IsFlying => false;
    public override bool IsRendered => _inputReceived && base.IsRendered;

    private bool _inputReceived;

    public virtual void Update(double deltaTime)
    {
        if (controller.InputReceived)
        {
            Rotation = controller.Rotation;

            if (controller.IsMoving)
                MovementStep(deltaTime);

            if (controller.IsShooting)
                ShootingStep(deltaTime);

            _inputReceived = true;
        }
    }

    protected abstract void ShootingStep(double deltaTime);
}

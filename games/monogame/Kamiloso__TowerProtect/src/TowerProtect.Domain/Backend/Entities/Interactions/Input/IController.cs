namespace TowerProtect.Domain.Backend.Entities.Interactions.Input;

public interface IController
{
    bool InputReceived { get; }

    // Input properties
    double Rotation { get; }
    bool IsMoving { get; }
    bool IsShooting { get; }
}

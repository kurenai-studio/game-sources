using TowerProtect.Domain.Model.Unions;

namespace TowerProtect.Domain.Backend.Entities.Interactions.Input;

public class ManualController : IController
{
    public bool InputReceived { get; private set; }

    // Input properties
    public double Rotation { get; private set; }
    public bool IsMoving { get; private set; }
    public bool IsShooting { get; private set; }

    public void AcceptInput(InputUnion inputUnion)
    {
        InputReceived = true;

        Rotation = inputUnion.Rotation;
        IsMoving = inputUnion.IsMoving;
        IsShooting = inputUnion.IsShooting;
    }
}

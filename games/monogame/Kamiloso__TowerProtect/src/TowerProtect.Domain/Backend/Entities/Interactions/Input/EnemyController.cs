using System.Diagnostics;

namespace TowerProtect.Domain.Backend.Entities.Interactions.Input;

public class EnemyController : IController
{
    public bool InputReceived => true; // Enemy AI always has some input

    public double Rotation => _sw.ElapsedMilliseconds / 1000.0;
    public bool IsMoving => true;
    public bool IsShooting => true;

    // TODO: Implement enemy AI logic

    private readonly Stopwatch _sw = Stopwatch.StartNew();
}

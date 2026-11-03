namespace TowerProtect.Domain.Model.Unions;

public readonly record struct InputUnion(
    double Rotation,
    bool IsMoving,
    bool IsShooting);

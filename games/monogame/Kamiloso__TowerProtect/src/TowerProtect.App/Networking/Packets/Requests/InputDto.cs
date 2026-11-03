using TowerProtect.Domain.Inventions.Networking;
using TowerProtect.Domain.Model.Unions;

namespace TowerProtect.App.Networking.Packets.Requests;

public readonly record struct InputDto(
    double Rotation,
    bool IsMoving,
    bool IsShooting) : IPacket
{
    public static int Identifier => 2;

    public InputUnion ToInputUnion() => new()
    {
        Rotation = Rotation,
        IsMoving = IsMoving,
        IsShooting = IsShooting,
    };
}

using TowerProtect.Domain.Inventions.Networking;

namespace TowerProtect.App.Networking.Packets.Requests;

public readonly record struct HelloDto : IPacket
{
    public static int Identifier => 1;
}

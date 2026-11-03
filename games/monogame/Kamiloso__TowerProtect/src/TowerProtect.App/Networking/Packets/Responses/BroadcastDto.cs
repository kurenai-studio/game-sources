using System;
using TowerProtect.Domain.Inventions.Networking;
using TowerProtect.Domain.Model.Entities;
using TowerProtect.Domain.Model.Unions;

namespace TowerProtect.App.Networking.Packets.Responses;

public readonly record struct BroadcastDto(
    EntityListData EntityList,
    double TickTime) : IPacket
{
    public static int Identifier => -1;

    public FrameUnion ToFrameUnion(Guid playerGuid) => new()
    {
        PlayerGuid = playerGuid,
        EntityList = EntityList,
        TickTime = TickTime,
    };
}

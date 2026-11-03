using System;
using TowerProtect.Domain.Model.Entities;

namespace TowerProtect.Domain.Model.Unions;

public readonly record struct FrameUnion(
    Guid PlayerGuid,
    EntityListData EntityList,
    double TickTime)
{
    public void ForEach(Action<EntityData> action)
    {
        EntityList.ForEach(action);
    }

    public void ForPlayer(Action<EntityData> action)
    {
        var playerGuid = PlayerGuid;

        ForEach(entity =>
        {
            if (entity.Guid == playerGuid)
                action(entity);
        });
    }
}

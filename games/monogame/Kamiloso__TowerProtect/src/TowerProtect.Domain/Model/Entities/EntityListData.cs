using System;
using System.Collections.Immutable;

namespace TowerProtect.Domain.Model.Entities;

public readonly record struct EntityListData(
    ImmutableArray<EntityData> Entities)
{
    public void ForEach(Action<EntityData> process)
    {
        foreach (var entityData in Entities)
        {
            process(entityData);
        }
    }
}

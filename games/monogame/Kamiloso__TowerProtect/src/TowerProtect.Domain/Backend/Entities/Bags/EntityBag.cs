using AutoInterfaceAttributes;
using System;
using System.Collections.Generic;
using System.Linq;
using TowerProtect.Domain.Backend.Entities.Abstract;
using TowerProtect.Domain.Inventions.Interfaces;
using TowerProtect.Domain.Model.Entities;

namespace TowerProtect.Domain.Backend.Entities.Bags;

partial interface IEntityBag : IUpdateAware
{
    internal void SpawnEntity(Entity entity, out Guid guid);
}

[AutoInterface]
internal class EntityBag : IEntityBag
{
    private readonly Dictionary<Guid, Entity> _entities = [];

    private IEnumerable<Entity> EntitiesView => _entities.Values;
    private IEnumerable<Entity> EntitiesSnapshotWhereAlive => EntitiesView.ToList()
        .Where(e => e.IsAlive);

    public void Update(double deltaTime)
    {
        foreach (var entity in EntitiesSnapshotWhereAlive)
        {
            var updateAware = entity as IUpdateAware;
            updateAware?.Update(deltaTime);
        }
    }

    [IgnoreAutoInterface]
    public void SpawnEntity(Entity entity, out Guid guid)
    {
        entity.OnDeathEvent += () =>
        {
            _entities.Remove(entity.Guid);
        };

        _entities.Add(entity.Guid, entity);
        guid = entity.Guid;
    }

    public EntityListData CollectEntityListData()
    {
        List<EntityData> entityDataList = [.. EntitiesView
            .Where(e => e.IsRendered)
            .Select(e => e.EntityData)];

        return new([.. entityDataList]);
    }
}

using Monod.Shared.Exceptions;
using System;

namespace DerelictDimension.ECS.Rewinding;

public record struct ComponentRef
{
    public int EntityId;
    public Type? ComponentType;

    public ComponentRef(int entityId, Type? componentType)
    {
        EntityId = entityId;
        ComponentType = componentType;
    }

    public readonly IComponent? Get(EntityStore store)
    {
        if (EntityId == -1 || ComponentType == null) Guard.Exception($"Tried to get Component of invalid ComponentRef: {this}");
        Entity entity = store.GetEntityById(EntityId);
        EntitySchema schema = EntityStore.GetEntitySchema();
        var componentType = schema.ComponentTypeByType[ComponentType];
        return EntityUtils.GetEntityComponent(entity, componentType);
    }

    public override readonly string ToString() => $"{{ EntityId: {EntityId}, ComponentType: {(ComponentType != null ? ComponentType : "<null>")} }}";
}

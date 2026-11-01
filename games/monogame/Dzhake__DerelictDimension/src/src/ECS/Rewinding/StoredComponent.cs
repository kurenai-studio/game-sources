using Monod.ECS;
using Monod.Shared.Exceptions;
using System;
using System.Runtime.InteropServices;

namespace DerelictDimension.ECS.Rewinding;

[StructLayout(LayoutKind.Explicit)]
public record struct StoredComponent()
{
    [FieldOffset(0)]
    public IComponent? Component;
    [FieldOffset(0)]
    public Type? ComponentType;

    [FieldOffset(8)]
    public int EntityId;

    [FieldOffset(12)]
    public bool RemoveComponent;
    [FieldOffset(12)]
    public bool EnableEntity;

    public static StoredComponent ComponentChangedOrAdded(int entityId, IComponent? component)
    {
        return new()
        {
            EntityId = entityId,
            Component = component
        };
    }

    public static StoredComponent NoComponent(int entityId, Type type)
    {
        return new()
        {
            EntityId = entityId,
            ComponentType = type,
            RemoveComponent = true,
        };
    }

    public static StoredComponent EntityChanged(int entityId, bool enableEntity)
    {
        return new()
        {
            EntityId = entityId,
            EnableEntity = enableEntity,
        };
    }

    public readonly void Set(EntityStore store)
    {
        if (EntityId == -1) Guard.Exception($"Tried to apply invalid StoredComponent: {this}");
        Entity entity = store.GetEntityById(EntityId);
        var data = entity.Data;
        if (data.Has<TimelessComponent>())
            return;

        if (Component is null)
        {
            entity.Enabled = EnableEntity;
        }
        else if (RemoveComponent)
        {
            entity.RemoveComponentByType(ComponentType!); // 'Component is null' is the same 'ComponentType is null', so ComponentType is not null here.
        }
        else
        {
            entity.AddOrChangeComponent(Component!);
        }
    }

    public readonly ComponentRef ToComponentRef()
    {
        return new ComponentRef(EntityId, GetComponentType());
    }

    public readonly Type? GetComponentType()
    {
        return ComponentType?.GetType().IsAssignableTo(typeof(Type)) != false ? ComponentType : Component?.GetType();
    }

    public readonly override string ToString() => $"EntityId: {EntityId}, Component: {Component?.ToString() ?? "<null>"}";
}

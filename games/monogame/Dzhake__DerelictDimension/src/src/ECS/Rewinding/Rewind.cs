using System.Collections.Generic;

namespace DerelictDimension.ECS.Rewinding;

public static class Rewind
{
    public static Dictionary<ComponentRef, RecordedComponent> RecordedComponents = [];
    public static bool Active;
    public static int CurrentFrame = 0;
    public static int RewindSpeed = -1;

    public static float GetSaturationChange()
    {
        if (!Active) return 0;
        return (Math.Sign(RewindSpeed) - 1) * 0.4f;
    }

    public static void StoreEntityUpdated(Entity entity, bool wasEnabled)
    {
        if (Active) return;
        ComponentRef key = new(entity.Id, null);

        if (RecordedComponents.TryGetValue(key, out var recorded))
        {
            recorded.EnableEntity = wasEnabled;
            RecordedComponents[key] = recorded;
            return;
        }

        RecordedComponents.Add(key, new(null, wasEnabled));
    }

    public static void StoreComponentUpdated<T>(int entityId, ref T component) where T : IComponent
    {
        if (Active) return;
        ComponentRef key = new(entityId, typeof(T));

        if (RecordedComponents.TryGetValue(key, out var recorded))
        {
            if (recorded.Component is not null) return;
            recorded.Component = component;
            RecordedComponents[key] = recorded;
        }
        else
        {
            RecordedComponents.Add(key, new(component, null));
        }
    }

    public static void StoreComponentNonExisting<T>(int entityId) where T : IComponent
    {
        if (Active) return;
        ComponentRef key = new(entityId, typeof(T));

        if (!RecordedComponents.ContainsKey(key))
            RecordedComponents.Add(key, new(null, null));
    }

    public static bool ShouldUpdateEntity(EntityData data)
    {
        return !Active || data.Has<TimelessComponent>();
    }
}

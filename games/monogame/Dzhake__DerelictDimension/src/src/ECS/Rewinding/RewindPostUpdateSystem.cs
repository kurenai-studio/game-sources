using Friflo.Engine.ECS.Systems;
using Monod.InputModule;
using System.Collections.Generic;

namespace DerelictDimension.ECS.Rewinding;

public class RewindPostUpdateSystem : BaseSystem
{
    public List<List<StoredComponent>> StoredComponents;
    public EntityStore Store;
    public static int LastValidFrame;

    public RewindPostUpdateSystem()
    {
        LastValidFrame = 0;
        Rewind.RewindSpeed = -1;
    }

    protected override void OnAddStore(EntityStore store)
    {
        StoredComponents = new();
        Store = store;
        base.OnAddStore(store);
    }

    protected override void OnUpdateGroup()
    {
        if (Rewind.Active)
        {
            int framesToRewind = Rewind.RewindSpeed;
            if (Input.KeyPressed(Key.W)) framesToRewind++;
            if (Input.KeyPressed(Key.Q)) framesToRewind--;

            int framesSign = Math.Sign(framesToRewind);
            while (framesToRewind != 0 && (Rewind.CurrentFrame > 0 || framesSign == 1) && (Rewind.CurrentFrame < LastValidFrame || framesSign == -1))
            {
                Rewind.CurrentFrame += framesSign;
                framesToRewind -= framesSign;
                foreach (StoredComponent stored in StoredComponents[Rewind.CurrentFrame])
                    stored.Set(Store);
            }
        }
        else
        {
            if (Rewind.CurrentFrame >= StoredComponents.Count)
            {
                StoredComponents.Add(new());
            }
            else
            {
                StoredComponents[Rewind.CurrentFrame].Clear();
            }

            // record components that were stored in previous frame and that are different now.
            if (Rewind.CurrentFrame > 0)
            {
                foreach (StoredComponent oldStored in StoredComponents[Rewind.CurrentFrame - 1])
                {
                    var oldRef = oldStored.ToComponentRef();
                    if (!Rewind.RecordedComponents.ContainsKey(oldRef))
                    {
                        if (oldRef.ComponentType == null)
                        {
                            Entity entity = Store.GetEntityById(oldRef.EntityId);
                            if (oldStored.EnableEntity != entity.Enabled)
                                Rewind.RecordedComponents.Add(oldRef, new(null, entity.Enabled, true));
                            continue;
                        }

                        var currentValue = oldRef.Get(Store);
                        if (currentValue?.Equals(oldStored.Component) != true)
                            Rewind.RecordedComponents.Add(oldRef, new(currentValue, null, true));
                    }
                }
            }

            foreach (var (componentRef, recorded) in Rewind.RecordedComponents)
            {
                // entity was disabled/enabled ('deleted'/'added')
                if (componentRef.ComponentType == null)
                {
                    Entity entity = Store.GetEntityById(componentRef.EntityId);
                    bool currentlyEnabled = !entity.IsNull && entity.Enabled;

                    if (recorded.ForceStore || currentlyEnabled != recorded.EnableEntity)
                    {
                        StoreComponent(StoredComponent.EntityChanged(componentRef.EntityId, recorded.EnableEntity ?? currentlyEnabled));
                    }


                    continue;
                }

                // component value changed or component was added/removed
                IComponent? currentValue = componentRef.Get(Store);
                bool currentlyHasComponent = currentValue != null;
                IComponent? recordedComponent = recorded.Component;


                bool componentStateChanged = false;
                if (recordedComponent == null)
                {
                    componentStateChanged = currentlyHasComponent;
                }
                else if (recordedComponent != null)
                {
                    if (!recordedComponent.Equals(currentValue))
                        componentStateChanged = true;
                }

                if (recorded.ForceStore || componentStateChanged)
                {
                    if (recordedComponent != null)
                        StoreComponent(StoredComponent.ComponentChangedOrAdded(componentRef.EntityId, recordedComponent));
                    else
                        StoreComponent(StoredComponent.NoComponent(componentRef.EntityId, componentRef.ComponentType));
                }

            }

            Rewind.RecordedComponents.Clear();
            Rewind.CurrentFrame++;
        }
        base.OnUpdateGroup();
    }

    private void StoreComponent(StoredComponent stored)
    {
        StoredComponents[Rewind.CurrentFrame].Add(stored);
    }
}

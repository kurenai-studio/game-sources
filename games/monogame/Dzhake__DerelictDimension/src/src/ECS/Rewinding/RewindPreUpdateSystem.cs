using Friflo.Engine.ECS.Systems;
using Monod.InputModule;

namespace DerelictDimension.ECS.Rewinding;

public class RewindPreUpdateSystem : BaseSystem
{
    public EntityStore Store;
    public ArchetypeQuery NotRegisteredAsCreatedQuery;
    public ArchetypeQuery<CreatedAtComponent> CreatedAtQuery;
    public CommandBuffer cb;

    protected override void OnAddStore(EntityStore store)
    {
        base.OnAddStore(store);
        Store = store;
        cb = store.GetCommandBuffer();
        cb.ReuseBuffer = true;
        NotRegisteredAsCreatedQuery = store.Query().WithoutAllComponents(ComponentTypes.Get<CreatedAtComponent>()).WithDisabled();
        CreatedAtQuery = store.Query<CreatedAtComponent>().WithDisabled();
    }

    protected override void OnUpdateGroup()
    {
        base.OnUpdateGroup();

        foreach (Entity entity in NotRegisteredAsCreatedQuery.Entities)
            cb.AddComponent<CreatedAtComponent>(entity.Id, new CreatedAtComponent());
        cb.Playback();

        bool enableRewind = Rewind.Active;
        if (Input.KeyPressed(Key.LeftShift))
            enableRewind = !enableRewind;
        ref int rewindSpeed = ref Rewind.RewindSpeed;

        // set default value when rewind is not active
        if (!Rewind.Active)
        {
            rewindSpeed = -1;
        }

        // when rewind starts, very last frame becomes invalid, so we need to exclude it.
        if (enableRewind && !Rewind.Active)
        {
            RewindPostUpdateSystem.LastValidFrame = Rewind.CurrentFrame - 1;
        }

        if (!enableRewind && Rewind.Active)
        {
            CreatedAtQuery.ForEachEntity(CleanupEntity);
        }

        if (enableRewind && Input.KeyPressed(Key.Up))
        {
            if (rewindSpeed == -1 || rewindSpeed == 0) rewindSpeed++;
            else if (rewindSpeed < 0) rewindSpeed /= 2;
            else rewindSpeed *= 2;
        }

        if (enableRewind && Input.KeyPressed(Key.Down))
        {
            if (rewindSpeed == 1 || rewindSpeed == 0) rewindSpeed--;
            else if (rewindSpeed < 0) rewindSpeed *= 2;
            else rewindSpeed /= 2;
        }
        Rewind.Active = enableRewind;
    }

    private void CleanupEntity(ref CreatedAtComponent createdAt, Entity entity)
    {
        if (createdAt.Frame > Rewind.CurrentFrame)
            entity.DeleteEntity();
    }
}

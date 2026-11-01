using Friflo.Engine.ECS.Systems;
using System.Collections.Generic;

namespace DerelictDimension.ECS.Prefabs;

public sealed class CannonSystem : QuerySystem<CannonComponent, CannonInfoComponent>
{
    private List<Entity> ToShoot = [];
    public EntityStore Store;

    protected override void OnAddStore(EntityStore store)
    {
        Store = store;
        base.OnAddStore(store);
    }

    protected override void OnUpdate()
    {
        /*Query.ForEachEntity(UpdateCannon);

        foreach (var entity in ToShoot)
        {
            var data = entity.Data;
            if (!data.Has<CannonInfoComponent>() || !data.Has<Transform2D>()) continue;

            ref var cannonInfo = ref data.Get<CannonInfoComponent>();
            if (cannonInfo.Prefab is null) continue;
            ref var transform = ref data.Get<Transform2D>();

            var instance = cannonInfo.Prefab.Instantiate(Store);
            Rewind.StoreEntityUpdated(instance, false);

            var instanceData = instance.Data;
            if (instanceData.Has<Transform2D>())
            {
                ref var instanceTransform = ref instanceData.Get<Transform2D>();
                instanceTransform.Position = transform.Position;
            }

            if (instanceData.Has<MobileComponent>())
            {
                ref var instanceMobile = ref instanceData.Get<MobileComponent>();

                Vector2 projectileVelocity = MathM.VectorRight;
                projectileVelocity.Rotate(transform.GetFlippedRotation());
                projectileVelocity *= cannonInfo.ProjectileVelocity;
                instanceMobile.Velocity = projectileVelocity;
            }
        }

        ToShoot.Clear();
        ToShoot.Capacity = 4;*/
    }

    private void UpdateCannon(ref CannonComponent cannon, ref CannonInfoComponent cannonInfo, Entity cannonEnt)
    {
        /*if (cannonInfo.Prefab is null || Assets.ReloadThisFrame)
        {
            cannonInfo.Prefab = Assets.Get<PrefabAsset>(cannonInfo.PrefabPath);
        }

        if (!Rewind.ShouldUpdateEntity(cannonEnt.Data)) return;
        Rewind.StoreComponentUpdated(cannonEnt.Id, ref cannon);

        cannon.TimeUntilNextShot -= Time.DeltaTime;
        if (cannon.TimeUntilNextShot <= 0)
        {
            cannon.TimeUntilNextShot += cannonInfo.FiringInterval;
            ToShoot.Add(cannonEnt);
        }*/
    }

}


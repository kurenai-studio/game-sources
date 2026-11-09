using Unity.Burst;
using Unity.Collections;
using Unity.Collections.LowLevel.Unsafe;
using Unity.Entities;
using Unity.Jobs;
using Unity.Mathematics;
using Unity.Physics;
using Unity.Physics.Systems;
using Unity.Transforms;
using Unity.Rendering;

[UpdateAfter(typeof(BuildPhysicsWorld))]
public class EnemySystem : JobComponentSystem
{
    BuildPhysicsWorld physicsWorldSystem;
    EntityCommandBufferSystem buffer;
    Entity lazerPrefab;
    Entity explosionPrefab;
    EnemySettings settings;

    //[BurstCompile]
    struct EnemySystemJob : IJobForEachWithEntity<Translation, Enemy>
    {
        public float deltaTime;
        public uint mask;
        public EntityCommandBuffer.Concurrent cmd;
        [ReadOnly] public CollisionWorld world;
        public Entity lazerPrefab;
        public Entity explosionPrefab;

        public void Execute(Entity ent, int index, [ReadOnly] ref Translation translation, ref Enemy enemy)
        {
            enemy.timer -= deltaTime;
            var input = new PointDistanceInput()
            {
                MaxDistance = enemy.rangeDie,
                Filter = new CollisionFilter() { CategoryBits = mask, MaskBits = mask, GroupIndex = 0 },
                Position = translation.Value
            };
            DistanceHit hit;
            if (world.CalculateDistance(input, out hit)) {
                cmd.DestroyEntity(index, ent);
                cmd.DestroyEntity(index, world.Bodies[hit.RigidBodyIndex].Entity);
                var e = cmd.Instantiate(index, explosionPrefab);
                cmd.SetComponent(index, e, new Translation() { Value = hit.Position });
            } else if (enemy.timer < 0) {
                input.MaxDistance = enemy.rangeShoot;
                if (world.CalculateDistance(input, out hit)) {
                    var dir = hit.Position - translation.Value;
                    dir *= enemy.rangeShoot / math.length(dir) * 0.5f;
                    cmd.DestroyEntity(index, world.Bodies[hit.RigidBodyIndex].Entity);
                    var e = cmd.Instantiate(index, lazerPrefab);
                    cmd.SetComponent(index, e, new Translation() { Value = translation.Value + dir });
                    cmd.SetComponent(index, e, new Rotation() { Value = quaternion.RotateZ(math.atan2(dir.y, dir.x)) });
                    enemy.timer = enemy.cooldown;
                }
            }
        }
    }

    protected void Setup() {
        physicsWorldSystem = EntityManager.World.GetOrCreateSystem<BuildPhysicsWorld>();
        settings = UnityEngine.GameObject.FindObjectOfType<EnemySettings>();
        buffer = EntityManager.World.GetOrCreateSystem<EndSimulationEntityCommandBufferSystem>();
        lazerPrefab = GameObjectConversionUtility.ConvertGameObjectHierarchy(settings.lazerPrefab, World);
        explosionPrefab = GameObjectConversionUtility.ConvertGameObjectHierarchy(settings.explosionPrefab, World);
    }
    
    protected override JobHandle OnUpdate(JobHandle inputDependencies)
    {
        if (!settings) Setup();
        var job = new EnemySystemJob() {
            deltaTime = UnityEngine.Time.deltaTime,
            world = physicsWorldSystem.PhysicsWorld.CollisionWorld,
            mask = (uint)settings.blobShape.BelongsTo,
            cmd = buffer.CreateCommandBuffer().ToConcurrent(),
            lazerPrefab = lazerPrefab,
            explosionPrefab = explosionPrefab
        };
        var jh = JobHandle.CombineDependencies(inputDependencies, physicsWorldSystem.FinalJobHandle);
        jh = job.Schedule(this, jh);
        buffer.AddJobHandleForProducer(jh);
        return jh;
    }
}
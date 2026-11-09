using Unity.Burst;
using Unity.Collections;
using Unity.Entities;
using Unity.Jobs;
using Unity.Mathematics;
using Unity.Physics;
using Unity.Transforms;

public class OrbiterSystem : JobComponentSystem
{

    [BurstCompile]
    struct OrbiterSystemJob : IJobForEach<Translation, Rotation, Orbiter>
    {
        public float deltaTime;
        
        public void Execute(ref Translation translation, ref Rotation rotation, [ReadOnly] ref Orbiter orbiter)
        {
            var pos = translation.Value;
            var cen = orbiter.center;
            var acc = cen - pos;
            float angle = math.atan2(acc.y, acc.x);
            float tangle = angle + math.PI * 2 / orbiter.period * deltaTime;
            var acc2 = new float3(math.cos(tangle) * orbiter.distance, math.sin(tangle) * orbiter.distance, 0);
            var target = cen - acc2;
            var dir = target - pos;
            translation.Value = target;
            rotation.Value = quaternion.RotateZ(math.atan2(dir.y, dir.x));
        }
    }
    
    protected override JobHandle OnUpdate(JobHandle inputDependencies)
    {
        var job = new OrbiterSystemJob() { deltaTime = UnityEngine.Time.deltaTime };
        return job.Schedule(this, inputDependencies);
    }
}
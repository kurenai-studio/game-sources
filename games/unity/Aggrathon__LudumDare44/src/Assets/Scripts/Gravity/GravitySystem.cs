using Unity.Burst;
using Unity.Collections;
using Unity.Entities;
using Unity.Jobs;
using Unity.Mathematics;
using Unity.Transforms;
using static Unity.Mathematics.math;
using Unity.Physics;
using UnityEngine;

[UpdateAfter(typeof(Unity.Physics.Systems.EndFramePhysicsSystem))]
public class GravitySystem : JobComponentSystem
{
    VectorField vectorField;
    
    [BurstCompile]
    struct GravitySystemJob : IJobForEach<Translation, PhysicsVelocity>
    {
        [ReadOnly] public NativeArray<float3> vectorField;
        public int size;
        public float radius;
        public float spacing;
        public float deltaTime;

        public void Execute(ref Translation translation,  ref PhysicsVelocity gravity)
        {
            float x = clamp((translation.Value.x + radius) / spacing, 0, size - 1);
            float y = clamp((translation.Value.y + radius) / spacing, 0, size - 1);
            gravity.Linear += vectorField[(int)round(x) + (int)round(y) * size] * deltaTime;
            gravity.Linear.z = 0;
            gravity.Angular.x = 0;
            gravity.Angular.y = 0;
            //gravity.Angular.z = gravity.Angular.z * 0.1f;
            translation.Value.z = 0;
        }
    }
    
    protected override JobHandle OnUpdate(JobHandle inputDependencies)
    {
        if (!vectorField)
            vectorField = GameObject.FindObjectOfType<VectorField>();
        var job = new GravitySystemJob() {
            vectorField = vectorField.vectors,
            radius = vectorField.radius,
            spacing = vectorField.spacing,
            size = (int)(vectorField.radius * 2 / vectorField.spacing),
            deltaTime = Time.fixedDeltaTime
        };
        return job.Schedule(this, inputDependencies);
    }
}
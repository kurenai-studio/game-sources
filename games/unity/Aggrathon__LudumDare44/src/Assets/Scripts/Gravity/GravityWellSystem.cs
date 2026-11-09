using Unity.Burst;
using Unity.Collections;
using Unity.Entities;
using Unity.Jobs;
using Unity.Mathematics;
using Unity.Transforms;
using static Unity.Mathematics.math;
using UnityEngine;

public class GravityWellSystem : JobComponentSystem
{
    VectorField vectorField;
    
    [BurstCompile]
    struct GravityWellSystemJob : IJobForEach<Translation, GravityWell>
    {
        [WriteOnly] public NativeArray<float3> vectorField;
        [ReadOnly] public NativeArray<float3> reset;
        public float radius;
        public float spacing;
        public int size;
        
        public void Execute([ReadOnly] ref Translation translation, ref GravityWell well)
        {
            int newIndex = -1;
            if (well.enabled) {
                float x = clamp((translation.Value.x + radius) / spacing, 0, size - 1);
                float y = clamp((translation.Value.y + radius) / spacing, 0, size - 1);
                newIndex = (int)round(x) + (int)round(y) * size;
            }
            
            if (well.lastIndex > -1 && well.lastIndex != newIndex) {
                for (int i = max(0, well.lastIndex-well.range); i < min(vectorField.Length, well.lastIndex + well.range + 1); i++)
                {
                    for (int j = -well.range; j < well.range + 1; j++)
                    {
                        var index = i + j * size;
                        if (index >= vectorField.Length)
                            break;
                        else if (index >= 0)
                            vectorField[index] = reset[index];
                    }
                }
            }
            if (newIndex > -1) {
                for (int i = max(0, newIndex-well.range); i < min(vectorField.Length, newIndex + well.range + 1); i++)
                {
                    int i2 = i - newIndex;
                    for (int j = -well.range; j < well.range + 1; j++)
                    {
                        var index = i + j * size;
                        if (index >= vectorField.Length)
                            break;
                        else if (index >= 0 && i2*i2 + j*j <= well.range * well.range) {
                            vectorField[index] = new float3(-i2, -j, 0) * well.strength;
                        }
                    }
                }
            }
            well.lastIndex = newIndex;
        }
    }
    
    protected override JobHandle OnUpdate(JobHandle inputDependencies)
    {
        if (!vectorField)
            vectorField = GameObject.FindObjectOfType<VectorField>();
        var job = new GravityWellSystemJob() {
            vectorField = vectorField.vectors,
            reset = vectorField.reset,
            size = vectorField.size,
            spacing = vectorField.spacing,
            radius = vectorField.radius
        };
        return job.ScheduleSingle(this, inputDependencies);
    }
}
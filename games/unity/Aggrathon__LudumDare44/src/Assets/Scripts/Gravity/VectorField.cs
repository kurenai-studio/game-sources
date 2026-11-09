using System.Collections;
using System.Collections.Generic;
using System.Runtime.CompilerServices;
using UnityEngine;
using Unity.Collections;
using Unity.Mathematics;
using Unity.Jobs;
using Unity.Burst;
using Unity.Entities;
using Unity.Transforms;

public class VectorField : MonoBehaviour
{
    public float radius = 17f;
    public float spacing = 0.25f;

    public NativeArray<float3> vectors;
    public NativeArray<float3> reset;
    
    CalcVector job;
    JobHandle jobH;

    [System.NonSerialized] public int size;


    [BurstCompile]
    struct CalcVector : IJobParallelFor
    {
        [ReadOnly] public NativeArray<Translation> positions;
        [ReadOnly] public NativeArray<Gravity> masses;
        [WriteOnly] public NativeArray<float3> vectors;

        public float radius;
        public float spacing;

        public int width;

        public void Execute(int index)
        {
            float3 pos = new float3(
                -radius + (int)(index % width) * spacing,
                -radius + (int)(index / width) * spacing,
                0);
            float3 vec = new float3(0, 0, 0);
            for (int i = 0; i < positions.Length; i++)
            {
                float3 dir = positions[i].Value - pos;
                float magn = math.length(dir);
                if (magn > masses[i].minDist)
                    vec += dir / math.pow(magn, 3) * masses[i].mass;
            }
            vectors[index] = vec;
        }
    }

    private void Awake() {
        size = (int) (radius * 2 / spacing);
        vectors = new NativeArray<float3>(size * size, Allocator.Persistent);
        reset = new NativeArray<float3>(size * size, Allocator.Persistent);
        var query = World.Active.EntityManager.CreateEntityQuery(typeof(Translation), typeof(Gravity));
        JobHandle handle1;
        JobHandle handle2;
        job.vectors = vectors;
        job.radius = radius;
        job.width = size;
        job.spacing = spacing;
        job.positions = query.ToComponentDataArray<Translation>(Allocator.TempJob, out handle1);
        job.masses = query.ToComponentDataArray<Gravity>(Allocator.TempJob, out handle2);
        jobH = job.Schedule(vectors.Length, 32, JobHandle.CombineDependencies(handle1, handle2));
    }

    void Start()
    {
        jobH.Complete();
        job.positions.Dispose();
        job.masses.Dispose();
        reset.CopyFrom(vectors);
        enabled = false;
    }

    private void OnDestroy() {
        vectors.Dispose();
        reset.Dispose();
    }

    private void OnDrawGizmosSelected() {
        int size = (int) (radius * 2 / spacing);
        Gizmos.color = Color.green;
        for (int i = 0; i < vectors.Length; i++)
        {
            float3 pos = new float3(-radius + (int)(i % size) * spacing, -radius + (int)(i / size) * spacing, 0);
            Gizmos.DrawLine(pos, pos + vectors[i] / math.length(vectors[i]) * spacing);
        }
    }

    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static int CoordToIndex(float3 pos, float radius, float spacing, int size) {
        float x = math.clamp((pos.x + radius) / spacing, 0, size - 1);
        float y = math.clamp((pos.y + radius) / spacing, 0, size - 1);
        return (int)math.round(x) + (int)math.round(y) * size;
    }

    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static float3 CoordToVec(float3 pos, float radius, float spacing, int size, NativeArray<float3> vectors) {
        return vectors[CoordToIndex(pos, radius, spacing, size)];
    }

    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static float3 IndexToCoord(int index, float radius, float spacing, int size) {
        return new float3(
            -radius + (int)(index % size) * spacing,
            -radius + (int)(index / size) * spacing,
            0);
    }

    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static float3 IndexToVec(int index, NativeArray<float3> vectors) {
        return vectors[index];
    }
}

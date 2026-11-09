using System.Collections;
using System.Collections.Generic;
using Unity.Burst;
using Unity.Collections;
using Unity.Jobs;
using Unity.Physics;
using Unity.Mathematics;
using Unity.Entities;
using Unity.Collections.LowLevel.Unsafe;

public static class PhysicsCasting
{
     [BurstCompile]
    public struct RaycastJob : IJobParallelFor
    {
        [ReadOnly] public CollisionWorld world;
        [ReadOnly] public NativeArray<RaycastInput> inputs;
        public NativeArray<RaycastHit> results;

        public unsafe void Execute(int index)
        {
            RaycastHit hit;
            if(!world.CastRay(inputs[index], out hit)) hit = new RaycastHit() { RigidBodyIndex = -1 };
            results[index] = hit;
        }
    }

    public static JobHandle ScheduleBatchRayCast(CollisionWorld world, NativeArray<RaycastInput> inputs, NativeArray<RaycastHit> results)
    {
        JobHandle rcj = new RaycastJob
        {
            inputs = inputs,
            results = results,
            world = world

        }.Schedule(inputs.Length, 5);
        return rcj;
    }

    [BurstCompile]
    public struct RaycastJobSingle : IJob
    {
        [ReadOnly] public CollisionWorld world;
        [ReadOnly] public RaycastInput input;
        public RaycastHit result;
        public bool hit;

        public unsafe void Execute()
        {
            hit = world.CastRay(input, out result);
        }
    }

    public static bool SingleRayCast(CollisionWorld world, RaycastInput input, out RaycastHit result)
    {
        var job = new RaycastJobSingle
        {
            input = input,
            world = world

        };
        job.Schedule().Complete();
        result = job.result;
        return job.hit;
    }

    public static void SingleRayCast2(CollisionWorld world, RaycastInput input, out RaycastHit result)
    {
        var rayCommands = new NativeArray<RaycastInput>(1, Allocator.TempJob);
        var rayResults = new NativeArray<RaycastHit>(1, Allocator.TempJob);
        rayCommands[0] = input;
        var handle = ScheduleBatchRayCast(world, rayCommands, rayResults);
        handle.Complete();
        result = rayResults[0];
        rayCommands.Dispose();
        rayResults.Dispose();
    }


    public unsafe static void SphereCastAll(CollisionWorld world, float radius, uint mask, float3 origin, float3 direction, NativeList<ColliderCastHit> results) {
        var sphereCollider = Unity.Physics.SphereCollider.Create(float3.zero, radius,
            new CollisionFilter() { CategoryBits = mask, MaskBits = mask, GroupIndex = (int)mask});
        ColliderCastInput input = new ColliderCastInput()
        {
            Position  = origin,
            Orientation = quaternion.identity,
            Direction = direction,
            Collider = (Collider*)sphereCollider.GetUnsafePtr()
        };
        world.CastCollider(input, ref results);
    }

    public unsafe static ColliderCastHit SphereCast(CollisionWorld world, float radius, uint mask, float3 origin, float3 direction) {
        var sphereCollider = Unity.Physics.SphereCollider.Create(float3.zero, radius,
            new CollisionFilter() { CategoryBits = mask, MaskBits = mask, GroupIndex = (int)mask});
        ColliderCastInput input = new ColliderCastInput()
        {
            Position  = origin,
            Orientation = quaternion.identity,
            Direction = direction,
            Collider = (Collider*)sphereCollider.GetUnsafePtr()
        };
        ColliderCastHit hit = new ColliderCastHit() { RigidBodyIndex = -1 };
        world.CastCollider(input, out hit);
        return hit;
    }

    public unsafe static void ColliderRange(CollisionWorld world, float radius, Collider coll, RigidTransform trans, ref NativeList<DistanceHit> hits) {
        ColliderDistanceInput input = new ColliderDistanceInput()
        {
            MaxDistance = radius,
            Collider = &coll,
            Transform = trans
        };
        world.CalculateDistance(input, ref hits);
    }

    
    [BurstCompile]
    public struct PointRangeJob : IJob
    {
        [ReadOnly] public CollisionWorld world;
        [ReadOnly] public PointDistanceInput input;
        public NativeList<DistanceHit> result;

        public unsafe void Execute()
        {
            world.CalculateDistance(input, ref result);
        }
    }

    public unsafe static void PointRange(CollisionWorld world, float radius, uint mask, float3 pos, ref NativeList<DistanceHit> hits) {
        PointDistanceInput input = new PointDistanceInput()
        {
            MaxDistance = radius,
            Filter = new CollisionFilter() { CategoryBits = mask, MaskBits = mask, GroupIndex = 0 },
            Position = pos
        };
        world.CalculateDistance(input, ref hits);
    }

    public unsafe static void PointRange2(CollisionWorld world, float radius, uint mask, float3 pos, ref NativeList<DistanceHit> hits) {
        var job = new PointRangeJob() {
            world = world,
            result = hits,
            input = new PointDistanceInput()
            {
                MaxDistance = radius,
                Filter = new CollisionFilter() { CategoryBits = mask, MaskBits = mask, GroupIndex = 0 },
                Position = pos
            }
        };
        job.Schedule().Complete();
    }

    [BurstCompile]
    public struct PointRangeSingleJob : IJob
    {
        [ReadOnly] public CollisionWorld world;
        [ReadOnly] public PointDistanceInput input;
        public DistanceHit result;
        public bool hit;

        public unsafe void Execute()
        {
            DistanceHit dh;
            hit = world.CalculateDistance(input, out dh);
            result = dh;
        }
    }

    public unsafe static bool PointRangeSingle(CollisionWorld world, float radius, uint mask, float3 pos, out DistanceHit hit) {
        var job = new PointRangeSingleJob() {
            world = world,
            input = new PointDistanceInput()
            {
                MaxDistance = radius,
                Filter = new CollisionFilter() { CategoryBits = mask, MaskBits = mask, GroupIndex = 0 },
                Position = pos
            }
        };
        job.Schedule().Complete();
        hit = job.result;
        return job.hit;
    }

    [BurstCompile]
    public struct PointRangesJob : IJobParallelFor
    {
        [ReadOnly] public CollisionWorld world;
        [ReadOnly] public NativeArray<PointDistanceInput> inputs;
        public NativeArray<DistanceHit> results;

        public unsafe void Execute(int index)
        {
            DistanceHit hit;
            if (!world.CalculateDistance(inputs[index], out hit))
                hit = new DistanceHit() { RigidBodyIndex = -1 };
            results[index] = hit;
        }
    }

    public unsafe static JobHandle PointRanges(CollisionWorld world, NativeArray<PointDistanceInput> inputs, NativeArray<DistanceHit> hits) {
        var job = new PointRangesJob() {
            world = world,
            inputs = inputs,
            results = hits
        };
        return job.Schedule(inputs.Length, 4);
    }

    public unsafe static bool PointRangeSingle2(CollisionWorld world, float radius, uint mask, float3 pos, out DistanceHit hit) {
        var rayCommands = new NativeArray<PointDistanceInput>(1, Allocator.TempJob);
        var rayResults = new NativeArray<DistanceHit>(1, Allocator.TempJob);
        rayCommands[0] = new PointDistanceInput()
        {
            MaxDistance = radius,
            Filter = new CollisionFilter() { CategoryBits = mask, MaskBits = mask, GroupIndex = 0 },
            Position = pos
        };
        var handle = PointRanges(world, rayCommands, rayResults);
        handle.Complete();
        hit = rayResults[0];
        rayCommands.Dispose();
        rayResults.Dispose();
        return hit.RigidBodyIndex != -1;
    }
}

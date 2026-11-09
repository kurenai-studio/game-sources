using Unity.Burst;
using Unity.Collections;
using Unity.Entities;
using Unity.Jobs;
using Unity.Mathematics;
using Unity.Transforms;
using Unity.Physics;

public class NavigatorSystem : JobComponentSystem
{
    
    [BurstCompile]
    struct NavigatorSystemJob : IJobForEach<Translation, Rotation, Navigator, PhysicsVelocity>
    {
        [ReadOnly] public NativeArray<float3> vectorField;
        public float spacing;
        public float radius;
        public int size;
        public float deltaTime;
        
        public void Execute(ref Translation translation, ref Rotation rotation, ref Navigator nav, ref PhysicsVelocity vel)
        {
            if (nav.pause) return;
            var dir = nav.target - translation.Value;
            dir *= spacing * 1.5f / math.length(dir);
            var dir2a = math.rotate(quaternion.RotateZ(math.PI/4.4f), dir);
            var dir2b = math.rotate(quaternion.RotateZ(-math.PI/4.4f), dir);
            var dir3a = math.rotate(quaternion.RotateZ(math.PI/2.2f), dir);
            var dir3b = math.rotate(quaternion.RotateZ(-math.PI/2.2f), dir);
            var val =   math.lengthsq(VectorField.CoordToVec(translation.Value + dir, radius, spacing, size, vectorField));
            var val2a = math.lengthsq(VectorField.CoordToVec(translation.Value + dir2a, radius, spacing, size, vectorField));
            var val2b = math.lengthsq(VectorField.CoordToVec(translation.Value + dir2b, radius, spacing, size, vectorField));
            var val3a = math.lengthsq(VectorField.CoordToVec(translation.Value + dir3a, radius, spacing, size, vectorField));
            var val3b = math.lengthsq(VectorField.CoordToVec(translation.Value + dir3b, radius, spacing, size, vectorField));
            float div = - (val + val2a + val2b + val3a + val3b) / (nav.avoidance + 1);
            val = val / div + 1.5f;
            val2a = val2a / div + 1f;
            val2b = val2b / div + 1f;
            val3a = val3a / div;
            val3b = val3b / div;
            if (val2a > val) {
                val = val2a;
                dir = dir2a;
            }
            if (val2b > val) {
                val = val2b;
                dir = dir2b;
            }
            if (val3a > val) {
                val = val3a;
                dir = dir3a;
            }
            if (val3b > val) {
                val = val3b;
                dir = dir3b;
            }
            rotation.Value = math.nlerp(rotation.Value, quaternion.RotateZ(math.atan2(dir.y, dir.x)), deltaTime * nav.turning);
            vel.Angular = float3.zero;
            vel.Linear = dir * (deltaTime * nav.speed / (spacing * 1.5f));
        }
    }

    VectorField vectorField;
    
    protected override JobHandle OnUpdate(JobHandle inputDependencies)
    {
        if (!vectorField)
            vectorField = UnityEngine.GameObject.FindObjectOfType<VectorField>();
        var job = new NavigatorSystemJob() {
            vectorField = vectorField.reset,
            spacing = vectorField.spacing,
            radius = vectorField.radius,
            size = vectorField.size,
            deltaTime = UnityEngine.Time.deltaTime
        };
        return job.Schedule(this, inputDependencies);
    }
}
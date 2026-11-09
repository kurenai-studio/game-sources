using System;
using Unity.Collections;
using Unity.Entities;
using Unity.Mathematics;
using UnityEngine;

[Serializable]
public struct Orbiter : IComponentData
{
    public float period;
    public float3 center;
    public float distance;
}

public class OrbiterProxy : ComponentDataProxy<Orbiter>
{
    private void OnDrawGizmos() {
        Gizmos.color = Color.blue;
        Gizmos.DrawWireSphere(Value.center, Value.distance);
    }
}

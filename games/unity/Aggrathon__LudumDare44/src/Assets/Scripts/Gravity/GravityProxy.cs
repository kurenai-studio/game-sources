using System;
using Unity.Collections;
using Unity.Entities;
using Unity.Mathematics;

[Serializable]
public struct Gravity : IComponentData
{
    public float mass;
    public float minDist;
}

public class GravityProxy : ComponentDataProxy<Gravity> {}

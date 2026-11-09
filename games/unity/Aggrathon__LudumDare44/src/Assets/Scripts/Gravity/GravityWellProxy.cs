using System;
using Unity.Collections;
using Unity.Entities;
using Unity.Mathematics;

[Serializable]
public struct GravityWell : IComponentData
{
    public bool enabled;
    public int lastIndex;
    public int range;
    public float strength;

    public GravityWell(float size, float spacing, bool enabled = true, float strength = 0.75f) {
        this.enabled = enabled;
        lastIndex = -1;
        range = (int)(size / spacing);
        this.strength = strength;
    }
}

public class GravityWellProxy : ComponentDataProxy<GravityWell> {}
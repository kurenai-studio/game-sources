using System;
using Unity.Collections;
using Unity.Entities;
using Unity.Mathematics;

[Serializable]
public struct SoundDestroy : IComponentData
{
    public float time;
    public int soundId;
}

public class SoundDestroyProxy : ComponentDataProxy<SoundDestroy> {}

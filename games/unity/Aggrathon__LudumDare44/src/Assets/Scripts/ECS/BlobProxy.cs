using System;
using Unity.Collections;
using Unity.Entities;
using Unity.Mathematics;

[Serializable]
public struct Blob : IComponentData
{
}

public class BlobProxy : ComponentDataProxy<Blob>
{
}

using System;
using Unity.Collections;
using Unity.Entities;
using Unity.Mathematics;

[Serializable]
public struct TransportShip : IComponentData
{
    [NonSerialized] public Entity target;
    public float minDist;
    public int inventory;
    public Asteroid.Resource resource;
}

public class TransportShipProxy : ComponentDataProxy<TransportShip>
{
}

using System;
using Unity.Collections;
using Unity.Entities;
using Unity.Mathematics;
using UnityEngine;

[Serializable]
public struct Asteroid : IComponentData
{
    public enum Resource {
        Iron,
        Water,
        Aluminium
    }

    public Resource resource;
    public int stock;
    public int mines;
    public int minerals;
    [NonSerialized] public int index;
    public int minShipTicks;
    [NonSerialized] public int shipTicks;
}

public class AsteroidProxy : ComponentDataProxy<Asteroid> {

}
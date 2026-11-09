using System;
using Unity.Collections;
using Unity.Entities;
using Unity.Mathematics;

[Serializable]
public struct Enemy : IComponentData
{
    public float rangeShoot;
    public float rangeDie;

    public float cooldown;
    [NonSerialized] public float timer;
}

public class EnemyProxy : ComponentDataProxy<Enemy>
{
}

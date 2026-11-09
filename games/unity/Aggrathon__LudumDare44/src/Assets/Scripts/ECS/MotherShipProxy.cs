using System;
using Unity.Collections;
using Unity.Entities;
using Unity.Mathematics;
using UnityEngine;

[Serializable]
public struct MotherShip : IComponentData
{
    [Header("Movement")]
    public float3 pos1;
    public float3 pos2;
    public float3 pos3;
    public float3 pos4;

    public float speed;
    public int current;
    public float lerp;

    [Header("Spawning")]
    public float delay;
    public float range;
    [NonSerialized] public float timer;

    public float3 GetPos(int index) {
        switch (index % 4) {
            case 0:
                return pos1;
            case 1:
                return pos2;
            case 2:
                return pos3;
            case 3:
                return pos4;
            default:
                return pos1;
        }
    }

}

public class MotherShipProxy : ComponentDataProxy<MotherShip>
{
    private void OnDrawGizmos() {
        Gizmos.color = Color.yellow;
        Gizmos.DrawWireSphere(Value.pos1, 0.5f);
        Gizmos.DrawWireSphere(Value.pos2, 0.5f);
        Gizmos.DrawWireSphere(Value.pos3, 0.5f);
        Gizmos.DrawWireSphere(Value.pos4, 0.5f);
    }
}

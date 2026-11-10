using m039.Common;
using UnityEngine;

public class StartLocation : BaseOrbitObject
{
    void OnDrawGizmosSelected()
    {
        Gizmos.color = Color.blue.WithAlpha(0.4f);
        Gizmos.DrawCube(transform.position, Vector3.one * 1f);
    }
}

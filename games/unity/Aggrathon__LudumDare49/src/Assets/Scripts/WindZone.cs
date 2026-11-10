using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class WindZone : MonoBehaviour
{
    public float radius = 10f;
    public float maxDist = 50f;
    public float windStrength = 1f;
    public int windRaysPerFixedUpdate = 5;

    private void FixedUpdate()
    {
        Vector2 dir = transform.right;
        Vector2 perp = transform.up;
        Vector2 pos = transform.position;
        for (int i = 0; i < windRaysPerFixedUpdate; i++)
        {
            Vector2 start = pos + perp * Random.Range(-radius, radius);
            var hit = Physics2D.Raycast(start, dir, maxDist);
            var rb = hit.rigidbody;
            if (rb && !rb.isKinematic)
            {
                rb.AddForceAtPosition(dir * windStrength, hit.point, ForceMode2D.Force);
            }
        }
    }

    private void OnDrawGizmosSelected()
    {
        Gizmos.color = Color.blue;
        Gizmos.DrawLine(transform.position + transform.up * radius, transform.position + transform.up * radius + transform.right * maxDist);
        Gizmos.DrawLine(transform.position + 0.5f * radius * transform.up, transform.position + 0.5f * radius * transform.up + transform.right * maxDist);
        Gizmos.DrawLine(transform.position, transform.position + transform.right * maxDist);
        Gizmos.DrawLine(transform.position - 0.5f * radius * transform.up, transform.position - 0.5f * radius * transform.up + transform.right * maxDist);
        Gizmos.DrawLine(transform.position - transform.up * radius, transform.position - transform.up * radius + transform.right * maxDist);
        Gizmos.color = Color.red;
        Gizmos.DrawLine(transform.position + radius * transform.up, transform.position - radius * transform.up);
        Gizmos.DrawLine(transform.position + radius * transform.up + 0.1f * transform.right, transform.position - radius * transform.up + 0.1f * transform.right);
    }

    private void OnDrawGizmos()
    {
        Gizmos.DrawIcon(transform.position, "WindZone Gizmo");
    }
}

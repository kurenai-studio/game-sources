using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(Field))]
public class SimpleField : MonoBehaviour
{
    Field field;

    [ContextMenu("Refresh Gizmos")]
    void Start()
    {
        field = GetComponent<Field>();
        var renderer = GetComponent<Renderer>();
        if (renderer != null)
        {
            var bounds = renderer.bounds;
            field.width = Mathf.Abs(bounds.center.x - transform.position.x) * 2 + bounds.size.x;
            field.length = Mathf.Abs(bounds.center.z - transform.position.z) * 2 + bounds.size.z;
        }
        field.SetupGrid((_, _) => true);
    }
}

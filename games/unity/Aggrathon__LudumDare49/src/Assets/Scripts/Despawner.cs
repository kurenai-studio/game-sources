using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;

public class Despawner : MonoBehaviour
{
    public UnityEvent<Vector2> onTrigger;

    private void OnTriggerEnter2D(Collider2D other)
    {
        var rb = other.attachedRigidbody;
        if (rb && rb.gameObject.activeSelf)
        {
            rb.gameObject.SetActive(false);
            Destroy(rb.gameObject);
            onTrigger.Invoke(rb.position);
        }
    }
}

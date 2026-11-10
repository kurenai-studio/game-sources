using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(Rigidbody2D))]
public class Spikes : MonoBehaviour
{
    public AnimationCurve movement;
    public float offset = 0;

    Rigidbody2D rb;
    Vector2 origin;

    void Start()
    {
        rb = GetComponent<Rigidbody2D>();
        origin = rb.position;
    }

    void FixedUpdate()
    {
        rb.MovePosition(origin + (Vector2)transform.up * movement.Evaluate(Time.time + offset));
    }

    private void OnTriggerEnter2D(Collider2D other)
    {
        var chr = other.GetComponent<Destructable>();
        if (chr != null)
        {
            chr.Die();
        }
    }

    private void OnDrawGizmosSelected()
    {
        if (movement.length > 0)
        {
            if (rb == null)
                rb = GetComponent<Rigidbody2D>();
            Gizmos.color = Color.red;
            float min = 0;
            float max = 0;
            foreach (var k in movement.keys)
            {
                if (min > k.value)
                    min = k.value;
                if (max < k.value)
                    max = k.value;
            }
            float h = max - min;
            Vector3 c = rb.centerOfMass;
            c.y = c.y + min + h / 2;
            Gizmos.DrawWireCube(c, new Vector3(1, h + 1, 0));
        }
    }
}

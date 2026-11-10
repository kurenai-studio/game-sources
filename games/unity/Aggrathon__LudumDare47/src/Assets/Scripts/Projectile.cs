using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(Rigidbody2D))]
public class Projectile : MonoBehaviour
{
    public enum OnHit
    {
        Dearm,
        Despawn,
        Stop,
    }

    public OnHit onHit = OnHit.Dearm;
    public bool active = true;
    public float initialVelocity = 0;
    public float fireVelocity = 20f;

    Rigidbody2D rb;

    private void Awake()
    {
        active = true;
        rb = GetComponent<Rigidbody2D>();
    }

    private void OnTriggerEnter2D(Collider2D other)
    {
        if (active)
        {
            var chr = other.GetComponent<Destructable>();
            if (chr != null)
            {
                chr.Die();
            }
            else if (!other.isTrigger)
            {
                switch (onHit)
                {
                    case OnHit.Dearm:
                        rb.velocity = Vector2.zero;
                        active = false;
                        break;
                    case OnHit.Despawn:
                        gameObject.SetActive(false);
                        break;
                    case OnHit.Stop:
                        rb.velocity = Vector2.zero;
                        break;
                }
            }
        }
    }

    public void Fire()
    {
        active = true;
        rb.velocity = transform.right * fireVelocity;
    }

    private void OnDrawGizmosSelected()
    {
        Gizmos.color = Color.red;
        Gizmos.DrawLine(transform.position + transform.right * -0.5f, transform.position + transform.right * 0.5f);
        Gizmos.DrawLine(transform.position + transform.right * 0.5f, transform.position + transform.right * 0.25f + transform.up * 0.25f);
        Gizmos.DrawLine(transform.position + transform.right * 0.5f, transform.position + transform.right * 0.25f + transform.up * -0.25f);
    }
}

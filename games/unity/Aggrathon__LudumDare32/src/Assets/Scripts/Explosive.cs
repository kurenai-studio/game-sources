using UnityEngine;
using System.Collections;

public class Explosive : MonoBehaviour {

    public bool explodeOnCollision = true;
    public float explosionRange = 20f;
    public float explosionDamage = 10f;
    public GameObject explosionPrefab;

    public void Explode()
    {
        SimplePool.Spawn(explosionPrefab, transform.position, transform.rotation);
        foreach (Collider c in Physics.OverlapSphere(transform.position, explosionRange))
        {
            ShipHealth sh = c.transform.GetComponent<ShipHealth>();
            if (sh != null)
                sh.Damage(explosionDamage);
        }
        Rigidbody rb = GetComponent<Rigidbody>();
        if (rb != null)
        {
            rb.AddForce(Vector3.zero, ForceMode.VelocityChange);
            rb.AddTorque(Vector3.zero, ForceMode.VelocityChange);
            rb.velocity = Vector3.zero;
            rb.angularVelocity = Vector3.zero;
        }
        SimplePool.Despawn(gameObject);
    }

    public void OnCollisionEnter(Collision collision)
    {
        if (explodeOnCollision)
            Explode();
    }

}

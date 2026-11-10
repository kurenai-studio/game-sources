using UnityEngine;
using System.Collections;

public class AutoCannon : MonoBehaviour {

    public GameObject round;
    public GameObject muzzleFlash;
    public Transform firePoint;
    public float fireRate = 0.5f;
    public float startDelay = 3f;
    public float muzzleVelocity = 100f;
    public float inaccuracy = 0.5f;

    float cooldown;
    int layer;

	// Use this for initialization
	void Start () {
        if (startDelay < 0)
            startDelay = Random.Range(0f, -startDelay);
        cooldown = startDelay;

        Transform topParent = transform;
        ShipHealth sh;
        while (topParent.parent != null)
        {
            topParent = topParent.parent;
            sh = topParent.GetComponent<ShipHealth>();
            if (sh != null)
            {
                if (sh.Enemy)
                    layer = LayerMask.NameToLayer("enemyShield");
                else
                    layer = LayerMask.NameToLayer("friendlyShield");
                break;
            }
        }

	}
	
	void FixedUpdate () {
        cooldown -= Time.fixedDeltaTime;
        if (cooldown < 0)
        {
            Fire();
            cooldown += fireRate;
        }
	}

    void Fire()
    {
        float angle = Random.Range(0f, 360f);
        float inacc = Random.Range(0f, inaccuracy);
        Vector3 dir = firePoint.eulerAngles + new Vector3(Mathf.Sin(angle) * inacc, Mathf.Cos(angle) * inacc, 0f);

        GameObject projectile = SimplePool.Spawn(round, firePoint.position, Quaternion.Euler(dir));
        Rigidbody rb = projectile.GetComponent<Rigidbody>();
        rb.velocity = projectile.transform.forward * muzzleVelocity;
        projectile.layer = layer;

        SimplePool.Spawn(muzzleFlash, firePoint.position, firePoint.rotation);
    }
}

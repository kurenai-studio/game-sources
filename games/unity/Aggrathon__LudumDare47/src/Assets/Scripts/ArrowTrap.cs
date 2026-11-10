using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ArrowTrap : MonoBehaviour
{

    public List<Projectile> projectiles;
    public Projectile prefab;

    public Vector3 prefabLaunchPoint;

    AudioSource audio;

    private void Start()
    {
        audio = GetComponent<AudioSource>();
    }

    public void Fire()
    {
        if (projectiles.Count > 0)
        {
            projectiles[projectiles.Count - 1].Fire();
            projectiles.RemoveAt(projectiles.Count - 1);
            if (audio)
                audio.Play();
        }
        else if (prefab != null)
        {
            Instantiate(prefab, transform.position + prefabLaunchPoint, transform.rotation).Fire();
            if (audio)
                audio.Play();
        }
    }

    private void OnDrawGizmosSelected()
    {
        Gizmos.color = Color.red;
        Gizmos.DrawWireSphere(transform.position + prefabLaunchPoint, 0.2f);
    }
}

using UnityEngine;
using System.Collections;

public class AutoDespawn : MonoBehaviour {

    public float despawnTimer = 3f;
    public bool startParticleSystem = false;

    float timer;

    public void OnEnable()
    {
        timer = despawnTimer;
        if (startParticleSystem)
        {
            foreach (ParticleSystem ps in GetComponents<ParticleSystem>())
                ps.Play();
            foreach (ParticleSystem ps in GetComponentsInChildren<ParticleSystem>())
                ps.Play();
        }
    }

    void Update()
    {
        if ((timer -= Time.deltaTime) < 0)
            Despawn();
    }

    public void Despawn()
    {
        SimplePool.Despawn(gameObject);
    }
}

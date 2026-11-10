using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SummoningController : MonoBehaviour
{
    private Animator animator;
    private ParticleSystem particleSystem;

    // Start is called before the first frame update
    void Start()
    {
        animator = GetComponent<Animator>();
        particleSystem = GetComponent<ParticleSystem>();
    }

    public void Despawn(bool didCast, Quaternion? rotation)
    {
        animator.SetTrigger("despawn");
        if (didCast && rotation.HasValue)
        {
            particleSystem.Play();
            particleSystem.transform.rotation = rotation.Value;
        }
    }

    public void OnDespawnAnimationEnd()
    {
        //Destroy(gameObject);
    }

    // Update is called once per frame
    void Update() { }
}

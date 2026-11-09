using System;
using UnityEngine;
using System.Collections.Generic;

[RequireComponent(typeof(Animator))]
[RequireComponent(typeof(Hittable))]
public class Bottle : MonoBehaviour
{
    public float fallTime = 0.33333f;
    public GameObject particles;

    Animator animator;
    Hittable hittable;
    float fallTimer = -1;

    void Start()
    {
        animator = GetComponent<Animator>();
        hittable = GetComponent<Hittable>();
    }

    void Hit(Transform from)
    {
        animator.SetTrigger("Fall");
        fallTimer = 0;
    }

    bool initialized = false;
    void Update()
    {
        if (!initialized)
        {
            hittable.callback += Hit;
            initialized = true;
        }
        if (fallTimer >= 0)
            fallTimer += Time.deltaTime;
        if (fallTimer >= fallTime)
        {
            if (particles != null)
            {
                GameObject p = Instantiate(particles);
                p.transform.position = transform.position;
            }
            Destroy(gameObject);
        }
    }
}

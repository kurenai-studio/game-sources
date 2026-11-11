using System;
using UnityEngine;
using UnityEngine.Events;

public class DeathController : MonoBehaviour
{
    public UnityEvent OnDeath;

    [SerializeField]
    private bool destroyOnAnimationEnd = true;

    private Animator animator;
    private Collider2D collider;

    void Awake() { }

    public void Die()
    {
        animator = GetComponent<Animator>();
        collider = GetComponent<Collider2D>();

        animator.SetTrigger("death");
        OnDeath?.Invoke();
        collider.enabled = false;
    }

    public void OnDeathAnimationEnd()
    {
        if (destroyOnAnimationEnd)
        {
            Destroy(gameObject);
        }
    }
}

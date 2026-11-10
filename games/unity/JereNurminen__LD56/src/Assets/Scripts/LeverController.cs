using System;
using UnityEngine;
using UnityEngine.Events;
using UnityEngine.InputSystem;

public class LeverController : MonoBehaviour
{
    public float duration = 5f;
    public LayerMask playerLayer;
    public UnityEvent OnActivate;
    public UnityEvent OnDeactivate;
    private Animator animator;
    private InputAction useAction;
    private bool playerIsInRange = false;
    private bool isActivated = false;
    private float timeSinceActivated = 0;

    void Start()
    {
        animator = GetComponent<Animator>();
        useAction = InputSystem.actions.FindAction("Interact");
        useAction.Enable();
    }

    void OnCollisionEnter2D(Collision2D other)
    {
        if (playerLayer == (playerLayer | (1 << other.gameObject.layer)))
        {
            playerIsInRange = true;
        }
    }

    void OnCollisionExit2D(Collision2D other)
    {
        if (playerLayer == (playerLayer | (1 << other.gameObject.layer)))
        {
            playerIsInRange = false;
        }
    }

    // Update is called once per frame
    void Update()
    {
        animator.SetBool("show_key", playerIsInRange);
        animator.SetBool("is_activated", isActivated);

        if (isActivated)
        {
            timeSinceActivated += Time.deltaTime;
            if (timeSinceActivated >= duration)
            {
                isActivated = false;
                timeSinceActivated = 0;
                OnDeactivate?.Invoke();
            }
        }

        if (playerIsInRange && useAction.triggered)
        {
            isActivated = true;
            timeSinceActivated = 0;
            OnActivate?.Invoke();
        }
    }
}

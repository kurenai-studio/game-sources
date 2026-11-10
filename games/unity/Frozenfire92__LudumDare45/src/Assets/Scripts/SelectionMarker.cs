using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(Animator))]
public class SelectionMarker : MonoBehaviour
{
    public GameObject target;
    Animator animator;

    Transform player;

    private void Start()
    {
        animator = gameObject.GetComponent<Animator>();
        player = gameObject.transform.parent;
    }

    public void Target(GameObject target)
    {
        Disable();
        this.target = target;
        if (target != null)
        {
            Move(target.transform.position);
            transform.SetParent(target.transform);
            Enable();
        }
        else
        {
            Move(player.position);
            transform.SetParent(player);
        }
    }

    void Move(Vector3 pos)
    {
        transform.position = pos;
    }

    void Enable()
    {
        animator.SetBool("Selected", true);
    }

    void Disable()
    {
        animator.SetBool("Selected", false);
    }
}

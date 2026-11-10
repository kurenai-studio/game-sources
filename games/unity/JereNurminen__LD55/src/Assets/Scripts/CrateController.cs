using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UIElements;

public class CrateController : MonoBehaviour
{
    private Animator animator;
    private BoxCollider2D boxCollider;
    private Rigidbody2D rb;

    // Start is called before the first frame update
    void Start()
    {
        animator = GetComponent<Animator>();
        boxCollider = GetComponent<BoxCollider2D>();
        rb = GetComponent<Rigidbody2D>();
    }

    // Update is called once per frame
    void Update() { }

    public void OnBreakAnimationEnd()
    {
        Destroy(gameObject);
    }

    public void Break()
    {
        animator.SetTrigger("break");
        rb.bodyType = RigidbodyType2D.Static;
        boxCollider.enabled = false;
    }
}

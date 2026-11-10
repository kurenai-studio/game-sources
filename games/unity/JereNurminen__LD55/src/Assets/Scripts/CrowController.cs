using System.Collections;
using System.Collections.Generic;
using Unity.VisualScripting;
using UnityEngine;

public class CrowController : MonoBehaviour
{
    public float speed = 1.0f;
    public int damage = 1;
    private Vector2 startPosition;
    private Vector2 targetPosition;
    private Vector2 movement;
    private Animator animator;
    private Rigidbody2D rb;
    private BoxCollider2D boxCollider;
    private SummonController summonController;

    // Start is called before the first frame update
    void Start()
    {
        rb = GetComponent<Rigidbody2D>();
        animator = GetComponent<Animator>();
        boxCollider = GetComponent<BoxCollider2D>();
        summonController = GetComponent<SummonController>();
    }

    public void Spawn(Vector2 startPosition, Vector2 targetPosition) {
        summonController = GetComponent<SummonController>();
        summonController.Spawn(startPosition, targetPosition);
    }

    // Update is called once per frame
    void Update()
    {
        
    }

 
}

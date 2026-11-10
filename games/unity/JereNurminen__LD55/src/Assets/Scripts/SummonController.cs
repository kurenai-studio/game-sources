using System.Collections;
using System.Collections.Generic;
using NUnit.Framework;
using UnityEngine;

public class SummonController : MonoBehaviour
{
    public float speed = 1.0f;
    public int damage = 1;
    public float gravity = 0f;
    public LayerMask targerLayers;
    private bool isGrounded = false;
    public bool hasHit = false;
    public Vector2 movement;
    private Vector2 startPosition;
    private Vector2 targetPosition;
    private Animator animator;
    private Rigidbody2D rb;
    private BoxCollider2D boxCollider;
    private CollisionDetection collisionDetection;
    private float lifeTime = 0f;
    public float maxLifeTime = 5f;

    // Start is called before the first frame update
    void Start()
    {
        animator = GetComponent<Animator>();
        rb = GetComponent<Rigidbody2D>();
        boxCollider = GetComponent<BoxCollider2D>();
        collisionDetection = GetComponent<CollisionDetection>();
    }

    public void OnHit()
    {
        hasHit = true;
        animator.SetTrigger("despawn");
        movement = Vector2.zero;
        boxCollider.enabled = false;
    }

    public void OnDespawnAnimationEnd()
    {
        Destroy(gameObject);
    }

    public void Spawn(Vector2 startPosition, Vector2 targetPosition)
    {
        this.startPosition = startPosition;
        this.targetPosition = targetPosition;
        movement = (targetPosition - startPosition).normalized * speed;
        Debug.Log("Spawned with movement: " + movement);
    }

    void ApplyGravity()
    {
        if (!isGrounded)
        {
            movement.y -= gravity * Time.deltaTime;
        }
    }

    public void Hit(GameObject targetObject, Vector2 point)
    {
        Debug.Log(targetObject.tag);

        if (targerLayers == (targerLayers | (1 << targetObject.layer)))
        {
            var health = targetObject.GetComponent<Health>();

            if (health != null)
            {
                if (health.isDead)
                {
                    return;
                }
                health.TakeDamage(1, point);
            }

            OnHit();
        }
    }

    private void OnCollisionEnter2D(Collision2D collision)
    {
        Hit(collision.gameObject, collision.GetContact(0).point);
    }

    void FixedUpdate()
    {
        ApplyGravity();
        rb.MovePosition(rb.position + movement * Time.deltaTime);
    }

    void Update()
    {
        lifeTime += Time.deltaTime;
        if (lifeTime >= maxLifeTime)
        {
            OnHit();
        }
    }
}

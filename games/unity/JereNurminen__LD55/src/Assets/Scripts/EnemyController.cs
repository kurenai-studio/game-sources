using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UIElements;

public class EnemyController : MonoBehaviour
{
    public float speed = 1.0f;
    public float gravity = 9.8f;
    public float groundRaycastDistance = 1 / 16f;
    public LayerMask visionBlockingLayerMask;
    public LayerMask targetLayers;
    public LayerMask killLayers;
    public float visionRange = 10.0f;
    public AudioClip chargeSound;

    private Vector2 velocity = Vector2.zero;
    private bool isGrounded = false;
    private bool isAlive = true;
    private bool isCharging = false;
    public float chargeCooldown = 1.0f;
    private float timeSinceLastChargeEnd = 0.0f;
    private int chargeDirection = 1;
    private BoxCollider2D boxCollider;
    private CollisionDetection collisionDetection;
    private Animator animator;
    private GameObject player;
    private PlayerController playerController;
    private Rigidbody2D rb;
    private Health health;
    private SpriteRenderer spriteRenderer;
    private bool hasSeenPlayer = false;

    // Start is called before the first frame update
    void Start()
    {
        boxCollider = GetComponent<BoxCollider2D>();
        collisionDetection = GetComponent<CollisionDetection>();
        animator = GetComponent<Animator>();
        player = GameObject.Find("Player");
        playerController = player.GetComponent<PlayerController>();
        rb = GetComponent<Rigidbody2D>();
        health = GetComponent<Health>();
        spriteRenderer = GetComponent<SpriteRenderer>();
    }

    void ApplyGravity()
    {
        if (!isGrounded)
        {
            velocity.y -= gravity * Time.deltaTime;
        }
    }

    RaycastHit2D? CheckForGround()
    {
        var hit = collisionDetection.CheckForGround();
        if (hit != null)
        {
            isGrounded = true;
            velocity.y = Mathf.Max(0, velocity.y);
            transform.position = new Vector2(
                transform.position.x,
                hit.Value.point.y + boxCollider.bounds.size.y / 2 + groundRaycastDistance
            );
        }
        else
        {
            isGrounded = false;
        }
        return hit;
    }

    RaycastHit2D? CheckForCeiling()
    {
        var hit = collisionDetection.CheckForCeiling();
        if (hit != null)
        {
            velocity.y = 0;
        }
        return hit;
    }

    RaycastHit2D? CheckForWalls()
    {
        var hit = collisionDetection.CheckForWalls(velocity.x);
        if (hit != null)
        {
            velocity.x = 0;
            var hitHealth = hit.Value.collider.gameObject.GetComponent<Health>();
            if (isCharging && hitHealth != null)
            {
                hitHealth.TakeDamage(1);
            }
            StopCharging();
        }
        return hit;
    }

    void ApplyVelocity()
    {
        transform.Translate(velocity * Time.deltaTime);
        if (velocity.x < 0)
        {
            transform.localScale = new Vector2(-1, 1);
        }
        else if (velocity.x > 0)
        {
            transform.localScale = new Vector2(1, 1);
        }
    }

    private bool CanSeePlayer()
    {
        // If player can't see the monster, the monster doesn't see the player
        if (!hasSeenPlayer && !spriteRenderer.isVisible)
        {
            return false;
        }
        var playerBottom = player.GetComponent<BoxCollider2D>().bounds.min;
        var playerTop = player.GetComponent<BoxCollider2D>().bounds.max;
        RaycastHit2D bottomHit = Physics2D.Raycast(
            transform.position,
            playerBottom - transform.position,
            visionRange,
            visionBlockingLayerMask
        );
        RaycastHit2D topHit = Physics2D.Raycast(
            transform.position,
            playerTop - transform.position,
            visionRange,
            visionBlockingLayerMask
        );

        if (topHit.collider != null && topHit.collider.gameObject.CompareTag("Player"))
        {
            Debug.DrawLine(transform.position, playerTop, Color.red);
            return true;
        }
        else if (topHit.collider != null)
        {
            Debug.DrawLine(transform.position, topHit.point, Color.blue);
        }
        else
        {
            Debug.DrawLine(transform.position, playerTop, Color.green);
        }
        if (bottomHit.collider != null && bottomHit.collider.gameObject.CompareTag("Player"))
        {
            Debug.DrawLine(transform.position, playerBottom, Color.red);
            return true;
        }
        else if (bottomHit.collider != null)
        {
            Debug.DrawLine(transform.position, bottomHit.point, Color.blue);
        }
        else
        {
            Debug.DrawLine(transform.position, playerBottom, Color.green);
        }
        return false;
    }

    public void onDeath()
    {
        animator.SetTrigger("die");
        isAlive = false;
        rb.bodyType = RigidbodyType2D.Static;
        //boxCollider.enabled = false;
    }

    private void ChargePlayer()
    {
        if (!isGrounded)
        {
            return;
        }
        if (!isCharging && timeSinceLastChargeEnd > chargeCooldown)
        {
            var direction = player.transform.position.x - transform.position.x > 0 ? 1 : -1;
            chargeDirection = direction;
            isCharging = true;
            Debug.Log(
                "Saw player at "
                    + player.transform.position.x
                    + " charging in direction "
                    + chargeDirection
            );
            AudioSource.PlayClipAtPoint(chargeSound, transform.position);
        }
        velocity.x = chargeDirection * speed;
    }

    private void StopCharging()
    {
        isCharging = false;
        chargeDirection = 0;
        velocity.x = 0;
        timeSinceLastChargeEnd = 0.0f;
    }

    public void onDamage()
    {
        StopCharging();
        timeSinceLastChargeEnd = chargeCooldown / 2;
    }

    private void OnCollisionEnter2D(Collision2D collision)
    {
        if (!isAlive)
        {
            return;
        }
        Debug.Log("Bull collided with " + collision.gameObject.name);
        var collisionHealth = collision.gameObject.GetComponent<Health>();

        if (
            targetLayers == (targetLayers | (1 << collision.gameObject.layer))
            && collisionHealth.name != "Boss"
        )
        {
            collisionHealth.TakeDamage(1);
        }

        if (killLayers == (killLayers | (1 << collision.gameObject.layer)))
        {
            health.TakeDamage(1);
            onDeath();
        }
    }

    // Update is called once per frame
    void Update()
    {
        var groundHits = CheckForGround();
        var wallHits = CheckForWalls();
        var ceilingHits = CheckForCeiling();
        if (isAlive)
        {
            if (CanSeePlayer() && playerController.isAlive)
            {
                ChargePlayer();
                hasSeenPlayer = true;
            }

            new List<RaycastHit2D?> { groundHits, wallHits, ceilingHits }.ForEach(hit =>
            {
                if (
                    hit != null
                    && hit.Value.collider.gameObject.GetComponent<Health>() != null
                        & hit.Value.collider.gameObject.name != "Boss"
                )
                {
                    hit.Value.collider.gameObject.GetComponent<Health>().TakeDamage(1);
                    if (hit.Value.collider.gameObject.CompareTag("Enemies"))
                    {
                        health.TakeDamage(1);
                    }
                }
            });
        }
        animator.SetBool("is_charging", isCharging);
        animator.SetBool("is_grounded", isGrounded);
        timeSinceLastChargeEnd += Time.deltaTime;
    }

    void FixedUpdate()
    {
        ApplyGravity();
        ApplyVelocity();
    }
}

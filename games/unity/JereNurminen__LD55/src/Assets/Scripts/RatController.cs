using System.Collections;
using System.Collections.Generic;
using NUnit.Framework.Constraints;
using UnityEngine;

public class RatController : MonoBehaviour
{
    public float landSpeed = 1.0f;
    public float airSpeed = 0.5f;
    public float gravity = 0.5f;
    public LayerMask flipLayers;

    private bool isGrounded = false;
    private Vector2 velocity = Vector2.zero;
    private CollisionDetection collisionDetection;
    private SummonController summonController;
    private Animator animator;

    // Start is called before the first frame update
    void Start()
    {
        collisionDetection = GetComponent<CollisionDetection>();
        summonController = GetComponent<SummonController>();
        animator = GetComponent<Animator>();
    }

    public void Spawn(Vector2 startPosition, Vector2 targetPosition)
    {
        summonController = GetComponent<SummonController>();
        summonController.Spawn(startPosition, targetPosition);
    }

    // Update is called once per frame
    void Update()
    {
        var groundHit = collisionDetection.CheckForGround();
        var wasGrounded = isGrounded;
        isGrounded = groundHit != null;
        var horizontalHit = collisionDetection.CheckForWalls(summonController.movement.x);
        var hasHorizontalHit = horizontalHit != null;

        if (summonController.hasHit)
        {
            summonController.movement = Vector2.zero;
            return;
        }

        animator.SetBool("grounded", isGrounded);
        if (isGrounded)
        {
            summonController.movement.y = 0;
            if (!wasGrounded)
            {
                summonController.Hit(groundHit.Value.collider.gameObject, groundHit.Value.point);
                var direction = summonController.movement.x > 0 ? 1 : -1;
                summonController.movement.x = landSpeed * direction;
            }
        }
        if (hasHorizontalHit)
        {
            summonController.Hit(
                horizontalHit.Value.collider.gameObject,
                horizontalHit.Value.point
            );
            if (flipLayers == (flipLayers | (1 << horizontalHit.Value.collider.gameObject.layer)))
            {
                summonController.movement.x *= -1;
            }
        }
        if (summonController.movement.x > 0)
        {
            transform.localScale = new Vector2(1, 1);
        }
        else if (summonController.movement.x < 0)
        {
            transform.localScale = new Vector2(-1, 1);
        }
    }
}

using UnityEngine;

enum PatrolDirection
{
    Left,
    Right
}

[RequireComponent(typeof(CollisionDetector2D))]
[RequireComponent(typeof(Rigidbody2D))]
[RequireComponent(typeof(Animator))]
[RequireComponent(typeof(BoxCollider2D))]
[RequireComponent(typeof(SpriteRenderer))]
public class PatrolController : MonoBehaviour
{
    [SerializeField]
    private float speed = 2f;

    private CollisionDetector2D collisionDetector;
    private PatrolDirection patrolDirection = PatrolDirection.Right;

    [SerializeField]
    private bool detectLedges = true;

    [SerializeField]
    private LayerMask floorMask;

    private BoxCollider2D boxCollider;
    private Animator animator;

    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start()
    {
        collisionDetector = GetComponent<CollisionDetector2D>();
        boxCollider = GetComponent<BoxCollider2D>();
        animator = GetComponent<Animator>();
    }

    bool DetectLedge()
    {
        Vector2 farOrigin =
            patrolDirection == PatrolDirection.Right
                ? new Vector2(boxCollider.bounds.max.x + 6f, boxCollider.bounds.min.y + 3f)
                : new Vector2(boxCollider.bounds.min.x - 6f, boxCollider.bounds.min.y + 3f);
        RaycastHit2D farHit = Physics2D.Raycast(
            farOrigin,
            Vector2.down,
            6f,
            collisionDetector.collisionMask
        );

        Vector2 closeOrigin =
            patrolDirection == PatrolDirection.Right
                ? new Vector2(boxCollider.bounds.max.x + 2f, boxCollider.bounds.min.y + 3f)
                : new Vector2(boxCollider.bounds.min.x - 2f, boxCollider.bounds.min.y + 3f);
        RaycastHit2D closeHit = Physics2D.Raycast(
            closeOrigin,
            Vector2.down,
            6f,
            collisionDetector.collisionMask
        );

        // Draw the rays
        Debug.DrawRay(farOrigin, Vector2.down * 6f, Color.red);
        Debug.DrawRay(closeOrigin, Vector2.down * 6f, Color.red);

        return farHit.collider == null && closeHit.collider == null;
    }

    bool DetectWall()
    {
        return collisionDetector.IsTouchingWall(
            patrolDirection == PatrolDirection.Right ? Vector2.right : Vector2.left
        );
    }

    public void Die()
    {
        GetComponent<BoxCollider2D>().enabled = false;
        speed = 0;
    }

    // Update is called once per frame
    void Update()
    {
        // Self destruct if they somehow end up in the air
        if (!collisionDetector.IsGrounded())
        {
            animator.SetTrigger("death");
            Die();
        }

        // Check if the enemy is at the edge of a ledge
        if (DetectWall() || DetectLedge())
        {
            // Change direction
            patrolDirection =
                patrolDirection == PatrolDirection.Right
                    ? PatrolDirection.Left
                    : PatrolDirection.Right;
        }

        // Move the enemy in the current direction
        Vector2 movement = new Vector2(
            (patrolDirection == PatrolDirection.Right ? 1 : -1) * speed * Time.deltaTime,
            0
        );
        transform.Translate(movement);
    }
}

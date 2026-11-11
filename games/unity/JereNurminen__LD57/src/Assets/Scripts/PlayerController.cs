using UnityEngine;
using UnityEngine.InputSystem;

[RequireComponent(typeof(Rigidbody2D))]
[RequireComponent(typeof(CollisionDetector2D))]
//[RequireComponent(typeof(PlayerInput))]
public class PlayerController : MonoBehaviour
{
    [Header("Movement Settings")]
    [Tooltip("Horizontal movement speed.")]
    [SerializeField]
    private float moveSpeed = 5f;

    [Tooltip("Jump force applied when jumping.")]
    [SerializeField]
    private float jumpForce = 10f;

    [Tooltip("Gravity applied when airborne.")]
    [SerializeField]
    private float gravity = -20f;

    [Tooltip("Gravity applied when actively dropping.")]
    [SerializeField]
    private float dropGravity = -20f;

    [Tooltip("Gravity applied when actively dropping.")]
    [SerializeField]
    private float hoverGravity = -20f;

    [Tooltip("Maximum fall speed.")]
    [SerializeField]
    private float maxFallSpeed = -20f;

    [Tooltip("Maximum fall speed when hovering.")]
    [SerializeField]
    private float maxHoverFallSpeed = -40f;

    [Tooltip("Maximum fall speed when dropping.")]
    [SerializeField]
    private float maxDropFallSpeed = -300f;

    [Tooltip("A small distance to keep away from colliders to avoid penetration.")]
    [SerializeField]
    private float skinWidth = 0.01f;

    [Tooltip("Layers that are detected when dropping.")]
    [SerializeField]
    private LayerMask dropLayerMask;

    [Tooltip("Level hazard layers")]
    [SerializeField]
    private LayerMask hazardLayerMask;

    public bool isGrounded = false;
    private bool jumpConsumed = false;
    private bool isHovering = false;

    private Rigidbody2D rb;
    public Collider2D playerCollider;
    private CollisionDetector2D collisionDetector;
    private PlayerInput playerInput;
    private InputAction moveAction;
    private InputAction jumpAction;
    private InputAction hoverAction;
    private InputAction dropAction;
    private Animator animator;

    // Controlled velocity (manually simulated).
    private Vector2 velocity;
    private bool jumpPressed;
    private bool hoverPressed;
    private bool dropPressed;
    private bool leftPressed;
    private bool rightPressed;

    private bool isAlive = true;
    private GameManager gameManager;

    void Awake()
    {
        rb = GetComponent<Rigidbody2D>();
        playerCollider = GetComponent<Collider2D>();
        collisionDetector = GetComponent<CollisionDetector2D>();
        animator = GetComponent<Animator>();
        gameManager = FindFirstObjectByType<GameManager>();

        // Set Rigidbody2D to kinematic for manual control.
        rb.bodyType = RigidbodyType2D.Kinematic;

        playerInput = GetComponent<PlayerInput>();
        moveAction = playerInput.actions["Move"];
        jumpAction = playerInput.actions["Jump"];
        hoverAction = playerInput.actions["Hover"];
        dropAction = playerInput.actions["Drop"];
    }

    void OnEnable()
    {
        moveAction.Enable();
        jumpAction.Enable();
        hoverAction.Enable();
        dropAction.Enable();
    }

    void OnDisable()
    {
        moveAction.Disable();
        jumpAction.Disable();
        hoverAction.Disable();
        dropAction.Disable();
    }

    public void OnDeathAnimationCompleted()
    {
        GetComponent<SpriteRenderer>().enabled = false;
    }

    void OnCollisionEnter2D(Collision2D collision)
    {
        if (hazardLayerMask == (hazardLayerMask | (1 << collision.gameObject.layer)))
        {
            if (dropPressed)
            {
                var contact = collision.GetContact(0);
                var isFromAbove = contact.normal.y > 0.5f;
                var stompable = collision.gameObject.GetComponent<Stompable>();

                if (stompable != null && isFromAbove)
                {
                    return;
                }
                else
                {
                    Debug.Log("Hit hazard from above");
                }
            }
            isAlive = false;
            gameManager.OnPlayerDeath();
            animator.SetTrigger("death");
        }
        else if (
            dropPressed && dropLayerMask == (dropLayerMask | (1 << collision.gameObject.layer))
        )
        {
            var contact = collision.GetContact(0);
            var isFromAbove = contact.normal.y > 0.5f;
            var stompable = collision.gameObject.GetComponent<Stompable>();

            if (stompable != null && isFromAbove)
            {
                stompable.OnStomp.Invoke();
            }
        }
    }

    void Update()
    {
        if (!isAlive)
            return;

        leftPressed = moveAction.ReadValue<Vector2>().x < 0;
        rightPressed = moveAction.ReadValue<Vector2>().x > 0;

        // Only allow jumpPressed to be set if the player is grounded
        if (isGrounded && !jumpConsumed && jumpAction.triggered)
        {
            jumpPressed = true;
        }

        // Handle hover and drop inputs
        hoverPressed = hoverAction.IsPressed();
        dropPressed = dropAction.IsPressed();

        Vector2 deltaMovement = velocity * Time.deltaTime;

        // Move the player using the adjusted movement.
        transform.position = collisionDetector.GetNewPosition(deltaMovement);
    }

    void FixedUpdate()
    {
        if (!isAlive)
            return;

        var wasGrounded = isGrounded;
        var isNowGrounded = collisionDetector.IsGrounded();

        if (!wasGrounded && isNowGrounded)
        {
            Debug.Log("Landed");
        }
        else if (wasGrounded && !isNowGrounded)
        {
            Debug.Log("Jumped");
        }

        velocity.x = leftPressed
            ? -moveSpeed
            : rightPressed
                ? moveSpeed
                : 0f;

        if (velocity.x > 0f)
        {
            var isTouchingWall = collisionDetector.IsTouchingWall(Vector2.right);
            if (isTouchingWall)
            {
                velocity.x = 0f;
            }
            transform.localScale = new Vector3(1f, 1f, 1f);
        }
        else if (velocity.x < 0f)
        {
            var isTouchingWall = collisionDetector.IsTouchingWall(Vector2.left);
            if (isTouchingWall)
            {
                velocity.x = 0f;
            }
            transform.localScale = new Vector3(-1f, 1f, 1f);
        }
        else if (Mathf.Approximately(velocity.x, 0f)) { }

        // Ground detection via our collision detector.
        if (isNowGrounded)
        {
            if (jumpPressed)
            {
                Debug.Log("Jump pressed");
                velocity.y = jumpForce;
                jumpPressed = false; // Reset jumpPressed after processing
                jumpConsumed = true; // Mark jump as consumed
            }
            else
            {
                // When grounded, reset vertical velocity.
                velocity.y = 0f;
            }
        }
        else
        {
            var gravityToApply = gravity;
            var fallSpeed = maxFallSpeed;

            if (collisionDetector.IsTouchingCeiling())
            {
                Debug.Log("Ceiling hit");
                velocity.y = 0f;
            }

            if (dropPressed)
            {
                animator.SetBool("isDropping", true);
                animator.SetBool("isHovering", false);
                gravityToApply = dropGravity;
                fallSpeed = maxDropFallSpeed;
            }
            else if (hoverPressed && velocity.y < 0f)
            {
                animator.SetBool("isDropping", false);
                animator.SetBool("isHovering", true);
                gravityToApply = hoverGravity;
                fallSpeed = maxHoverFallSpeed;
            }
            else
            {
                animator.SetBool("isDropping", false);
                animator.SetBool("isHovering", false);
            }

            velocity.y += gravityToApply * Time.fixedDeltaTime;
            velocity.y = Mathf.Max(velocity.y, fallSpeed);
        }

        Vector2 deltaMovement = velocity * Time.fixedDeltaTime;

        // Move the player using the adjusted movement.
        transform.position = collisionDetector.GetNewPosition(deltaMovement);

        if (!isGrounded && dropPressed)
        {
            Vector2 colliderOffset = playerCollider.offset;
            Vector2 colliderSize = playerCollider.bounds.size;

            float rayLength = 3f;
            int rayCount = 5;
            float spacing = colliderSize.x / (rayCount - 1);

            for (int i = 0; i < rayCount; i++)
            {
                // Adjust ray origins to account for the collider's offset
                Vector2 rayOrigin = new Vector2(
                    transform.position.x + colliderOffset.x - colliderSize.x / 2 + i * spacing,
                    transform.position.y + colliderOffset.y - colliderSize.y / 2
                );

                RaycastHit2D hit = Physics2D.Raycast(
                    rayOrigin,
                    Vector2.down,
                    rayLength,
                    dropLayerMask
                );

                Debug.DrawRay(rayOrigin, Vector2.down * rayLength, Color.red);

                if (hit.collider != null)
                {
                    var target = hit.collider.gameObject;
                    Debug.Log($"Dropped on {target.name}");
                    var targetStompable = target.GetComponent<Stompable>();
                    if (targetStompable != null)
                    {
                        targetStompable.OnStomp.Invoke();
                        if (targetStompable.bouncy)
                        {
                            velocity.y = targetStompable.bounceForce;
                        }
                    }
                    break; // Exit loop after hitting a valid target
                }
            }
        }

        isGrounded = isNowGrounded;

        // Reset jumpConsumed when grounded
        if (isGrounded)
        {
            jumpConsumed = false;
            animator.SetBool("isGrounded", true);
            animator.SetBool("isDropping", false);
            animator.SetBool("isHovering", false);
        }
        else
        {
            animator.SetBool("isGrounded", false);
        }
        isGrounded = isNowGrounded;
        animator.SetBool("isGrounded", isGrounded);
        if (isGrounded && !Mathf.Approximately(velocity.x, 0f))
        {
            animator.SetBool("isRunning", true);
        }
        else
        {
            animator.SetBool("isRunning", false);
        }
    }
}

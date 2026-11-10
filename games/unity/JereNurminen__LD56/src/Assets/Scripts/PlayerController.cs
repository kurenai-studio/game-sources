using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.InputSystem;

public class PlayerController : MonoBehaviour
{
    public float moveSpeed = 5f;
    public float jumpSpeed = 10f;
    public float coyoteTime = 0.2f; // Coyote time duration
    public float fallAcceleration = 4f; // Units (pixels) per second
    public float maxFallSpeed = 8f; // Units (pixels) per second
    public float gravityImmunityDuration = 0.5f;
    public float commandRange = 128f;
    public Vector2 speechBubbleOffset = new Vector2(0, 1);
    public LayerMask hazardLayers;

    private Rigidbody2D rb;
    private Collider2D col;
    private CollisionDetector2D collisionDetector;
    private float coyoteTimeCounter;
    private float verticalVelocity;
    private float horizontalVelocity;
    private bool isGrounded;
    private float timeSinceJump = 0;

    private InputAction moveAction;
    private InputAction jumpAction;
    private InputAction commandGoAction;
    private InputAction commandStopAction;
    private InputAction commandJumpAction;

    private Animator animator;
    private Animator speechBubbleAnimator;
    private bool commandReady = true;
    private bool isAlive = true;
    private LevelManager levelManager;
    private SheepController[] sheepControllers;

    void Start()
    {
        rb = GetComponent<Rigidbody2D>();
        col = GetComponent<Collider2D>();
        collisionDetector = GetComponent<CollisionDetector2D>();
        animator = GetComponent<Animator>();
        speechBubbleAnimator = transform.Find("Command Bubble").GetComponent<Animator>();
        levelManager = FindFirstObjectByType<LevelManager>();
        sheepControllers = FindObjectsByType<SheepController>(FindObjectsSortMode.None);

        moveAction = InputSystem.actions.FindAction("Move");
        jumpAction = InputSystem.actions.FindAction("Jump");
        commandGoAction = InputSystem.actions.FindAction("Command: Go");
        commandStopAction = InputSystem.actions.FindAction("Command: Stop");
        commandJumpAction = InputSystem.actions.FindAction("Command: Jump");
    }

    void HandleMovementInputs()
    {
        var moveValue = moveAction.ReadValue<Vector2>().x;
        if (moveValue.CompareTo(0) != 0)
        {
            var movement = moveValue > 0 ? Vector2.right : Vector2.left;

            if (movement.x > 0)
            {
                transform.localScale = new Vector2(1, 1);
            }
            else
            {
                transform.localScale = new Vector2(-1, 1);
            }

            horizontalVelocity = movement.x * moveSpeed;

            animator.SetBool("is_running", true);
        }
        else
        {
            horizontalVelocity = 0;
            animator.SetBool("is_running", false);
        }
    }

    public void Jump()
    {
        verticalVelocity = jumpSpeed;
        timeSinceJump = 0;
        coyoteTimeCounter = 0f;

        animator.SetTrigger("jump");
    }

    private void HandleJump()
    {
        if (isGrounded && jumpAction.triggered && coyoteTimeCounter > 0f)
        {
            Jump();
        }
    }

    private void HandleGravity()
    {
        if (collisionDetector.IsGroundedBox() && verticalVelocity.CompareTo(0) <= 0)
        {
            coyoteTimeCounter = coyoteTime;
            verticalVelocity = 0f;
            isGrounded = true;
        }
        else
        {
            coyoteTimeCounter -= Time.deltaTime;
            isGrounded = false;
            if (timeSinceJump > gravityImmunityDuration)
            {
                verticalVelocity -= fallAcceleration * Time.deltaTime;
            }
        }
    }

    void HandleCommands()
    {
        if (!commandReady)
        {
            return;
        }
        if (commandGoAction.triggered)
        {
            speechBubbleAnimator.SetTrigger("go");
            foreach (var sheepController in sheepControllers)
            {
                sheepController.ReceiveCommand(SheepCommand.Go, transform.position);
            }
            commandReady = false;
        }
        else if (commandStopAction.triggered)
        {
            speechBubbleAnimator.SetTrigger("stop");
            foreach (var sheepController in sheepControllers)
            {
                sheepController.ReceiveCommand(SheepCommand.Stop, transform.position);
            }
            commandReady = false;
        }
        else if (commandJumpAction.triggered)
        {
            speechBubbleAnimator.SetTrigger("jump");
            foreach (var sheepController in sheepControllers)
            {
                sheepController.ReceiveCommand(SheepCommand.Jump, transform.position);
            }
            commandReady = false;
        }
    }

    public void OnCommandAnimationComplete()
    {
        commandReady = true;
    }

    public void OnDeathAnimationComplete()
    {
        gameObject.SetActive(false);
        levelManager.OnPlayerDeath();
    }

    void FixedUpdate()
    {
        if (isAlive)
        {
            HandleGravity();

            if (collisionDetector.IsTouchingWall(transform.localScale.x))
            {
                horizontalVelocity = 0;
            }
            else
            {
                //transform.Translate(horizontalVelocity * Time.deltaTime, 0, 0);
                Vector2 horizontalPredictedPosition =
                    (Vector2)transform.position
                    + new Vector2(horizontalVelocity * Time.deltaTime, 0);
                var horizontalCastOrig = new Vector2(col.bounds.center.x, col.bounds.center.y);
                var horizontalCastTarget = new Vector2(
                    horizontalPredictedPosition.x,
                    horizontalPredictedPosition.y
                );
                Debug.DrawLine(horizontalCastOrig, horizontalCastTarget, Color.red);
                var horizontalHit = Physics2D.Linecast(
                    horizontalCastOrig,
                    horizontalCastTarget,
                    collisionDetector.groundLayer
                );

                if (horizontalHit.collider == null)
                {
                    transform.position = horizontalPredictedPosition;
                }
                else
                {
                    transform.position = new Vector2(
                        horizontalHit.point.x + col.bounds.size.x / 2,
                        transform.position.y
                    );
                }
            }

            if (verticalVelocity > 0 && collisionDetector.IsTouchingCeiling())
            {
                Debug.Log("Bonk");
                verticalVelocity = -fallAcceleration * Time.deltaTime;
            }

            Vector2 predictedPosition =
                transform.position + new Vector3(0, verticalVelocity * Time.deltaTime);

            Vector2 castOrig = new(col.bounds.center.x, col.bounds.center.y + 3f);
            Vector2 castTarget =
                new(predictedPosition.x, predictedPosition.y - col.bounds.size.y / 2 - 3f);
            var hit = Physics2D.Linecast(castOrig, castTarget, collisionDetector.groundLayer);

            //Debug.DrawLine(castOrig, castTarget, Color.red);

            if (hit.collider != null && verticalVelocity < 0)
            {
                // Snap character to the ground if a collision is detected
                predictedPosition.y = hit.point.y + (col.bounds.size.y / 2) - col.offset.y;
                verticalVelocity = 0f;
            }

            // Move the character on the y-axis
            transform.position = new Vector2(transform.position.x, predictedPosition.y);
        }
    }

    void Update()
    {
        if (isAlive)
        {
            HandleJump();
            HandleCommands();
            HandleMovementInputs();
        }

        animator.SetFloat("vertical_speed", verticalVelocity);
        animator.SetBool("is_grounded", isGrounded);

        timeSinceJump += Time.deltaTime;
    }

    private void OnCollisionEnter2D(Collision2D collision)
    {
        if (hazardLayers == (hazardLayers | (1 << collision.gameObject.layer)))
        {
            isAlive = false;
            animator.SetTrigger("hit");
        }
    }

    /*
    private void OnCollisionExit2D(Collision2D collision)
    {
        if (collision.gameObject.CompareTag("MovingPlatform"))
        {
            transform.SetParent(null);
        }
    }
    */
}

using System.Linq;
using UnityEngine;

public enum SheepCommand
{
    Go,
    Stop,
    Jump
}

public enum CommandFrom
{
    Player,
    Sheep
}

public enum SheepJumpStrength
{
    Short,
    Long,
    ExtraLong
}

public class SheepController : MonoBehaviour
{
    public float moveSpeed = 5f;
    public float memoryDuration = 5f;
    public float shortJumpSpeed = 10f;
    public float longJumpSpeed = 32f;
    public float fallAcceleration = 4f;
    public LayerMask obstacleLayers;
    public LayerMask hazardLayers;
    public LayerMask goalLayers;
    public float autoJumpDelay = 1f;
    private float timeSinceEdgeDetected = 0f;
    private bool isOverEdge = false;

    private float horizontalVelocity = 0;
    private float verticalVelocity = 0;

    private int direction = 1;

    private float timeSinceCommand = 0;
    private bool isGrounded = true;
    private bool isJumping = false;
    public bool isAlive = true;
    public bool isSuccess = false;

    private CollisionDetector2D collisionDetector;
    private Collider2D col;
    public SheepCommand? currentCommand = null;
    private bool isRunning = false;
    private Animator animator;
    private LevelManager levelManager;
    private BoxCollider2D levelBounds;
    public bool isInRange;
    private PlayerController playerController;

    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start()
    {
        moveSpeed += Random.Range(-1f, 1f);
        memoryDuration += Random.Range(-1f, 1f);

        col = GetComponent<Collider2D>();
        collisionDetector = GetComponent<CollisionDetector2D>();
        animator = GetComponent<Animator>();
        levelManager = FindFirstObjectByType<LevelManager>();
        levelBounds = levelManager.GetComponent<BoxCollider2D>();
        playerController = FindFirstObjectByType<PlayerController>();
    }

    private void HandleGravity()
    {
        if (collisionDetector.IsGroundedBox() && verticalVelocity.CompareTo(0) <= 0)
        {
            verticalVelocity = 0f;
            isGrounded = true;
            isJumping = false;
        }
        else
        {
            if (!collisionDetector.IsTouchingCeiling())
            {
                verticalVelocity -= fallAcceleration * Time.deltaTime;
                isGrounded = false;
            }
            else
            {
                verticalVelocity = 0f;
            }
        }

        Vector2 predictedPosition =
            transform.position + new Vector3(0, verticalVelocity * Time.deltaTime);

        Vector2 castOrig = new(col.bounds.center.x, col.bounds.min.y);
        Vector2 castTarget =
            new(predictedPosition.x, predictedPosition.y - col.bounds.size.y / 2 - 1);
        var hit = Physics2D.Linecast(castOrig, castTarget, collisionDetector.groundLayer);

        if (hit.collider != null && verticalVelocity < 0)
        {
            // Snap character to the ground if a collision is detected
            predictedPosition.y = hit.point.y + (col.bounds.size.y / 2) - col.offset.y;
            verticalVelocity = 0f;
        }

        // Move the character on the y-axis
        transform.position = new Vector2(transform.position.x, predictedPosition.y);

        animator.SetFloat("vertical_speed", verticalVelocity);
    }

    public void ReceiveCommand(
        SheepCommand? command,
        Vector2 commandPos,
        CommandFrom from = CommandFrom.Player
    )
    {
        if ((from == CommandFrom.Player && !isInRange) || !isAlive || command == null)
        {
            return;
        }
        timeSinceCommand = 0;
        switch (command)
        {
            case SheepCommand.Go:
                currentCommand = command;
                Go(commandPos);
                break;
            case SheepCommand.Stop:
                currentCommand = null;
                Stop();
                break;
            case SheepCommand.Jump:
                Jump(SheepJumpStrength.Long);
                break;
        }
    }

    void Go(Vector2 moveAwayFrom)
    {
        isRunning = true;
        direction = transform.position.x > moveAwayFrom.x ? 1 : -1;

        // If there are any non-sheep obstacles in the way, turn around
        var IsBlocked = Physics2D
            .RaycastAll(
                new Vector2(col.bounds.center.x, col.bounds.min.y),
                direction == 1 ? Vector2.right : Vector2.left,
                col.bounds.size.x / 2 + 5f,
                obstacleLayers
            )
            .Any(
                hit => hit.collider != null && hit.collider.GetComponent<SheepController>() == null
            );

        if (IsBlocked)
        {
            direction *= -1;
            var newSheepHits = Physics2D
                .RaycastAll(
                    new Vector2(col.bounds.center.x, col.bounds.min.y),
                    direction == 1 ? Vector2.right : Vector2.left,
                    col.bounds.size.x / 2 + 5f,
                    obstacleLayers
                )
                .Where(
                    hit =>
                        hit.collider != null && hit.collider.GetComponent<SheepController>() != null
                )
                .ToArray();
            foreach (var hit in newSheepHits)
            {
                var otherSheep = hit.collider.GetComponent<SheepController>();
                otherSheep.ReceiveCommand(SheepCommand.Go, transform.position, CommandFrom.Sheep);
            }
        }
    }

    void Stop()
    {
        isRunning = false;
    }

    public void Jump(SheepJumpStrength strength)
    {
        Debug.Log($"Jumping with strength {strength}");
        if (isGrounded)
        {
            verticalVelocity = strength switch
            {
                SheepJumpStrength.Short => shortJumpSpeed,
                SheepJumpStrength.Long => longJumpSpeed,
                SheepJumpStrength.ExtraLong => longJumpSpeed * 2f,
                _ => verticalVelocity
            };
            isJumping = true;
            animator.SetTrigger("jump");
        }
    }

    void DetectLedge()
    {
        var frontX = direction == 1 ? col.bounds.max.x : col.bounds.min.x;
        var backX = direction == 1 ? col.bounds.min.x : col.bounds.max.x;

        var backGroundHit = Physics2D.Raycast(
            new Vector2(backX, col.bounds.min.y),
            Vector2.down,
            2f,
            collisionDetector.groundLayer
        );
        var frontGroundHit = Physics2D.Raycast(
            new Vector2(frontX, col.bounds.min.y),
            Vector2.down,
            2f,
            collisionDetector.groundLayer
        );

        if (backGroundHit.collider != null && frontGroundHit.collider == null)
        {
            if (!isOverEdge)
            {
                timeSinceEdgeDetected = 0;
            }
            isOverEdge = true;

            if (timeSinceEdgeDetected > autoJumpDelay)
            {
                Jump(SheepJumpStrength.Short);
                timeSinceEdgeDetected = 0;
                isOverEdge = false;
            }
        }
        else if (backGroundHit.collider != null && frontGroundHit.collider != null)
        {
            isOverEdge = false;
            timeSinceEdgeDetected = 0;
        }
    }

    bool IsBlocked()
    {
        var dir = direction == 1 ? Vector2.right : Vector2.left;
        var origX = direction == 1 ? col.bounds.max.x + 1 : col.bounds.min.x - 1;
        var rayLength = 2f;

        var bottomHit = Physics2D.Raycast(
            new Vector2(origX, col.bounds.min.y + 1),
            dir,
            rayLength,
            obstacleLayers
        );
        var topHit = Physics2D.Raycast(
            new Vector2(origX, col.bounds.max.y - 1),
            dir,
            rayLength,
            obstacleLayers
        );

        var wouldHit = bottomHit.collider != null || topHit.collider != null;
        var other =
            bottomHit.collider != null
                ? bottomHit.collider
                : topHit.collider != null
                    ? topHit.collider
                    : null;

        if (other != null && other.GetComponent<SheepController>() != null)
        {
            var otherSheep = other.GetComponent<SheepController>();
            if (currentCommand != null && otherSheep.currentCommand == null)
            {
                otherSheep.ReceiveCommand(currentCommand, transform.position, CommandFrom.Sheep);
            }
        }

        return wouldHit;
    }

    void Move()
    {
        if (!IsBlocked())
        {
            horizontalVelocity = direction * moveSpeed * Time.deltaTime;
            transform.Translate(horizontalVelocity, 0, 0);
        }
        else if (!isGrounded)
        {
            //direction *= -1;
        }
        transform.localScale = new Vector2(direction, 1);
        DetectLedge();
    }

    void OnCollisionEnter2D(Collision2D collision)
    {
        if (hazardLayers == (hazardLayers | (1 << collision.gameObject.layer)))
        {
            OnHazardHit();
        }
        else if (goalLayers == (goalLayers | (1 << collision.gameObject.layer)))
        {
            isSuccess = true;
            levelManager.UpdateSheepStatuses();
        }
    }

    public void OnHazardHit()
    {
        animator.SetTrigger("die");
        isAlive = false;
        collisionDetector.enabled = false;
        gameObject.layer = LayerMask.NameToLayer("Dead Sheep");
    }

    public void Kill()
    {
        gameObject.SetActive(false);
        levelManager.UpdateSheepStatuses();
    }

    // Update is called once per frame
    void FixedUpdate()
    {
        timeSinceEdgeDetected += Time.deltaTime;

        var isInPlayersFacingDirection =
            playerController.transform.localScale.x.CompareTo(0) >= 0
                && transform.position.x > playerController.transform.position.x
            || playerController.transform.localScale.x.CompareTo(0) < 0
                && transform.position.x < playerController.transform.position.x;

        isInRange =
            isInPlayersFacingDirection
            && (
                Vector2.Distance(playerController.transform.position, transform.position)
                < playerController.commandRange
            );

        if (!isAlive)
        {
            return;
        }

        HandleGravity();

        timeSinceCommand += Time.deltaTime;
        if (timeSinceCommand > memoryDuration)
        {
            currentCommand = null;
        }

        if (isRunning || isJumping)
        {
            Move();
            animator.SetBool("is_running", true);
        }
        else
        {
            animator.SetBool("is_running", false);
        }

        animator.SetBool("is_grounded", isGrounded);

        if (
            !isSuccess && transform.position.y > levelBounds.bounds.max.y
            || transform.position.y < levelBounds.bounds.min.y
            || transform.position.x > levelBounds.bounds.max.x
            || transform.position.x < levelBounds.bounds.min.x
        )
        {
            Kill();
        }
    }
}

using UnityEngine;

public class CollisionDetector2D : MonoBehaviour
{
    [System.Serializable]
    public struct CollisionCheck
    {
        [Tooltip("Layer mask to check against")]
        public LayerMask layer;

        [Tooltip("Distance to check for collision")]
        public float distance;

        [Tooltip("Local offset for the check")]
        public Vector2 offset;
    }

    [Header("Collision Checks")]
    [SerializeField]
    private CollisionCheck groundCheck;

    [SerializeField]
    private CollisionCheck wallCheck;

    [SerializeField]
    private CollisionCheck ceilingCheck;

    [Header("Movement Collision")]
    [Tooltip("Layers that count as obstacles for movement")]
    public LayerMask collisionMask;

    [Tooltip("Small offset to prevent clipping into colliders")]
    public float skinWidth = 0.05f;

    [Header("Debug Settings")]
    [Tooltip("Toggle to draw debug gizmos in the Scene view")]
    public bool drawGizmos = true;

    private BoxCollider2D boxCollider;

    // Debug variables for visualization
    private Vector2 debugOrigin,
        debugSize,
        debugDirection,
        debugDesiredMovement,
        debugAdjustedMovement,
        debugHitPoint;
    private float debugDistance;
    private bool debugHitFound;

    void Awake() => boxCollider = GetComponent<BoxCollider2D>();

    // Helper method to perform a raycast check with given settings.
    private bool CheckCollision(CollisionCheck check, Vector2 direction)
    {
        Vector2 origin = (Vector2)transform.position + check.offset;
        var hit = Physics2D.Raycast(origin, direction, check.distance, check.layer);
        if (hit.collider != null)
            Debug.Log("Raycast hit: " + hit.collider.name);
        return hit.collider != null;
    }

    public Collider2D GetHitsBelow(LayerMask? layerMask)
    {
        var mask = layerMask ?? groundCheck.layer;
        // Use the boxCollider's size and offset
        Vector2 origin = (Vector2)transform.position + (Vector2)boxCollider.offset;
        Vector2 size = boxCollider.size;

        // Adjust the origin to position the OverlapBox at the bottom of the collider
        origin.y -= (boxCollider.size.y / 2) + (groundCheck.distance / 2);

        // Adjust the size to extend slightly below the collider
        size.y = groundCheck.distance;

        Collider2D hit = Physics2D.OverlapBox(origin, size, 0f, groundCheck.layer);

        return hit;
    }

    public bool IsGrounded()
    {
        var hit = GetHitsBelow(null);

        if (hit != null)
        {
            Debug.Log($"Ground detected: {hit.name}");
            return true;
        }
        else
        {
            return false;
        }
    }

    public bool IsTouchingCeiling()
    {
        // Use the boxCollider's size and offset
        Vector2 origin = (Vector2)transform.position + (Vector2)boxCollider.offset;
        Vector2 size = boxCollider.size;

        // Adjust the origin to position the OverlapBox at the top of the collider
        origin.y += (boxCollider.size.y / 2) + (groundCheck.distance / 2);

        // Adjust the size to extend slightly below the collider
        size.y = groundCheck.distance;

        Collider2D hit = Physics2D.OverlapBox(origin, size, 0f, ceilingCheck.layer);

        if (hit != null)
        {
            Debug.Log($"Ceiling detected: {hit.name}");
            return true;
        }
        else
        {
            return false;
        }
    }

    public bool IsTouchingWall(Vector2 dir)
    {
        // Use the boxCollider's size and offset
        Vector2 origin = (Vector2)transform.position + (Vector2)boxCollider.offset;
        Vector2 size = boxCollider.size;

        // Adjust the origin to position the OverlapBox at the side of the collider
        origin += dir * ((boxCollider.size.x / 2) + (wallCheck.distance / 2));

        // Adjust the size to extend slightly beyond the collider
        size.x = wallCheck.distance;

        Collider2D hit = Physics2D.OverlapBox(origin, size, 0f, wallCheck.layer);

        if (hit != null)
        {
            Debug.Log($"Wall detected: {hit.name}");
            return true;
        }
        else
        {
            return false;
        }
    }

    public Vector2 GetNewPosition(Vector2 desiredMovement)
    {
        debugDesiredMovement = desiredMovement;
        Vector2 currentPosition = transform.position;

        // Calculate BoxCast origin based on the collider's offset.
        debugOrigin = currentPosition + (Vector2)boxCollider.offset;
        debugSize = boxCollider.size;

        float distance = desiredMovement.magnitude;
        if (distance == 0)
            return currentPosition;

        debugDirection = desiredMovement / distance;
        debugDistance = distance;

        // Cast a box along the desired movement path with an extra skinWidth.
        RaycastHit2D hit = Physics2D.BoxCast(
            debugOrigin,
            debugSize,
            0f,
            debugDirection,
            distance + skinWidth,
            collisionMask
        );

        if (hit.collider != null)
        {
            debugHitFound = true;
            debugHitPoint = hit.point;
            // Adjust movement so that we stop skinWidth away from the collision.
            float moveDistance = Mathf.Max(hit.distance - skinWidth, 0f);
            debugAdjustedMovement = debugDirection * moveDistance;
            return currentPosition + debugAdjustedMovement;
        }
        else
        {
            debugHitFound = false;
            debugAdjustedMovement = desiredMovement;
            return currentPosition + desiredMovement;
        }
    }

    private void OnDrawGizmosSelected()
    {
        // Visualize the raycasts for ground, ceiling, and wall checks.
        // Ground
        Gizmos.color = Color.green;
        Vector2 groundOrigin = (Vector2)transform.position + groundCheck.offset;
        Gizmos.DrawLine(groundOrigin, groundOrigin + Vector2.down * groundCheck.distance);

        // Ceiling
        Gizmos.color = Color.blue;
        Vector2 ceilingOrigin = (Vector2)transform.position + ceilingCheck.offset;
        Gizmos.DrawLine(ceilingOrigin, ceilingOrigin + Vector2.up * ceilingCheck.distance);

        // Walls (both left and right)
        Gizmos.color = Color.red;
        Vector2 wallOrigin = (Vector2)transform.position + wallCheck.offset;
        Gizmos.DrawLine(wallOrigin, wallOrigin + Vector2.left * wallCheck.distance);
        Gizmos.DrawLine(wallOrigin, wallOrigin + Vector2.right * wallCheck.distance);
    }

    private void OnDrawGizmos()
    {
        // Draw the box collider in the Scene view for debugging.
        if (!drawGizmos || boxCollider == null)
            return;

        // Draw initial collider position as a blue wire cube.
        Gizmos.color = Color.blue;
        Gizmos.DrawWireCube(debugOrigin, debugSize);

        // Draw the full desired movement (if no collisions occurred) in green.
        Gizmos.color = Color.green;
        Vector3 desiredDestination = debugOrigin + debugDesiredMovement;
        Gizmos.DrawLine(debugOrigin, desiredDestination);
        Gizmos.DrawWireCube(desiredDestination, debugSize);

        // If a collision was detected, show the adjusted movement in red.
        if (debugHitFound)
        {
            Gizmos.color = Color.red;
            Vector3 adjustedDestination = debugOrigin + debugAdjustedMovement;
            Gizmos.DrawLine(debugOrigin, adjustedDestination);
            Gizmos.DrawWireCube(adjustedDestination, debugSize);
            // Mark the collision point.
            Gizmos.DrawSphere(debugHitPoint, 0.1f);
        }
    }
}

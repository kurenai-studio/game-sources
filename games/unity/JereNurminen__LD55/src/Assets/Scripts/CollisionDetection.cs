using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CollisionDetection : MonoBehaviour
{
    public LayerMask groundLayerMask;
    public LayerMask wallLayerMask;
    public int groundRaycastCount = 2;
    public float groundRaycastDistance = 1 / 16f;
    public int wallRaycastCount = 2;
    public int upRaycastCount = 2;
    public int horizontalRaycastCount = 2;
    public float wallRaycastDistance = 1 / 16f;
    private BoxCollider2D boxCollider;

    // Start is called before the first frame update
    void Start()
    {
        boxCollider = GetComponent<BoxCollider2D>();
    }

    // Update is called once per frame
    void Update() { }

    public RaycastHit2D? CheckForGround()
    {
        Vector2 colliderBottomLeft = new Vector2(
            boxCollider.bounds.min.x,
            boxCollider.bounds.center.y
        );
        float raylength = boxCollider.bounds.size.y / 2 + groundRaycastDistance;
        float colliderWidth = boxCollider.bounds.size.x;

        // This actually draws one more ray than defined in groundRaycastCount, don't care about fixing it rn
        for (int i = 0; i <= groundRaycastCount; i++)
        {
            Vector2 origin = new Vector2(
                colliderBottomLeft.x + (i * (colliderWidth / groundRaycastCount)),
                colliderBottomLeft.y
            );
            Debug.DrawRay(origin, Vector2.down * raylength, Color.red);
            RaycastHit2D hit = Physics2D.Raycast(origin, Vector2.down, raylength, groundLayerMask);
            if (hit.collider != null)
            {
                var health = hit.collider.gameObject.GetComponent<Health>();
                if (health != null && health.isDead)
                {
                    continue;
                }
                transform.position = new Vector2(
                    transform.position.x,
                    hit.point.y + boxCollider.bounds.size.y / 2 + groundRaycastDistance
                );
                return hit;
            }
        }
        return null;
    }

    public RaycastHit2D? CheckForCeiling()
    {
        Vector2 colliderTopLeft = new Vector2(boxCollider.bounds.min.x, boxCollider.bounds.max.y);
        float raylength = boxCollider.bounds.size.y / 2 + groundRaycastDistance;
        float colliderWidth = boxCollider.bounds.size.x;
        float originY = colliderTopLeft.y - boxCollider.bounds.size.y / 2;

        // This actually draws one more ray than defined in groundRaycastCount, don't care about fixing it rn
        for (int i = 0; i <= groundRaycastCount; i++)
        {
            Vector2 origin = new Vector2(
                colliderTopLeft.x + (i * (colliderWidth / upRaycastCount)),
                originY
            );
            Debug.DrawRay(origin, Vector2.up * raylength, Color.red);
            RaycastHit2D hit = Physics2D.Raycast(origin, Vector2.up, raylength, groundLayerMask);
            if (hit.collider != null)
            {
                var health = hit.collider.gameObject.GetComponent<Health>();
                if (health != null && health.isDead)
                {
                    continue;
                }
                return hit;
            }
        }
        return null;
    }

    public RaycastHit2D? CheckForWalls(float direction)
    {
        float raylength = boxCollider.bounds.size.x / 2 + wallRaycastDistance;
        float colliderHeight = boxCollider.bounds.size.y;
        Vector2 colliderBottomRight = new Vector2(
            boxCollider.bounds.max.x,
            boxCollider.bounds.min.y
        );
        float originX = colliderBottomRight.x - boxCollider.bounds.size.x / 2;
        float startY = colliderBottomRight.y + wallRaycastDistance;

        if (direction > 0)
        {
            for (int i = 0; i <= wallRaycastCount; i++)
            {
                Vector2 origin = new Vector2(
                    originX,
                    startY + (i * (colliderHeight / wallRaycastCount))
                );
                Debug.DrawRay(origin, Vector2.right * raylength, Color.red);
                RaycastHit2D hit = Physics2D.Raycast(
                    origin,
                    Vector2.right,
                    raylength,
                    wallLayerMask
                );
                if (hit.collider != null)
                {
                    var health = hit.collider.gameObject.GetComponent<Health>();
                    if (health != null && health.isDead)
                    {
                        continue;
                    }
                    return hit;
                }
            }
        }
        else if (direction < 0)
        {
            for (int i = 0; i <= wallRaycastCount; i++)
            {
                Vector2 origin = new Vector2(
                    originX,
                    startY + (i * (colliderHeight / wallRaycastCount))
                );
                Debug.DrawRay(origin, Vector2.left * raylength, Color.red);
                RaycastHit2D hit = Physics2D.Raycast(
                    origin,
                    Vector2.left,
                    raylength,
                    wallLayerMask
                );
                if (hit.collider != null)
                {
                    var health = hit.collider.gameObject.GetComponent<Health>();
                    if (health != null && health.isDead)
                    {
                        continue;
                    }
                    return hit;
                }
            }
        }
        return null;
    }
}

using System.Collections;
using UnityEngine;
using UnityEngine.Tilemaps;

[RequireComponent(typeof(Rigidbody2D))]
public class GridMovement2D : MonoBehaviour
{
    [Header("Grid")]
    [SerializeField] private float cellSize = 1f;
    [SerializeField] private float moveDuration = 0.12f;

    [Header("Collision")]
    [SerializeField] private Tilemap wallsTilemap;
    [SerializeField] private LayerMask obstacleLayer;
    [SerializeField] private float obstacleCheckRadius = 0.2f;


    private Rigidbody2D rb;
    private bool isMoving;

    private void Awake()
    {
        rb = GetComponent<Rigidbody2D>();
    }

    private void Update()
    {
        if (isMoving) return;

        Vector2Int dir = ReadInputDirection();
        if (dir == Vector2Int.zero) return;

        Vector2 start = rb.position;
        Vector2 target = start + (Vector2)dir * cellSize;

        if (IsBlocked(target))
            return;

        StartCoroutine(MoveTo(target));
    }

    // One move per key press, no diagonals.
    private static Vector2Int ReadInputDirection()
    {
        int x = 0;
        int y = 0;

        if (Input.GetKeyDown(KeyCode.A) || Input.GetKeyDown(KeyCode.LeftArrow)) x = -1;
        else if (Input.GetKeyDown(KeyCode.D) || Input.GetKeyDown(KeyCode.RightArrow)) x = 1;
        else if (Input.GetKeyDown(KeyCode.W) || Input.GetKeyDown(KeyCode.UpArrow)) y = 1;
        else if (Input.GetKeyDown(KeyCode.S) || Input.GetKeyDown(KeyCode.DownArrow)) y = -1;

        // Choose one axis only: horizontal first, then vertical.
        return new Vector2Int(x, y);
    }

    private bool IsBlocked(Vector2 targetWorldPos)
    {
        // 1) Tilemap blocking
        if (wallsTilemap != null)
        {
            Vector3Int cell = wallsTilemap.WorldToCell(targetWorldPos);
            if (wallsTilemap.HasTile(cell))
                return true;
        }

        // 2) Collider blocking (doors, crates, etc.)
        if (obstacleLayer.value != 0)
        {
            Collider2D hit = Physics2D.OverlapCircle(targetWorldPos, obstacleCheckRadius, obstacleLayer);
            if (hit != null)
                return true;
        }

        return false;
    }


    private IEnumerator MoveTo(Vector2 targetWorldPos)
    {
        isMoving = true;

        Vector2 start = rb.position;
        float elapsed = 0f;

        while (elapsed < moveDuration)
        {
            elapsed += Time.deltaTime;
            float t = Mathf.Clamp01(elapsed / moveDuration);
            Vector2 newPos = Vector2.Lerp(start, targetWorldPos, t);
            rb.MovePosition(newPos);
            yield return null;
        }

        // Snap to exact grid cell center to prevent drift
        if (wallsTilemap != null)
        {
            Vector3Int cell = wallsTilemap.WorldToCell(targetWorldPos);
            Vector3 snapped = wallsTilemap.GetCellCenterWorld(cell);
            rb.MovePosition(snapped);
        }
        else
        {
            rb.MovePosition(targetWorldPos);
        }

        isMoving = false;
    }

}

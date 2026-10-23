using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// Grid-based snake. The snake lives entirely in a list of grid cells;
/// movement, wall hits, self hits and food pickup are all resolved with
/// integer cell math — no Rigidbody, colliders or physics callbacks.
/// The spawned segment objects are pure visuals.
/// </summary>
public class SnakeMovement : MonoBehaviour
{
    public float moveInterval = 0.2f;
    public int StartSize = 5;

    public GameObject bodyPrefab;
    public GameObject headPrefab;

    public GameObject UIpanel;
    public GameObject gameoverpanel;

    private readonly List<Vector2Int> cells = new List<Vector2Int>();    // cells[0] is the head
    private readonly List<Transform> segments = new List<Transform>();   // segments[i] renders cells[i]
    private Vector2Int direction = Vector2Int.right;     // direction of the last executed move
    private Vector2Int nextDirection = Vector2Int.right; // buffered input, committed once per step
    private float moveTimer;
    private float height;

    private GenerateFloor floor;
    private GenerateFood food;
    private GenerateSpike spikes;

    /// <summary>Every cell currently occupied by the snake, head first.</summary>
    public IReadOnlyList<Vector2Int> Cells
    {
        get { return cells; }
    }

    /// <summary>Direction of the last executed move.</summary>
    public Vector2Int CurrentDirection
    {
        get { return direction; }
    }

    /// <summary>Requests a direction change, same rules as keyboard input.</summary>
    public void SetDirectionInput(Vector2Int candidate)
    {
        TrySetDirection(candidate);
    }

    /// <summary>
    /// Instantly grows the snake by the given number of segments. They stack
    /// on the tail cell and fan out as the snake moves, like normal growth.
    /// </summary>
    public void GrowBy(int amount)
    {
        for (int i = 0; i < amount; i++)
        {
            Vector2Int tail = cells[cells.Count - 1];
            cells.Add(tail);
            segments.Add(Instantiate(bodyPrefab, CellToWorld(tail), Quaternion.identity, transform).transform);
        }
    }

    private void Awake()
    {
        floor = FindObjectOfType<GenerateFloor>();
        height = transform.position.y;
        BuildSnake();
    }

    private void Start()
    {
        food = FindObjectOfType<GenerateFood>();
        spikes = FindObjectOfType<GenerateSpike>();
        GameManager.Instance.RegisterUI(UIpanel, gameoverpanel);
    }

    private void Update()
    {
        if (GameManager.Instance.IsGameOver)
        {
            return;
        }

        HandleInput();

        moveTimer += Time.deltaTime;
        if (moveTimer >= moveInterval)
        {
            moveTimer -= moveInterval;
            Step();
        }
    }

    private void BuildSnake()
    {
        Vector2Int headCell = WorldToCell(transform.position);
        if (floor != null)
        {
            headCell.x = Mathf.Clamp(headCell.x, -floor.PlayableHalfWidth, floor.PlayableHalfWidth);
            headCell.y = Mathf.Clamp(headCell.y, -floor.PlayableHalfDepth, floor.PlayableHalfDepth);
        }

        for (int i = 0; i <= StartSize; i++)
        {
            // The body trails behind the head, so no segments ever overlap
            Vector2Int cell = headCell - direction * i;
            cells.Add(cell);
            GameObject prefab = (i == 0) ? headPrefab : bodyPrefab;
            segments.Add(Instantiate(prefab, CellToWorld(cell), Quaternion.identity, transform).transform);
        }
    }

    private void HandleInput()
    {
        if (Input.GetKey(KeyCode.W))
        {
            TrySetDirection(Vector2Int.up);
        }
        if (Input.GetKey(KeyCode.S))
        {
            TrySetDirection(Vector2Int.down);
        }
        if (Input.GetKey(KeyCode.A))
        {
            TrySetDirection(Vector2Int.left);
        }
        if (Input.GetKey(KeyCode.D))
        {
            TrySetDirection(Vector2Int.right);
        }
    }

    private void TrySetDirection(Vector2Int candidate)
    {
        // Validate against the last executed direction (not the buffered one)
        // so two quick presses inside one step can never reverse the snake.
        if (candidate + direction != Vector2Int.zero)
        {
            nextDirection = candidate;
        }
    }

    private void Step()
    {
        direction = nextDirection;
        Vector2Int newHead = cells[0] + direction;

        if (HitsWall(newHead) || HitsBody(newHead) || HitsSpike(newHead))
        {
            Die();
            return;
        }

        bool ate = food != null && food.IsFoodAt(newHead);

        cells.Insert(0, newHead);
        if (ate)
        {
            // Keep the tail cell: the snake grows by one segment
            segments.Add(Instantiate(bodyPrefab, CellToWorld(cells[cells.Count - 1]), Quaternion.identity, transform).transform);
            GameManager.Instance.AddScore();
            food.Eat(newHead);
        }
        else
        {
            cells.RemoveAt(cells.Count - 1);
        }

        for (int i = 0; i < cells.Count; i++)
        {
            segments[i].position = CellToWorld(cells[i]);
        }
    }

    private bool HitsWall(Vector2Int cell)
    {
        if (floor == null)
        {
            return false;
        }
        return Mathf.Abs(cell.x) > floor.PlayableHalfWidth
            || Mathf.Abs(cell.y) > floor.PlayableHalfDepth;
    }

    private bool HitsSpike(Vector2Int cell)
    {
        return spikes != null && spikes.IsSpikeAt(cell);
    }

    private bool HitsBody(Vector2Int cell)
    {
        // The tail cell is excluded: it vacates on this same step. Food never
        // spawns on the snake, so eating can't coincide with the tail cell.
        for (int i = 0; i < cells.Count - 1; i++)
        {
            if (cells[i] == cell)
            {
                return true;
            }
        }
        return false;
    }

    private void Die()
    {
        GameManager.Instance.TriggerGameOver();

        // Hand the segments over to physics: they get a collider and a
        // rigidbody and simply collapse under gravity — no forces applied.
        // The shrink also keeps the snugly packed cubes from starting
        // interpenetrated, which the solver would shove apart.
        for (int i = 0; i < segments.Count; i++)
        {
            Transform part = segments[i];

            MeshRenderer renderer = part.GetComponent<MeshRenderer>();
            if (renderer != null)
            {
                renderer.material.color = Color.black;
            }

            part.localScale *= (i == 0) ? 0.95f : 0.9f;
            part.gameObject.AddComponent<BoxCollider>();
            part.gameObject.AddComponent<Rigidbody>();
        }
    }

    private Vector2Int WorldToCell(Vector3 position)
    {
        float ts = (floor != null) ? floor.tileSize : 1f;
        return new Vector2Int(Mathf.RoundToInt(position.x / ts), Mathf.RoundToInt(position.z / ts));
    }

    private Vector3 CellToWorld(Vector2Int cell)
    {
        float ts = (floor != null) ? floor.tileSize : 1f;
        return new Vector3(cell.x * ts, height, cell.y * ts);
    }
}

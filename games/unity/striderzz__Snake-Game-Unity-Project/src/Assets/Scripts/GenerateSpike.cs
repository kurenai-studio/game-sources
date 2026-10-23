using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// Scatters deadly spikes on random free grid cells at the start of a run.
/// Spikes claim their cells before food spawns, so food can never appear on
/// a spike. A safe zone around the snake's spawn keeps the start fair.
/// Detection is grid-based — the spike visuals carry no physics.
/// </summary>
public class GenerateSpike : MonoBehaviour
{
    public GameObject spikePrefab; // optional; a red block is created if left empty
    public int spikeCount = 6;
    public int safeRadius = 3;     // cells around the snake's spawn kept spike-free

    private readonly List<Vector2Int> spikeCells = new List<Vector2Int>();
    private bool spawned;
    private GenerateFloor floor;
    private SnakeMovement snake;

    public IReadOnlyList<Vector2Int> SpikeCells
    {
        get { return spikeCells; }
    }

    private void Start()
    {
        EnsureSpawned();
    }

    public bool IsSpikeAt(Vector2Int cell)
    {
        return spikeCells.Contains(cell);
    }

    /// <summary>
    /// Spawns the spikes if they haven't been spawned yet. GenerateFood calls
    /// this before placing food, so the spawn order never depends on Unity's
    /// script execution order.
    /// </summary>
    public void EnsureSpawned()
    {
        if (spawned)
        {
            return;
        }
        spawned = true;

        floor = FindObjectOfType<GenerateFloor>();
        snake = FindObjectOfType<SnakeMovement>();

        int halfWidth = (floor != null) ? floor.PlayableHalfWidth : 8;
        int halfDepth = (floor != null) ? floor.PlayableHalfDepth : 8;

        for (int i = 0; i < spikeCount; i++)
        {
            for (int attempt = 0; attempt < 200; attempt++)
            {
                Vector2Int cell = new Vector2Int(
                    Random.Range(-halfWidth, halfWidth + 1),
                    Random.Range(-halfDepth, halfDepth + 1));

                if (IsCellBlocked(cell))
                {
                    continue;
                }
                spikeCells.Add(cell);
                CreateSpikeVisual(cell);
                break;
            }
        }
    }

    private bool IsCellBlocked(Vector2Int cell)
    {
        if (spikeCells.Contains(cell))
        {
            return true;
        }
        if (snake != null && snake.Cells.Count > 0)
        {
            // Keep clear of the snake's body and a zone around its spawn
            Vector2Int head = snake.Cells[0];
            if (Mathf.Abs(cell.x - head.x) + Mathf.Abs(cell.y - head.y) <= safeRadius)
            {
                return true;
            }
            for (int i = 0; i < snake.Cells.Count; i++)
            {
                if (snake.Cells[i] == cell)
                {
                    return true;
                }
            }
        }
        return false;
    }

    private void CreateSpikeVisual(Vector2Int cell)
    {
        float ts = (floor != null) ? floor.tileSize : 1f;
        Vector3 position = new Vector3(cell.x * ts, 0f, cell.y * ts);

        GameObject spike;
        if (spikePrefab != null)
        {
            spike = Instantiate(spikePrefab, position, Quaternion.identity, transform);
        }
        else
        {
            // Fallback visual so the script works without a prefab assigned:
            // a red block rotated 45 degrees to read as a hazard
            spike = GameObject.CreatePrimitive(PrimitiveType.Cube);
            Destroy(spike.GetComponent<Collider>());
            spike.transform.SetParent(transform);
            spike.transform.position = position;
            spike.transform.rotation = Quaternion.Euler(0f, 45f, 0f);
            spike.transform.localScale = new Vector3(0.5f, 0.9f, 0.5f);
            spike.GetComponent<Renderer>().material.color = Color.red;
        }
        spike.name = "Spike " + cell;
    }
}

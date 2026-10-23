using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// Keeps 1-2 food items on the board. The spawn area comes straight from
/// GenerateFloor's playable bounds — no manual ranges. Food never spawns on
/// the snake, on a spike, or on another food. When the last food is eaten,
/// a fresh batch of 1-2 appears. Pickup is grid-based, no physics.
/// </summary>
public class GenerateFood : MonoBehaviour
{
    public GameObject foodPrefab;
    public SnakeMovement snakeMovement;
    public int minFoods = 1;
    public int maxFoods = 2;

    private readonly List<GameObject> foods = new List<GameObject>();
    private readonly List<Vector2Int> foodCells = new List<Vector2Int>();
    private GenerateFloor floor;
    private GenerateSpike spikes;

    public IReadOnlyList<Vector2Int> FoodCells
    {
        get { return foodCells; }
    }

    private void Start()
    {
        floor = FindObjectOfType<GenerateFloor>();
        spikes = FindObjectOfType<GenerateSpike>();
        if (snakeMovement == null)
        {
            snakeMovement = FindObjectOfType<SnakeMovement>();
        }

        // Spikes claim their cells first so food can never land on one
        if (spikes != null)
        {
            spikes.EnsureSpawned();
        }
        SpawnBatch();
    }

    public bool IsFoodAt(Vector2Int cell)
    {
        return foodCells.Contains(cell);
    }

    /// <summary>Consumes the food on the given cell; respawns when none are left.</summary>
    public void Eat(Vector2Int cell)
    {
        int index = foodCells.IndexOf(cell);
        if (index < 0)
        {
            return;
        }
        Destroy(foods[index]);
        foods.RemoveAt(index);
        foodCells.RemoveAt(index);

        if (foodCells.Count == 0)
        {
            SpawnBatch();
        }
    }

    private void SpawnBatch()
    {
        int count = Random.Range(minFoods, maxFoods + 1);
        for (int i = 0; i < count; i++)
        {
            SpawnOne();
        }
    }

    private void SpawnOne()
    {
        int halfWidth = (floor != null) ? floor.PlayableHalfWidth : 8;
        int halfDepth = (floor != null) ? floor.PlayableHalfDepth : 8;

        for (int attempt = 0; attempt < 500; attempt++)
        {
            Vector2Int cell = new Vector2Int(
                Random.Range(-halfWidth, halfWidth + 1),
                Random.Range(-halfDepth, halfDepth + 1));

            if (!IsCellFree(cell))
            {
                continue;
            }

            float ts = (floor != null) ? floor.tileSize : 1f;
            foodCells.Add(cell);
            foods.Add(Instantiate(foodPrefab, new Vector3(cell.x * ts, 0f, cell.y * ts), Quaternion.identity, transform));
            return;
        }
        Debug.LogWarning("GenerateFood: no free cell found for food.");
    }

    private bool IsCellFree(Vector2Int cell)
    {
        if (foodCells.Contains(cell))
        {
            return false;
        }
        if (spikes != null && spikes.IsSpikeAt(cell))
        {
            return false;
        }
        if (snakeMovement != null)
        {
            var snakeCells = snakeMovement.Cells;
            for (int i = 0; i < snakeCells.Count; i++)
            {
                if (snakeCells[i] == cell)
                {
                    return false;
                }
            }
        }
        return true;
    }
}

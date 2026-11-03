using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Tilemaps;

public class LevelLoader : MonoBehaviour
{
    [Header("Level Data")]
    [SerializeField] private LevelDefinition level;

    [Header("Scene References")]
    [SerializeField] private Grid grid;
    [SerializeField] private Tilemap wallsTilemap;
    [SerializeField] private Tilemap triggersTilemap;

    [Header("Tiles")]
    [SerializeField] private TileBase wallTile;   // use your existing wall tile asset
    [SerializeField] private TileBase plateTile;  // use your existing plate tile asset

    [Header("Prefabs")]
    [SerializeField] private Door2D doorPrefab;

    [Header("Parents")]
    [SerializeField] private Transform levelRoot; // where doors get spawned

    [Header("Player")]
    [SerializeField] private Transform player;

    private readonly Dictionary<string, Door2D> spawnedDoors = new();

    public void BuildLevel()
    {
        if (level == null || grid == null || wallsTilemap == null || triggersTilemap == null || player == null)
        {
            Debug.LogError("LevelLoader missing references.");
            return;
        }

        // Clear previous
        wallsTilemap.ClearAllTiles();
        triggersTilemap.ClearAllTiles();

        foreach (Transform child in levelRoot)
            Destroy(child.gameObject);

        spawnedDoors.Clear();

        // Paint walls
        if (wallTile != null)
        {
            foreach (var cell2 in level.wallCells)
            {
                Vector3Int cell = new(cell2.x, cell2.y, 0);
                wallsTilemap.SetTile(cell, wallTile);
            }
        }

        // Spawn doors
        foreach (var doorDef in level.doors)
        {
            Vector3Int cell = new(doorDef.cell.x, doorDef.cell.y, 0);
            Vector3 worldPos = wallsTilemap.GetCellCenterWorld(cell);

            Door2D door = Instantiate(doorPrefab, worldPos, Quaternion.identity, levelRoot);
            door.Initialize(doorDef.doorId, doorDef.startsClosed);

            spawnedDoors[doorDef.doorId] = door;
        }

        // Paint plates and register triggers
        if (plateTile != null)
        {
            foreach (var plateDef in level.plates)
            {
                Vector3Int cell = new(plateDef.cell.x, plateDef.cell.y, 0);
                triggersTilemap.SetTile(cell, plateTile);
            }
        }

        // Move player to start
        Vector3Int startCell = new(level.playerStartCell.x, level.playerStartCell.y, 0);
        Vector3 startWorld = wallsTilemap.GetCellCenterWorld(startCell);
        player.position = startWorld;

        // Hook triggers to doors
        GridTriggerSystem triggerSystem = FindFirstObjectByType<GridTriggerSystem>();
        if (triggerSystem != null)
        {
            triggerSystem.ConfigureFromLevel(level, triggersTilemap, plateTile, spawnedDoors);
        }
    }

    private void Start()
    {
        BuildLevel();
    }
}

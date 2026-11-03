using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Tilemaps;

public class GridTriggerSystem : MonoBehaviour
{
    [SerializeField] private Transform player;

    private Tilemap triggersTilemap;
    private TileBase plateTile;

    private Vector3Int lastCell;
    private bool hasLast;

    // Maps plate cell -> doors to toggle
    private readonly Dictionary<Vector3Int, List<Door2D>> plateActions = new();

    public void ConfigureFromLevel(
        LevelDefinition level,
        Tilemap triggersMap,
        TileBase plate,
        Dictionary<string, Door2D> doorsById)
    {
        triggersTilemap = triggersMap;
        plateTile = plate;

        plateActions.Clear();

        foreach (var plateDef in level.plates)
        {
            Vector3Int cell = new(plateDef.cell.x, plateDef.cell.y, 0);

            var list = new List<Door2D>();
            foreach (string id in plateDef.togglesDoorIds)
            {
                if (doorsById.TryGetValue(id, out Door2D door) && door != null)
                    list.Add(door);
            }

            plateActions[cell] = list;
        }
    }

    private void Start()
    {
        if (player == null)
            Debug.LogError("GridTriggerSystem missing player reference.");
    }

    private void Update()
    {
        if (player == null || triggersTilemap == null)
            return;

        Vector3Int cell = triggersTilemap.WorldToCell(player.position);

        if (hasLast && cell == lastCell)
            return;

        lastCell = cell;
        hasLast = true;

        HandleCellEntered(cell);
    }

    private void HandleCellEntered(Vector3Int cell)
    {
        if (!plateActions.TryGetValue(cell, out var doors))
            return;

        // Optional: verify the tile is actually a plate tile (extra safety)
        if (plateTile != null)
        {
            TileBase t = triggersTilemap.GetTile(cell);
            if (t != plateTile)
                return;
        }

        foreach (var door in doors)
            door?.Toggle();
    }
}

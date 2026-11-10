using UnityEngine;

public class TerrainController : MonoBehaviour
{
    [SerializeField]
    private Sprite[] tileSprites;

    [SerializeField]
    private Transform player;

    [SerializeField]
    private int bufferTiles = 1;

    [SerializeField]
    private string sortingLayerName = "Default";

    private float tileSize;
    private int gridWidth;
    private int gridHeight;
    private GameObject[,] tileObjects;
    private Vector2Int currentOrigin;
    private Camera cam;

    [HideInInspector]
    public bool isActive = true;

    void Start()
    {
        cam = Camera.main;
        tileSize = tileSprites[0].rect.width / tileSprites[0].pixelsPerUnit;

        float camHalfW = cam.orthographicSize * cam.aspect;
        float camHalfH = cam.orthographicSize;
        gridWidth = Mathf.CeilToInt(camHalfW * 2f / tileSize) + bufferTiles * 2 + 1;
        gridHeight = Mathf.CeilToInt(camHalfH * 2f / tileSize) + bufferTiles * 2 + 1;
        if (gridWidth % 2 == 0)
            gridWidth++;
        if (gridHeight % 2 == 0)
            gridHeight++;

        tileObjects = new GameObject[gridWidth, gridHeight];
        Vector2Int playerTile = WorldToTile(player.position);
        currentOrigin = playerTile - new Vector2Int(gridWidth / 2, gridHeight / 2);

        for (int x = 0; x < gridWidth; x++)
            for (int y = 0; y < gridHeight; y++)
                tileObjects[x, y] = CreateTile(currentOrigin + new Vector2Int(x, y));
    }

    void Update()
    {
        if (!isActive)
            return;

        Vector2Int playerTile = WorldToTile(player.position);
        Vector2Int desiredOrigin = playerTile - new Vector2Int(gridWidth / 2, gridHeight / 2);
        Vector2Int delta = desiredOrigin - currentOrigin;

        for (int i = 0; i < Mathf.Abs(delta.x); i++)
            ShiftColumnOnce(delta.x > 0 ? 1 : -1);

        for (int i = 0; i < Mathf.Abs(delta.y); i++)
            ShiftRowOnce(delta.y > 0 ? 1 : -1);
    }

    private void ShiftColumnOnce(int dir)
    {
        if (dir > 0)
        {
            for (int y = 0; y < gridHeight; y++)
            {
                GameObject tile = tileObjects[0, y];
                for (int x = 0; x < gridWidth - 1; x++)
                    tileObjects[x, y] = tileObjects[x + 1, y];
                tileObjects[gridWidth - 1, y] = tile;
                PositionTile(
                    tile,
                    new Vector2Int(currentOrigin.x + gridWidth, currentOrigin.y + y)
                );
            }
            currentOrigin.x++;
        }
        else
        {
            for (int y = 0; y < gridHeight; y++)
            {
                GameObject tile = tileObjects[gridWidth - 1, y];
                for (int x = gridWidth - 1; x > 0; x--)
                    tileObjects[x, y] = tileObjects[x - 1, y];
                tileObjects[0, y] = tile;
                PositionTile(tile, new Vector2Int(currentOrigin.x - 1, currentOrigin.y + y));
            }
            currentOrigin.x--;
        }
    }

    private void ShiftRowOnce(int dir)
    {
        if (dir > 0)
        {
            for (int x = 0; x < gridWidth; x++)
            {
                GameObject tile = tileObjects[x, 0];
                for (int y = 0; y < gridHeight - 1; y++)
                    tileObjects[x, y] = tileObjects[x, y + 1];
                tileObjects[x, gridHeight - 1] = tile;
                PositionTile(
                    tile,
                    new Vector2Int(currentOrigin.x + x, currentOrigin.y + gridHeight)
                );
            }
            currentOrigin.y++;
        }
        else
        {
            for (int x = 0; x < gridWidth; x++)
            {
                GameObject tile = tileObjects[x, gridHeight - 1];
                for (int y = gridHeight - 1; y > 0; y--)
                    tileObjects[x, y] = tileObjects[x, y - 1];
                tileObjects[x, 0] = tile;
                PositionTile(tile, new Vector2Int(currentOrigin.x + x, currentOrigin.y - 1));
            }
            currentOrigin.y--;
        }
    }

    private GameObject CreateTile(Vector2Int gridCoord)
    {
        GameObject go = new GameObject();
        go.transform.SetParent(transform);
        SpriteRenderer sr = go.AddComponent<SpriteRenderer>();
        sr.sortingLayerName = sortingLayerName;
        PositionTile(go, gridCoord);
        return go;
    }

    private void PositionTile(GameObject tile, Vector2Int gridCoord)
    {
        tile.transform.position = new Vector3(
            (gridCoord.x + 0.5f) * tileSize,
            (gridCoord.y + 0.5f) * tileSize,
            0f
        );
        tile.GetComponent<SpriteRenderer>().sprite = GetSpriteForCoord(gridCoord);
    }

    private Vector2Int WorldToTile(Vector2 worldPos)
    {
        return new Vector2Int(
            Mathf.FloorToInt(worldPos.x / tileSize),
            Mathf.FloorToInt(worldPos.y / tileSize)
        );
    }

    private Sprite GetSpriteForCoord(Vector2Int coord)
    {
        int hash = coord.x * 73856093 ^ coord.y * 19349663;
        return tileSprites[Mathf.Abs(hash) % tileSprites.Length];
    }
}

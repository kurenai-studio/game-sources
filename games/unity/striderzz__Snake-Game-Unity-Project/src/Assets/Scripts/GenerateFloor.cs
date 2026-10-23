using UnityEngine;

/// <summary>
/// Spawns the checkerboard floor and the border ring. Also defines the
/// playable grid bounds that SnakeMovement checks against — the border
/// tiles are purely visual, collision is done in grid coordinates.
/// </summary>
public class GenerateFloor : MonoBehaviour
{
    public GameObject floorTileWhite;
    public GameObject floorTileBlack;
    public GameObject BorderPrefab;
    public int x, y;
    public float tileSize = 1.0f;

    // Border tiles occupy the outermost ring at +-(x/2); cells inside are playable.
    public int PlayableHalfWidth
    {
        get { return x / 2 - 1; }
    }

    public int PlayableHalfDepth
    {
        get { return y / 2 - 1; }
    }

    private void Awake()
    {
        if (x % 2 == 0 || y % 2 == 0)
        {
            Debug.LogWarning("x and y should be odd for a center-aligned grid.");
        }

        int xOffset = x / 2;
        int yOffset = y / 2;

        for (int i = -xOffset; i <= xOffset; i++)
        {
            for (int j = -yOffset; j <= yOffset; j++)
            {
                GameObject tilePrefab = ((i + j) % 2 == 0) ? floorTileWhite : floorTileBlack;
                Instantiate(tilePrefab, new Vector3(i * tileSize, -1, j * tileSize), Quaternion.identity, transform);
            }
        }

        SpawnBorderTiles(xOffset, yOffset);
    }

    private void SpawnBorderTiles(int xOffset, int yOffset)
    {
        float borderHeight = 0.6f;

        for (int i = -xOffset; i <= xOffset; i++)
        {
            Instantiate(BorderPrefab, new Vector3(i * tileSize, borderHeight / 2, yOffset * tileSize), Quaternion.identity, transform);
            Instantiate(BorderPrefab, new Vector3(i * tileSize, borderHeight / 2, -yOffset * tileSize), Quaternion.identity, transform);
        }

        for (int j = -yOffset; j <= yOffset; j++)
        {
            Instantiate(BorderPrefab, new Vector3(xOffset * tileSize, borderHeight / 2, j * tileSize), Quaternion.identity, transform);
            Instantiate(BorderPrefab, new Vector3(-xOffset * tileSize, borderHeight / 2, j * tileSize), Quaternion.identity, transform);
        }
    }
}

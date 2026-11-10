using System.Collections.Generic;
using UnityEngine;

public class PropSpawner : MonoBehaviour
{
    [Header("Player")]
    [SerializeField]
    private Transform player;

    [Header("Prefabs")]
    [SerializeField]
    private GameObject[] treePrefabs;

    [SerializeField]
    private GameObject[] rockPrefabs;

    [Header("Chunk Settings")]
    [SerializeField]
    private float chunkSize = 20f;

    [SerializeField]
    private int viewDistanceChunks = 3;

    [Header("Spawn Amounts")]
    [SerializeField]
    private int treesPerChunk = 4;

    [SerializeField]
    private int rocksPerChunk = 3;

    [Header("Placement Rules")]
    [SerializeField]
    private float minDistanceBetweenProps = 2f;

    [SerializeField]
    private float minDistanceFromChunkEdge = 1f;

    [SerializeField]
    private int maxPlacementAttempts = 30;

    [SerializeField]
    private LevelManager levelManager;

    [SerializeField]
    private float baseClearRadius = 30f;

    [Header("Sorting")]
    [SerializeField]
    private string sortingLayerName = "Default";

    [SerializeField]
    private float sortingYScale = 1f;

    [HideInInspector]
    public bool isActive = true;

    private readonly Dictionary<Vector2Int, List<GameObject>> loadedChunks =
        new Dictionary<Vector2Int, List<GameObject>>();

    void Update()
    {
        if (!isActive)
            return;

        Vector2Int playerChunk = WorldToChunk(player.position);

        for (int x = -viewDistanceChunks; x <= viewDistanceChunks; x++)
            for (int y = -viewDistanceChunks; y <= viewDistanceChunks; y++)
            {
                Vector2Int coord = playerChunk + new Vector2Int(x, y);
                if (!loadedChunks.ContainsKey(coord))
                    LoadChunk(coord);
            }

        var toUnload = new List<Vector2Int>();
        foreach (var coord in loadedChunks.Keys)
        {
            if (
                Mathf.Abs(coord.x - playerChunk.x) > viewDistanceChunks + 1
                || Mathf.Abs(coord.y - playerChunk.y) > viewDistanceChunks + 1
            )
                toUnload.Add(coord);
        }

        foreach (var coord in toUnload)
            UnloadChunk(coord);
    }

    private void LoadChunk(Vector2Int chunkCoord)
    {
        var props = new List<GameObject>();
        var placed = new List<Vector2>();

        // Deterministic seed so the same chunk always looks the same
        var rng = new System.Random(chunkCoord.x * 73856093 ^ chunkCoord.y * 19349663);

        SpawnGroup(treePrefabs, treesPerChunk, chunkCoord, props, placed, rng);
        SpawnGroup(rockPrefabs, rocksPerChunk, chunkCoord, props, placed, rng);

        loadedChunks[chunkCoord] = props;
    }

    private void SpawnGroup(
        GameObject[] prefabs,
        int count,
        Vector2Int chunkCoord,
        List<GameObject> props,
        List<Vector2> placed,
        System.Random rng
    )
    {
        if (prefabs == null || prefabs.Length == 0)
            return;

        float inner = chunkSize - minDistanceFromChunkEdge * 2f;
        if (inner <= 0f)
            inner = chunkSize;

        Vector2 chunkOrigin = new Vector2(chunkCoord.x * chunkSize, chunkCoord.y * chunkSize);

        for (int i = 0; i < count; i++)
        {
            for (int attempt = 0; attempt < maxPlacementAttempts; attempt++)
            {
                float lx = (float)rng.NextDouble() * inner + minDistanceFromChunkEdge;
                float ly = (float)rng.NextDouble() * inner + minDistanceFromChunkEdge;
                Vector2 pos = chunkOrigin + new Vector2(lx, ly);

                bool tooClose = false;
                foreach (var p in placed)
                {
                    if (Vector2.Distance(pos, p) < minDistanceBetweenProps)
                    {
                        tooClose = true;
                        break;
                    }
                }

                if (!tooClose && levelManager != null)
                    tooClose = Vector2.Distance(pos, levelManager.BasePosition) < baseClearRadius;

                if (!tooClose)
                {
                    var prefab = prefabs[rng.Next(prefabs.Length)];
                    var go = Instantiate(
                        prefab,
                        new Vector3(pos.x, pos.y, 0f),
                        Quaternion.identity
                    );
                    go.transform.SetParent(transform, worldPositionStays: true);

                    var sr = go.GetComponent<SpriteRenderer>();
                    if (sr != null)
                    {
                        sr.sortingLayerName = sortingLayerName;
                        sr.sortingOrder = Mathf.RoundToInt(-pos.y * sortingYScale);
                    }

                    placed.Add(pos);
                    props.Add(go);
                    break;
                }
            }
        }
    }

    private void UnloadChunk(Vector2Int chunkCoord)
    {
        if (loadedChunks.TryGetValue(chunkCoord, out var props))
        {
            foreach (var go in props)
                if (go != null)
                    Destroy(go);
            loadedChunks.Remove(chunkCoord);
        }
    }

    private Vector2Int WorldToChunk(Vector2 worldPos)
    {
        return new Vector2Int(
            Mathf.FloorToInt(worldPos.x / chunkSize),
            Mathf.FloorToInt(worldPos.y / chunkSize)
        );
    }
}

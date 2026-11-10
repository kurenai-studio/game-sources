using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class WorldGenerator : MonoBehaviour
{
    public int tileSize = 64;
    public int minTrees = 100, maxTrees = 1000;
    public float worldPadding = 5f;

    public List<GameObject> tiles;
    public List<GameObject> resources;
    public GameObject player;
    public GameObject plot;

    public void Start()
    {
        GenerateBackgroundTiles();
        GenerateForest();
        PlacePlayer();
    }

    public void GenerateBackgroundTiles()
    {
        GameObject go = new GameObject("Tiles");
        GameObject tile = Instantiate(tiles[0], go.transform);

        SpriteRenderer sr = tile.GetComponent<SpriteRenderer>();
        sr.size = new Vector2(tileSize, tileSize);

        GameObject plots = new GameObject("Plots");
        for (int x = 0; x < tileSize / 2; x++)
        {
            for (int y = 0; y < tileSize / 2; y++)
            {
                GameObject p = Instantiate(plot, new Vector3(x * 2, y * 2, 0), Quaternion.identity, plots.transform);
            }
        }
    }

    public void GenerateForest()
    {
        GameObject go = new GameObject("Forest");
        int treeCount = Random.Range(minTrees, maxTrees);
        for (int i = 0; i < treeCount; i++)
        {
            GameObject tree = Instantiate(resources[0], go.transform);
            tree.transform.position = new Vector2(Random.Range(0f, tileSize), Random.Range(0f, tileSize));
        }
    }

    public void PlacePlayer()
    {
        GameObject go = Instantiate(player);
        go.transform.position = new Vector3(tileSize / 2, tileSize / 2, 0);
        Player p = go.GetComponent<Player>();
        p.worldPaddingMin = worldPadding;
        p.worldPaddingMax = tileSize - worldPadding;
    }
}

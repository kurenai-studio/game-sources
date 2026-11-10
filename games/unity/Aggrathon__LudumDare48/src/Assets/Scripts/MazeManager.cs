using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MazeManager : MonoBehaviour
{

    public int width = 21;
    public int height = 21;


    public List<PrefabProbability> prefabsWallEnd;
    public List<PrefabProbability> prefabsWallStraight;
    public List<PrefabProbability> prefabsWallTurn;
    public List<PrefabProbability> prefabsWallT;
    public List<PrefabProbability> prefabsWallCross;
    public List<PrefabProbability> prefabsWallAlone;
    public List<PrefabProbability> prefabsSpace;
    public List<PrefabProbability> prefabsSpaceEnd;
    public List<PrefabProbability> prefabsSpaceStraight;
    public List<PrefabProbability> prefabsSpaceCorner;
    public List<PrefabProbability> prefabsSpaceU;
    public List<PrefabProbability> prefabsSpaceEnclosed;

    public List<RectInt> reservedSpace;
    public List<RectInt> reservedWall;


    private List<List<PrefabProbability>> mazePrefabs;
    protected List<List<PrefabProbability>> MazePrefabs
    {
        get
        {
            if (mazePrefabs == null || mazePrefabs.Count != 12)
            {
                mazePrefabs = new List<List<PrefabProbability>>
                {
                    prefabsWallEnd,
                    prefabsWallStraight,
                    prefabsWallTurn,
                    prefabsWallT,
                    prefabsWallCross,
                    prefabsWallAlone,
                    prefabsSpace,
                    prefabsSpaceEnd,
                    prefabsSpaceStraight,
                    prefabsSpaceCorner,
                    prefabsSpaceU,
                    prefabsSpaceEnclosed
                };
            }
            return mazePrefabs;
        }
    }

    [System.Serializable]
    public struct PrefabProbability
    {
        public float prob;
        public GameObject prefab;
    }


    private void Start()
    {
        NormalisePrefabProbabilities();
    }


    [ContextMenu("Normalise Prefab Probabilities")]
    void NormalisePrefabProbabilities()
    {
        foreach (var list in MazePrefabs)
        {
            float sum = 0f;
            foreach (var pp in list)
            {
                sum += pp.prob;
            }
            if (sum > 0f)
            {
                sum = 1f / sum;
                for (int i = 0; i < list.Count; i++)
                {
                    list[i] = new PrefabProbability { prob = list[i].prob * sum, prefab = list[i].prefab };
                }
            }
        }
    }


    [ContextMenu("Generate Maze")]
    void GenerateMaze()
    {
        NormalisePrefabProbabilities();
        MazeGenerator gen = new MazeGenerator(width, height);
        int midX = width / 2;
        int midY = height / 2;
        foreach (RectInt r in reservedSpace)
        {
            gen.OpenSpace(r);
        }
        foreach (RectInt r in reservedWall)
        {
            gen.ForceWall(r);
        }
        gen.Generate();
        SpawnMaze(gen);
    }

    [ContextMenu("Clear Maze")]
    void ClearMaze()
    {
        for (int i = transform.childCount - 1; i >= 0; i--)
        {
#if UNITY_EDITOR
            DestroyImmediate(transform.GetChild(i).gameObject);
#else
            Destroy(transform.GetChild(i).gameObject);
#endif
        }
    }

    void SpawnMaze(MazeGenerator gen)
    {
        float offsetX = -width / 2;
        float offsetY = -height / 2;
        var mp = MazePrefabs;
        foreach ((int x, int y, MazeGenerator.CellShape cell, float rotation) in gen.GetCells())
        {
            int i = (int)cell;
            var prefabs = mp[i];
            if (prefabs.Count > 0)
            {
                Vector3 pos = new Vector3(x + offsetX, 0f, y + offsetY);
                if (prefabs.Count == 1)
                {
                    if (prefabs[0].prefab)
                        Instantiate(prefabs[0].prefab, pos, Quaternion.Euler(0, rotation, 0), transform);
                }
                else
                {
                    float rnd = Random.value;
                    foreach (var pp in prefabs)
                    {
                        if (rnd > pp.prob)
                        {
                            rnd -= pp.prob;
                        }
                        else
                        {
                            if (pp.prefab)
                                Instantiate(pp.prefab, pos, Quaternion.Euler(0, rotation, 0), transform);
                            break;
                        }
                    }
                }
            }
        }
        for (int i = 0; i < transform.childCount; i++)
        {
            transform.GetChild(i).gameObject.isStatic = true;
        }
    }

    private void OnDrawGizmosSelected()
    {
        Gizmos.color = Color.green;
        Gizmos.DrawWireCube(Vector3.zero, new Vector3(width, 0, height));
        float offsetX = -width / 2;
        float offsetY = -height / 2;
        foreach (RectInt r in reservedSpace)
        {
            Gizmos.DrawWireCube(new Vector3(r.x + offsetX, 0, r.y + offsetY), new Vector3(r.width, 0, r.height));
        }
        Gizmos.color = Color.red;
        foreach (RectInt r in reservedWall)
        {
            Gizmos.DrawWireCube(new Vector3(r.x + offsetX, 0, r.y + offsetY), new Vector3(r.width, 0, r.height));
        }
    }


}

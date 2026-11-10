using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GenerateBuildings : MonoBehaviour
{
    public float spaceBetweenBuildings = 50;

    public float xRows = 15;
    public float zRows = 15;

    public float minHeight;
    public float maxHeight;

    public Color[] colors;

    public GameObject trampoline;
    public GameObject pool;
    public GameObject hay;

    void Awake()
    {
        int currentLevel = PlayerPrefs.GetInt("Level", 1);

        float xOffset = transform.position.x;
        float zOffset = transform.position.z;

        for (int z = 0; z < zRows; z++)
        {
            for (int x = 0; x < xRows; x++)
            {
                int randomChance = Random.Range(0, 30 + (currentLevel * 4));

                if (randomChance == 1)
                {
                    GameObject trampolineObj = Instantiate(trampoline, new Vector3(x * spaceBetweenBuildings + xOffset, 0, z * spaceBetweenBuildings + zOffset), Quaternion.identity);
                    AddMeshColliders(trampolineObj);
                    trampolineObj.transform.SetParent(transform);
                    AddTags(trampolineObj, "Saver");
                }
                else if (randomChance == 2)
                {
                    GameObject hayObj = Instantiate(hay, new Vector3(x * spaceBetweenBuildings + xOffset, 0, z * spaceBetweenBuildings + zOffset), Quaternion.identity);
                    AddMeshColliders(hayObj);
                    hayObj.transform.SetParent(transform);
                    AddTags(hayObj, "Saver");
                }
                else
                {
                    GameObject cube = GameObject.CreatePrimitive(PrimitiveType.Cube);
                    cube.transform.SetParent(transform);
                    AddTags(cube, "Death");

                    int randomColor = Random.Range(0, colors.Length);
                    cube.GetComponent<Renderer>().material.color = colors[randomColor];

                    float randomHeight = Random.Range(minHeight, maxHeight);
                    cube.transform.localScale = new Vector3(15, randomHeight, 15);
                    cube.transform.position = new Vector3(x * spaceBetweenBuildings + xOffset, randomHeight / 2, z * spaceBetweenBuildings + zOffset);

                    if (randomChance == 3)
                    {
                        GameObject poolObj = Instantiate(pool, new Vector3(cube.transform.position.x, cube.transform.position.y * 2 + 1, cube.transform.position.z), Quaternion.identity);
                        AddMeshColliders(poolObj);
                        AddTags(poolObj, "Saver");
                        poolObj.transform.SetParent(transform);
                    }
                }
            }
        }
    }

    void AddMeshColliders(GameObject obj)
    {
        MeshCollider meshObj = obj.AddComponent<MeshCollider>();
        if (obj.transform.childCount > 0) obj.transform.GetChild(0).gameObject.AddComponent<MeshCollider>();
        meshObj.convex = true;
    }

    void AddTags(GameObject obj, string tag)
    {
        obj.tag = tag;
        if (obj.transform.childCount > 0) obj.transform.GetChild(0).gameObject.tag = tag;
    }
}
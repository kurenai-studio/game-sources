using System.Collections;
using System.Collections.Generic;
#if UNITY_EDITOR
using UnityEditor;
#endif
using UnityEngine;
using static Unity.Mathematics.math;

public class AsteroidSpawner : MonoBehaviour
{

    public Transform planet;
    public float atmosphere = 2f;
    public float radius = 10;
    public float density = 1;
    public float rnd = 0.8f;
    public GameObject[] prefabs;
    [Range(0, 1)] public float square = 0.3f;


    [ContextMenu("Spawn Asteroids")]
    public void SpawnAsteroids() {
        for (int i = transform.childCount-1; i >= 0; i--)
        {
            #if UNITY_EDITOR
                if (!EditorApplication.isPlaying)
                    DestroyImmediate(transform.GetChild(i).gameObject);
                else
            #endif
                Destroy(transform.GetChild(i).gameObject);
        }
        for (float j = density/2; j < radius; j += density)
        {
            float offset = Random.Range(-density, density) * rnd * 2;
            for (float i = density/2; i < radius; i += density)
            {
                if (i * i + j * j > radius * radius * (1f - square) + radius * square)
                    continue;
                for (float k = -1; k <= 1; k +=2)
                {
                    for (float l = -1; l <= 1; l +=2)
                    {
                        var vec = new Vector3(i * k + Random.Range(-density, density) * rnd + offset, j * l + Random.Range(-density, density) * rnd, 0.5f);
                        if ((vec - planet.position).sqrMagnitude > pow(planet.localScale.x / 2 + atmosphere, 2)) {
                            var p = prefabs[Random.Range(0, prefabs.Length)];
                            #if UNITY_EDITOR
                                var go = PrefabUtility.InstantiatePrefab(p, transform) as GameObject;
                                go.transform.position = vec;
                            #else
                                var go = Instantiate(p, vec, Quaternion.identity);
                            #endif
                        }
                    }
                }
            }
        }
    }
}

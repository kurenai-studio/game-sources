
using UnityEngine;

public class MeteoriteSpawner : MonoBehaviour
{
    public GameObject meteoritePrefab;
    public Transform player;

    public float spawnInterval = 2f;
    public float spawnHeight = 6f;
    public float horizontalRange = 4f;
    public float mobileHorizontalRange = 1.8f;

    void Start()
    {
        InvokeRepeating("SpawnMeteorite", 1f, spawnInterval);
    }

    void SpawnMeteorite()
    {
        float currentRange = Screen.height > Screen.width
        ? mobileHorizontalRange
        : horizontalRange;

        float randomX = Random.Range(
        -currentRange,
        currentRange
        );

        Vector3 spawnPosition = new Vector3(
            randomX,
            player.position.y + spawnHeight,
            0f
        );

        Instantiate(meteoritePrefab, spawnPosition, Quaternion.identity);
    }
}

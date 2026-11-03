
using UnityEngine;

public class PlatformSpawner : MonoBehaviour
{
    public GameObject platformPrefab;
    public Transform player;

    public float platformDistance = 2.5f;
    public float horizontalRange = 4f;
    public float mobileHorizontalRange = 1.3f;

    private float lastPlatformY = 0f;

    void Start()
    {
        lastPlatformY = player.position.y + 2f;
    }

    void Update()
    {
        if (player.position.y + 10f > lastPlatformY)
        {
            SpawnPlatform();
        }
    }

    void SpawnPlatform()
    {
        float currentRange = Screen.height > Screen.width
            ? mobileHorizontalRange
            : horizontalRange;

        float randomX = Random.Range(
            -currentRange,
            currentRange
        );
        lastPlatformY = lastPlatformY + platformDistance;

        Vector3 position = new Vector3(
            randomX,
            lastPlatformY,
            0f
        );

        Instantiate(platformPrefab, position, Quaternion.identity);
    }
}

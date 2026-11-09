using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class HealthSpawnerScript : MonoBehaviour
{
    // The prefab
    public GameObject healthPickupPrefab;

    // The pickup spawned at this location
    private GameObject currentPickup;

    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    public bool HasPickup() {
        return currentPickup != null;
    }

    public void SpawnPickup() {
        if (!currentPickup)
            currentPickup = Instantiate(healthPickupPrefab, new Vector3(gameObject.transform.position.x, gameObject.transform.position.y + 0.15f, gameObject.transform.position.z), Quaternion.identity);
    }
}

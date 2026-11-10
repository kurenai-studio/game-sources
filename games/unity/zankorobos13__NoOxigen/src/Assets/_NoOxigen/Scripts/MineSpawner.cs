
using UnityEngine;

public class MineSpawner : MonoBehaviour
{
    public GameObject mine_prefab;
    public bool isAlreadySpawned = false;
    
    public void Spawn()
    {
        if (!isAlreadySpawned)
        {
            Instantiate(mine_prefab, gameObject.transform.position, gameObject.transform.rotation);
            isAlreadySpawned = true;
        }
    }
}

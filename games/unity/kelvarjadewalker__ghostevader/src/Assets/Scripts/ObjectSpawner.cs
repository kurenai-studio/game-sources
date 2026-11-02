using System.Collections;
using UnityEngine;
using Random = UnityEngine.Random;

public class ObjectSpawner : MonoBehaviour
{
    // Editor Fields
    [SerializeField] private GameObject prefab;
    [SerializeField] private float timeBetweenSpawns;
    [SerializeField] private Transform[] spawnPointArray;
    
    // Internal Fields
    private bool _isRunning;  
    private Coroutine _spawningCoroutine;
    

    // Internal Functions
    private IEnumerator SpawnObjects()
    {
        WaitForSeconds delay = new WaitForSeconds(timeBetweenSpawns);

        while (_isRunning)
        {
            int spawnIndex = Random.Range(0, spawnPointArray.Length);
            Instantiate(prefab, spawnPointArray[spawnIndex].position, Quaternion.identity);
            yield return delay;
        }
    }

    public void StartSpawner()
    {
        if (_spawningCoroutine != null)
        {
            StopCoroutine(_spawningCoroutine);
        }

        _isRunning = true;
        _spawningCoroutine = StartCoroutine(SpawnObjects());
    }

   public void StopSpawner()
   {
        _isRunning = false;
   }

    
    
}

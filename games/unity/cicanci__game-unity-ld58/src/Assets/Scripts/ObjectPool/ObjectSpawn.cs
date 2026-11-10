using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(ObjectPool))]
public class ObjectSpawn : MonoBehaviour
{
    [SerializeField]
    private float _spawnRate;

    [SerializeField]
    private bool _manualTrigger;

    [SerializeField]
    private List<Vector3> _spawnPoints = new()
    {
        new Vector3(5.5f, 0, 3.5f),
        new Vector3(5.5f, 0, 0),
        new Vector3(5.5f, 0, -3.5f),
        new Vector3(0, 0, 3.5f),
        new Vector3(0, 0, -3.5f),
        new Vector3(-5.5f, 0, 3.5f),
        new Vector3(-5.5f, 0, 0),
        new Vector3(-5.5f, 0, -3.5f),
    };

    private float _spawnTimer;
    private ObjectPool _poolComponent;

    private void Awake()
    {
        _poolComponent = GetComponent<ObjectPool>();
    }

    private void Update()
    {
        if (_manualTrigger)
        {
            return;
        }

        if (Time.time > _spawnTimer)
        {
            SpawnObject();
        }
    }

    public GameObject SpawnObject()
    {
        _spawnTimer = Time.time + _spawnRate;
        var obj = _poolComponent.GetItem();
        obj.transform.position = _spawnPoints[Random.Range(0, _spawnPoints.Count)];
        return obj;
    }
}

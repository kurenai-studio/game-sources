using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PlayerSpawner : MonoBehaviour
{
    public GameObject player_spawner;
    public GameObject player_prefab;
    private static GameObject _player;
    public void SpawnPlayer()
    {
        _player = Instantiate(player_prefab, player_spawner.transform.position, player_spawner.transform.rotation);
    }

    public GameObject GetPlayer()
    {
        return _player;
    }
}

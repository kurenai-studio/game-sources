using System;
using UnityEngine;

public class Enemy : MonoBehaviour
{
    // Editor Fields
    [SerializeField] private float moveSpeed = 2;
    [SerializeField] private float timeBetweenDirectionChange = 1;
    
    // Internal Fields
    private Rigidbody2D _enemyRigidbody;
    private Player _playerScript;
    private float _timeToNextDirectionChange;
    
    // Unity Events
    private void Awake()
    {
        _enemyRigidbody = GetComponent<Rigidbody2D>();
    }

    private void Start()
    {
        _playerScript = FindAnyObjectByType<Player>();
        _timeToNextDirectionChange = 0;
    }

    private void Update()
    {
        _timeToNextDirectionChange -= Time.deltaTime;

        if (_timeToNextDirectionChange > 0)
        {
            return;
        }

        FindPlayer();
        _timeToNextDirectionChange = timeBetweenDirectionChange;
    }


    private void OnBecameInvisible()
    {
        Destroy(gameObject);
    }

    // Internal Functions
    private void FindPlayer()
    {
        if (_playerScript == null)
        {
            Destroy(gameObject);
            return;
        }

        Vector2 playerPosition = _playerScript.transform.position;
        Vector2 currentPosition = transform.position;
        Vector2 directionToPlayer = (playerPosition - currentPosition).normalized;

        _enemyRigidbody.linearVelocity = directionToPlayer * moveSpeed;
    }
}

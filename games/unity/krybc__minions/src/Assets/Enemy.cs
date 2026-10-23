using UnityEngine;

public class Enemy : MonoBehaviour
{
    private GameObject gameManager;
    private GameObject player;
    private Vector3 playerPosition;
    private Vector3 direction;
    private float speed = 2f;

    void Start()
    {
        player = GameObject.FindWithTag("Player");
        gameManager = GameObject.FindWithTag("GameController");
    }

    void Update()
    {
        FindPlayer();
        GoToPlayer();
    }

    void FindPlayer()
    {
        if (player)
        {
            playerPosition = player.transform.position;
        }
    }

    void GoToPlayer()
    {
        direction = playerPosition - transform.position;
        transform.position += direction.normalized * speed * Time.deltaTime;
    }

    private void OnCollisionEnter2D(Collision2D collision)
    {
        if (collision.gameObject.tag == "Gun")
        {
            Destroy(gameObject);
            Destroy(collision.gameObject);
            gameManager.GetComponent<GameManager>().EnemyKilled();
        }

        if (collision.gameObject.CompareTag("Player"))
        {
            Destroy(collision.gameObject);
            gameManager.GetComponent<GameManager>().GameOver();
        }
    }
}

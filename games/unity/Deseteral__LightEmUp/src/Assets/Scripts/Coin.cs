using UnityEngine;
using Random = UnityEngine.Random;

public class Coin : MonoBehaviour {
    private GameObject playerObject;
    private new Rigidbody2D rigidbody;
    private AudioManager audioManager;
    private Timer aliveTimer = new Timer();
    private Timer blinkingTimer = new Timer();
    private SpriteRenderer spriteRenderer;
    private Color originalColor;

    private void Start() {
        playerObject = GameObject.Find("Player");
        rigidbody = GetComponent<Rigidbody2D>();
        audioManager = GameObject.Find("AudioManager").GetComponent<AudioManager>();
        spriteRenderer = GetComponent<SpriteRenderer>();
        originalColor = spriteRenderer.color;
        
        var splashDirection = new Vector2(Random.Range(-1f, 1f), Random.Range(-1f, 1f)).normalized;
        splashDirection *= 0.5f;
        GetComponent<Rigidbody2D>().AddForce(splashDirection, ForceMode2D.Impulse);

        int timeToBeAlive = Random.Range(7, 12);
        aliveTimer.Set(timeToBeAlive * 1000);
        blinkingTimer.Set((timeToBeAlive - 3) * 1000);
    }

    private void FixedUpdate() {
        aliveTimer.Update();
        blinkingTimer.Update();
        
        var position = transform.position;
        var playerPosition = playerObject.transform.position;
        
        Vector2 directionToPlayer = (playerPosition - position).normalized;
        float distanceToPlayer = Vector2.Distance(position, playerPosition);
        float speedScale = (1f / distanceToPlayer) * 4f;
        
        if (distanceToPlayer < 3f) {
            rigidbody.AddForce(directionToPlayer * speedScale, ForceMode2D.Force);
        }
        
        if (blinkingTimer.Check()) {
            int timeMillis = (int) (Time.timeSinceLevelLoad * 1000);
            spriteRenderer.color = ((timeMillis % 1000) == 0) ? Color.white : originalColor;
        }
        
        if (aliveTimer.Check()) {
            Destroy(gameObject);
        }
    }

    private void OnCollisionEnter2D(Collision2D target) {
        if (target.gameObject.CompareTag("Player")) {
            GameObject.Find("GameMaster").GetComponent<GameMaster>().coins += 5;
            audioManager.PlayPickupCoinSound();
            
            Destroy(gameObject);
        }
    }
}
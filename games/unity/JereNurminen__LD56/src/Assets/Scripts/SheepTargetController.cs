using UnityEngine;

public class SheepTargetController : MonoBehaviour
{
    public float amplitude = 1f; // Height of the sine wave
    public float frequency = 1f; // Speed of the sine wave

    private Vector2 startLocalPos;
    private SheepController sheepController;
    private SpriteRenderer spriteRenderer;

    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start()
    {
        // Store the starting position of the GameObject
        startLocalPos = transform.localPosition;
        sheepController = GetComponentInParent<SheepController>();
        spriteRenderer = GetComponent<SpriteRenderer>();
    }

    void Update()
    {
        if (sheepController.isInRange && sheepController.isAlive)
        {
            spriteRenderer.enabled = true;
            float sineWave = Mathf.Sin(Time.time * frequency) * amplitude;
            float newY = startLocalPos.y + Mathf.Round(sineWave);

            // Update the local position of the GameObject
            transform.localPosition = new(startLocalPos.x, newY);
        }
        else
        {
            spriteRenderer.enabled = false;
        }
    }
}

using UnityEngine;

public class PickUpController : MonoBehaviour
{
    [SerializeField]
    private float amplitude = 0.5f;

    [SerializeField]
    private float frequency = 1f;

    [SerializeField]
    private LayerMask playerLayer;

    [SerializeField]
    private bool randomizePosition = false;

    [SerializeField]
    private float randomizeRange = 16f;

    private Vector2 startPosition;
    private bool hasBeenCollected = false;
    private Animator animator;

    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start()
    {
        startPosition = transform.localPosition;
        animator = GetComponent<Animator>();
    }

    private void OnCollisionEnter2D(Collision2D collision)
    {
        if (playerLayer == (playerLayer | (1 << collision.gameObject.layer)))
        {
            hasBeenCollected = true;
            GetComponent<Collider2D>().enabled = false;
            GetComponent<Score>().ScorePoints();
            animator.SetTrigger("collect");
        }
    }

    public void OnAnimationEnd()
    {
        Destroy(gameObject);
    }

    // Update is called once per frame
    void Update()
    {
        if (hasBeenCollected)
        {
            return;
        }

        // Calculate the new position using a sine wave
        float newY = startPosition.y + Mathf.Round(amplitude * Mathf.Sin(Time.time * frequency));
        transform.localPosition = new Vector2(startPosition.x, newY);
    }
}

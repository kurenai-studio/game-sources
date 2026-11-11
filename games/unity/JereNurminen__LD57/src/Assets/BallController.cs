using UnityEngine;

[RequireComponent(typeof(Stompable))]
public class BallController : MonoBehaviour
{
    [SerializeField]
    private float bounceHeight = 64f;

    [SerializeField]
    private float bounceCycleDuration = 1f;

    [SerializeField]
    private float bounceCycleOffset = 1f;

    private Vector2 originalPosition;
    private float elapsedTime;

    void Start()
    {
        originalPosition = transform.position;
    }

    void Update()
    {
        elapsedTime += Time.deltaTime;

        float normalizedTime =
            (elapsedTime + bounceCycleOffset) % bounceCycleDuration / bounceCycleDuration;

        float yOffset = 4 * bounceHeight * normalizedTime * (1 - normalizedTime);

        // Update the position, ensuring the bounce starts from the original position
        transform.position = new Vector2(originalPosition.x, originalPosition.y + yOffset);
    }

    private void OnDrawGizmosSelected()
    {
        // Visualize the bounce range in the editor
        Gizmos.color = Color.green;
        Gizmos.DrawLine(
            new Vector3(transform.position.x, originalPosition.y, transform.position.z),
            new Vector3(
                transform.position.x,
                originalPosition.y + bounceHeight,
                transform.position.z
            )
        );
    }
}

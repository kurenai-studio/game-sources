using UnityEngine;

public class FlipPreventer : MonoBehaviour
{
    private Transform parent;
    private Vector3 initialLocalPosition;

    void Start()
    {
        parent = transform.parent;
        initialLocalPosition = transform.localPosition;
    }

    void Update()
    {
        // Preserve the child's offset related to the parent
        Vector3 newPosition = initialLocalPosition;
        newPosition.x *= Mathf.Sign(parent.localScale.x);
        transform.localPosition = newPosition;

        // Keep the child's local scale constant by compensating for the parent's flip
        Vector3 newScale = transform.localScale;
        newScale.x = Mathf.Abs(newScale.x) * Mathf.Sign(parent.localScale.x);
        transform.localScale = newScale;
    }
}

using UnityEngine;

public class CameraHolder : MonoBehaviour
{
    public Camera targetCamera;
    public float minDistance = 0.1f;
    public float offset = 0.1f;

    float maxDistance;

    void Start()
    {
        maxDistance = (targetCamera.transform.position - transform.position).magnitude;
    }

    void Update()
    {
        Vector3 vector = (targetCamera.transform.position - transform.position).normalized;
        RaycastHit hit;
        float distance;
        Vector3 startPoint = transform.position + vector * minDistance;
        if (Physics.Raycast(startPoint, vector, out hit, maxDistance, ~0, QueryTriggerInteraction.Ignore))
        {
            distance = hit.distance;
        }
        else
            distance = maxDistance;
        targetCamera.transform.position = startPoint + vector * distance;
    }
}

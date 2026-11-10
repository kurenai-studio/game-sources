using UnityEngine;

public class CameraController : MonoBehaviour
{
    [SerializeField]
    public Transform target;

    [SerializeField]
    private float smoothSpeed = 5f;

    [SerializeField]
    private bool instantFollow = false;

    [Header("Zoom")]
    [SerializeField]
    private float zoomMinSize = 5f;

    [SerializeField]
    private float zoomMaxSize = 12f;

    [SerializeField]
    private float zoomTopSpeed = 10f; // speed at which maxSize is reached

    [SerializeField]
    private float zoomSmoothSpeed = 3f;

    private Camera cam;
    private Rigidbody2D targetRb;

    private void Awake()
    {
        cam = GetComponent<Camera>();
        if (cam == null)
            cam = Camera.main;
    }

    void LateUpdate()
    {
        if (target == null)
            return;

        // Follow
        Vector3 desired = new Vector3(target.position.x, target.position.y, transform.position.z);
        if (instantFollow)
            transform.position = desired;
        else
            transform.position = Vector3.Lerp(
                transform.position,
                desired,
                smoothSpeed * Time.deltaTime
            );

        // Zoom
        if (cam != null)
        {
            if (targetRb == null)
                targetRb = target.GetComponent<Rigidbody2D>();

            float speed = targetRb != null ? targetRb.linearVelocity.magnitude : 0f;
            float t = Mathf.Clamp01(speed / zoomTopSpeed);
            float targetSize = Mathf.Lerp(zoomMinSize, zoomMaxSize, t);
            cam.orthographicSize = Mathf.Lerp(
                cam.orthographicSize,
                targetSize,
                zoomSmoothSpeed * Time.deltaTime
            );
        }
    }
}

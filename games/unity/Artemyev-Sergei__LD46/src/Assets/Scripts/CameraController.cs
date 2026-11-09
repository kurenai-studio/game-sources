using UnityEngine;

[RequireComponent(typeof(Camera))]
public class CameraController : GenericUnitySingleton<CameraController>
{
    [Header("Drag")]
    [SerializeField]
    private float dragSpeed = 100;

    [Header("Zoom")]
    [SerializeField]
    private float zoomSpeed = 50;
    [SerializeField]
    private float zoomMin = 10;
    [SerializeField]
    private float zoomMax = 50;

    private Vector3 dragAndZoomDeltaThisFrame = new Vector3(); // x,y are for Drag, z is for Zoom
    private Camera camera;

    public Camera Camera
    {
        get
        {
            return this.camera;
        }
    }

    protected override void Initialize()
    {
        base.Initialize();

        this.camera = GetComponent<Camera>();
    }

    private void Update()
    {
        this.dragAndZoomDeltaThisFrame = new Vector3();

        Zoom();
        Drag();
        ApplyCameraRestrictions();
    }

    /// <summary>
    /// Zoom camera in/out with mouse scroll wheel
    /// </summary>
    private void Zoom()
    {
        float zoomDelta = Input.GetAxis("Mouse ScrollWheel") * this.zoomSpeed * Time.deltaTime;
        if (!Mathf.Approximately(zoomDelta, 0f))
        {
            this.dragAndZoomDeltaThisFrame.z -= this.zoomSpeed * zoomDelta;
        }
    }

    /// <summary>
    /// Hold mouse button and drag camera around
    /// </summary>
    private void Drag()
    {
        if (Input.GetMouseButton(2))
        {
            this.dragAndZoomDeltaThisFrame -= new Vector3(
                Input.GetAxis("Mouse X") * dragSpeed * Time.deltaTime,
                Input.GetAxis("Mouse Y") * dragSpeed * Time.deltaTime,
                0);
        }

        this.dragAndZoomDeltaThisFrame += new Vector3(
            Input.GetAxis("Horizontal") * dragSpeed * Time.deltaTime,
            Input.GetAxis("Vertical") * dragSpeed * Time.deltaTime,
            0);
    }

    private void ApplyCameraRestrictions()
    {
        // Keep camera within zoom area
        float desiredOrthographicSize = this.camera.orthographicSize + this.dragAndZoomDeltaThisFrame.z;
        if (desiredOrthographicSize < zoomMin || desiredOrthographicSize > zoomMax)
        {
            this.dragAndZoomDeltaThisFrame.z = 0f;
        }
    }

    private void LateUpdate()
    {
        this.camera.transform.position += new Vector3(this.dragAndZoomDeltaThisFrame.x, this.dragAndZoomDeltaThisFrame.y);
        this.camera.orthographicSize += this.dragAndZoomDeltaThisFrame.z;
    }
}

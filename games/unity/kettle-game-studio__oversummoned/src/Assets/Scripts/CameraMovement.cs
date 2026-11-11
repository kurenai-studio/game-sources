
using UnityEngine;

public class CameraMovement : MonoBehaviour
{
    public float CameraSpeed = 10;
    public float RotationSpeed = 10;
    public float DesiredGrabbedDemonHeights = 3f;
    public float MinZoom = 2;
    public float MaxZoom = 12;

    public float CameraMouseMoveThreshold = 0.1f;

    public GameObject LassoPrefab;

    public Camera Camera;

    public AudioSource demonPopInSound;
    public AudioSource demonPopOutSound;

    private DemonScript Demon;
    private LineRenderer lasso;
    private TileManager tileManager;

    void Start()
    {
        tileManager = FindAnyObjectByType<TileManager>();
    }

    void Update()
    {
        transform.Translate(
            CameraMoveVector() * Time.deltaTime * CameraSpeed,
            Space.Self
        );
        CheckCameraBounds();

        if (Input.GetMouseButton(1))
        {
            transform.Rotate(Vector3.up, Input.GetAxis("Mouse X") * RotationSpeed, Space.World);
        }
        Camera.orthographicSize = Mathf.Clamp(Camera.orthographicSize - Input.mouseScrollDelta.y, MinZoom, MaxZoom);
        if (Input.GetMouseButtonDown(0) && Demon == null)
        {
            var p0 = MouseRayStart();

            // Debug.Log($"LayerMask.NameToLayer = {LayerMask.NameToLayer("Demon")}");
            var didHit = Physics.Raycast(p0, Camera.transform.forward * 10, out var hitInfo, 1000, ~(1 << LayerMask.NameToLayer("Wall")));
            if (didHit)
            {
                var demon = hitInfo.collider.GetComponent<DemonScript>();
                if (demon != null)
                {
                    // Debug.Log($"Demon {demon.Name}");
                    Demon = demon;
                    Demon.StartBeHeld();
                    lasso = Instantiate(LassoPrefab).GetComponentInChildren<LineRenderer>();
                    demonPopInSound.Play();
                }
            }
        }

        if (!Input.GetMouseButton(0) && Demon != null)
        {
            Demon.StopBeHeld();
            Demon = null;
            Destroy(lasso.transform.parent.gameObject);
            lasso = null;
            demonPopOutSound.Play();
        }

        SetDemonPosition();
    }

    void SetDemonPosition()
    {
        if (Demon == null) return;

        var p0 = MouseRayStart();
        var v0 = Camera.transform.forward;
        var d = (DesiredGrabbedDemonHeights - p0.y) / v0.y;
        var desiredPosition = p0 + d * v0;

        // Demon.DemonBody.transform.position =  p0 + d * v0;
        var dist = Mathf.Min((desiredPosition - Demon.DemonBody.transform.position).magnitude, 1);
        Demon.DemonBody.velocity = (desiredPosition - Demon.DemonBody.transform.position).normalized * dist * 10;

        for (var i = 0; i < lasso.positionCount; i++)
        {
            lasso.SetPosition(i, Vector3.Lerp(desiredPosition, Demon.DemonBody.transform.position, (float)i / (lasso.positionCount - 1)));
        }
    }

    Vector3 MouseRayStart()
    {
        var clickXCoeff = (2 * (Input.mousePosition.x / Camera.pixelWidth) - 1) * Camera.orthographicSize * Camera.aspect;
        var clickYCoeff = (2 * (Input.mousePosition.y / Camera.pixelHeight) - 1) * Camera.orthographicSize;
        var rayOffset = Camera.transform.right * clickXCoeff + Camera.transform.up * clickYCoeff;
        return Camera.transform.position + rayOffset;
    }

    float ScalarMouseDirection(float mousePos, float winSize, float threshold)
    {
        if (mousePos < 0 || mousePos > winSize) return 0;
        var thresholdPx = winSize * threshold;
        if (mousePos < thresholdPx)
            return -1;
        if (winSize - mousePos < thresholdPx)
            return 1;
        return 0;
    }

    Vector3 CameraMoveVector()
    {
        var mousePos = Input.mousePosition;
        var moveVector = new Vector3(Input.GetAxis("Horizontal"), 0, Input.GetAxis("Vertical"));

        if (!Input.GetMouseButton(1) && Demon != null)
        {
            moveVector.x += ScalarMouseDirection(mousePos.x, Screen.width, CameraMouseMoveThreshold);
            moveVector.z += ScalarMouseDirection(mousePos.y, Screen.height, CameraMouseMoveThreshold);
        } else if (Input.GetMouseButton(2)) {
            moveVector.x += ScalarMouseDirection(mousePos.x, Screen.width, 0.4f);
            moveVector.z += ScalarMouseDirection(mousePos.y, Screen.height, 0.4f);
        }
        return moveVector.normalized;
    }

    void CheckCameraBounds()
    {
        if (tileManager == null) return;

        var x = Mathf.Clamp(transform.position.x, tileManager.minX, tileManager.maxX);
        var z = Mathf.Clamp(transform.position.z, tileManager.minZ, tileManager.maxZ);
        transform.position = new Vector3(x, transform.position.y, z);
    }
}

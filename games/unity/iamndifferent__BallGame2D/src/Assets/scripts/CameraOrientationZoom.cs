
using UnityEngine;

[RequireComponent(typeof(Camera))]
public class CameraOrientationZoom : MonoBehaviour
{
    [SerializeField, Range(1f, 2f)]
    private float portraitZoomMultiplier = 1.2f;

    private Camera targetCamera;
    private float originalOrthographicSize;

    private int previousWidth = -1;
    private int previousHeight = -1;

    private void Awake()
    {
        targetCamera = GetComponent<Camera>();

        if (!targetCamera.orthographic)
        {
            Debug.LogWarning(
                "CameraOrientationZoom requiere una cámara Orthographic."
            );

            enabled = false;
            return;
        }

        originalOrthographicSize = targetCamera.orthographicSize;

        ApplyZoom();
    }

    private void Update()
    {
        if (Screen.width != previousWidth ||
            Screen.height != previousHeight)
        {
            ApplyZoom();
        }
    }

    private void ApplyZoom()
    {
        previousWidth = Screen.width;
        previousHeight = Screen.height;

        bool isPortrait = Screen.height > Screen.width;

        targetCamera.orthographicSize = originalOrthographicSize *
            (isPortrait ? portraitZoomMultiplier : 1f);
    }
}

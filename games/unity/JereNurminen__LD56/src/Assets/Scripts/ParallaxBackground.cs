using UnityEngine;

public class ParallaxBackground : MonoBehaviour
{
    public Transform[] backgrounds; // Array of background transforms (2 elements for seamless tiling)
    public float parallaxEffectMultiplier = 0.5f;

    private Transform cam; // Reference to the camera transform
    private Vector3 lastCameraPosition;
    private float backgroundWidth; // The width of one background tile

    void Start()
    {
        cam = Camera.main.transform;
        lastCameraPosition = cam.position;

        // Calculate the width of the background based on the SpriteRenderer's bounds
        if (backgrounds.Length > 0 && backgrounds[0].GetComponent<SpriteRenderer>() != null)
        {
            backgroundWidth = backgrounds[0].GetComponent<SpriteRenderer>().bounds.size.x;
        }
    }

    void Update()
    {
        Vector3 deltaMovement = cam.position - lastCameraPosition;

        // Parallax effect for all backgrounds
        foreach (Transform background in backgrounds)
        {
            background.position += new Vector3(deltaMovement.x * parallaxEffectMultiplier, 0, 0);
        }

        // Check if a background is out of the camera's view and reposition it
        if (Mathf.Abs(cam.position.x - backgrounds[0].position.x) >= backgroundWidth)
        {
            float offset = backgroundWidth * 2f; // Move by two background widths to reposition
            if (cam.position.x > backgrounds[0].position.x)
            {
                backgrounds[0].position += new Vector3(offset, 0, 0);
            }
            else
            {
                backgrounds[1].position -= new Vector3(offset, 0, 0);
            }

            // Swap the references for the backgrounds
            Transform temp = backgrounds[0];
            backgrounds[0] = backgrounds[1];
            backgrounds[1] = temp;
        }

        lastCameraPosition = cam.position;
    }
}

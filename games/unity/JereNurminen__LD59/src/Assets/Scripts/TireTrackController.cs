using System.Collections;
using UnityEngine;

// Wheel positions for one of the 16 car directions (clockwise from North).
// Both offsets are in local car space: +X = right, +Y = forward.
[System.Serializable]
public struct WheelOffsets
{
    public Vector2 leftWheel;
    public Vector2 rightWheel;
}

public class TireTrackController : MonoBehaviour
{
    [Header("References")]
    [SerializeField]
    private PlayerController playerController;

    [SerializeField]
    private Rigidbody2D playerRb;

    [Header("Track Appearance")]
    [SerializeField]
    private Sprite trackSprite;

    [SerializeField]
    private string sortingLayerName = "Default";

    [Header("Track Behaviour")]
    [SerializeField]
    private float spawnInterval = 0.4f; // world units between stamps

    [SerializeField]
    private float minSpeed = 0.5f; // don't stamp when nearly still

    [SerializeField]
    private float fadeDuration = 4f;

    [SerializeField]
    private Color trackColor = new Color(0f, 0f, 0f, 0.4f);

    // 16 entries, index matches PlayerController direction sprites (CW from North):
    // 0=N 1=NNE 2=NE 3=ENE 4=E 5=ESE 6=SE 7=SSE
    // 8=S 9=SSW 10=SW 11=WSW 12=W 13=WNW 14=NW 15=NNW
    [Header("Wheel Positions (local space, per direction)")]
    [SerializeField]
    private WheelOffsets[] wheelOffsets = new WheelOffsets[16];

    private float distanceSinceLastStamp = 0f;
    private Vector2 lastPosition;
    private Transform trackParent;
    private SpriteRenderer playerSpriteRenderer;

    void Start()
    {
        lastPosition = playerRb.position;
        playerSpriteRenderer = playerController.GetComponent<SpriteRenderer>();

        // Keep scene tidy — parent all tracks to a single holder
        var holder = new GameObject("TireTracks");
        trackParent = holder.transform;
    }

    void Update()
    {
        Vector2 currentPos = playerRb.position;
        float moved = Vector2.Distance(currentPos, lastPosition);
        distanceSinceLastStamp += moved;
        lastPosition = currentPos;

        if (playerRb.linearVelocity.magnitude < minSpeed)
        {
            distanceSinceLastStamp = 0f;
            return;
        }

        if (distanceSinceLastStamp >= spawnInterval)
        {
            distanceSinceLastStamp -= spawnInterval;
            StampTracks(currentPos, playerController.CurrentAngle);
        }
    }

    private void StampTracks(Vector2 pos, float angleCWFromNorth)
    {
        if (wheelOffsets == null || wheelOffsets.Length != 16)
            return;

        // Resolve direction index the same way PlayerController does
        float angleCCWFromEast = (90f - angleCWFromNorth + 360f) % 360f;
        int dirIndex = Mathf.RoundToInt(angleCWFromNorth / 22.5f) % 16;

        WheelOffsets offsets = wheelOffsets[dirIndex];

        // Unity rotation: 0° = right (East), positive = CCW
        float unityAngle = 90f - angleCWFromNorth;
        Quaternion rot = Quaternion.Euler(0f, 0f, unityAngle);

        // Transform local offsets to world space
        Vector2 worldLeft = pos + (Vector2)(rot * offsets.leftWheel);
        Vector2 worldRight = pos + (Vector2)(rot * offsets.rightWheel);

        SpawnTrack(worldLeft, rot);
        SpawnTrack(worldRight, rot);
    }

    private void SpawnTrack(Vector2 worldPos, Quaternion rot)
    {
        if (trackSprite == null)
            return;

        var go = new GameObject("Track");
        go.transform.SetParent(trackParent, worldPositionStays: true);
        go.transform.position = new Vector3(worldPos.x, worldPos.y, 0f);
        go.transform.rotation = rot;

        var sr = go.AddComponent<SpriteRenderer>();
        sr.sprite = trackSprite;
        sr.color = trackColor;
        sr.sortingLayerName = sortingLayerName;
        sr.sortingOrder =
            (playerSpriteRenderer != null ? playerSpriteRenderer.sortingOrder : 0) - 1;

        StartCoroutine(FadeAndDestroy(sr, go));
    }

    private IEnumerator FadeAndDestroy(SpriteRenderer sr, GameObject go)
    {
        float elapsed = 0f;
        Color startColor = sr.color;

        while (elapsed < fadeDuration)
        {
            if (sr == null)
                yield break;

            elapsed += Time.deltaTime;
            float t = elapsed / fadeDuration;
            Color c = startColor;
            c.a = Mathf.Lerp(startColor.a, 0f, t);
            sr.color = c;
            yield return null;
        }

        if (go != null)
            Destroy(go);
    }

    private void OnDrawGizmosSelected()
    {
        if (wheelOffsets == null || wheelOffsets.Length != 16 || playerController == null)
            return;

        Vector2 origin =
            playerRb != null ? playerRb.position : (Vector2)playerController.transform.position;

        for (int i = 0; i < 16; i++)
        {
            float angleCWFromNorth = i * 22.5f;
            float unityAngle = 90f - angleCWFromNorth;
            Quaternion rot = Quaternion.Euler(0f, 0f, unityAngle);

            Vector2 worldLeft = origin + (Vector2)(rot * wheelOffsets[i].leftWheel);
            Vector2 worldRight = origin + (Vector2)(rot * wheelOffsets[i].rightWheel);

            // Highlight the active direction in yellow, others in grey
            bool isActive =
                Application.isPlaying
                && Mathf.RoundToInt(playerController.CurrentAngle / 22.5f) % 16 == i;

            Gizmos.color = isActive ? Color.yellow : new Color(0.6f, 0.6f, 0.6f, 0.3f);
            Gizmos.DrawSphere(worldLeft, 0.06f);
            Gizmos.DrawSphere(worldRight, 0.06f);

            // Line between the two wheels for this direction
            Gizmos.DrawLine(worldLeft, worldRight);

            // Forward indicator from wheel midpoint
            Vector2 mid = (worldLeft + worldRight) * 0.5f;
            Vector2 fwd = rot * Vector2.up * 0.2f;
            Gizmos.DrawLine(mid, mid + fwd);

#if UNITY_EDITOR
            UnityEditor.Handles.Label(worldLeft + Vector2.left * 0.1f, i.ToString());
#endif
        }
    }
}

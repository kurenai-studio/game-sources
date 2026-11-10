using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.UI;

public class InterfaceController : MonoBehaviour
{
    [Header("Phone Slide")]
    [SerializeField]
    private Image phonePanel;

    [SerializeField]
    private Vector2 hiddenPosition = new Vector2(0f, -1200f);

    [SerializeField]
    private float slideSpeed = 8f;

    [Header("Dim Overlay")]
    [SerializeField]
    private Image dimOverlay;

    [SerializeField]
    private float dimTargetAlpha = 0.6f;

    [SerializeField]
    private float dimFadeSpeed = 6f;

    [Header("Radar Frame")]
    [SerializeField]
    private Image radarFrame;

    [SerializeField]
    private Vector2 radarHiddenPosition = new Vector2(0f, -1200f);

    [SerializeField]
    private Image radarStrengthImage;

    [SerializeField]
    private Sprite[] radarStrengthSprites = new Sprite[11];

    [SerializeField]
    private Sprite radarStrengthDoneSprite;

    [Header("Signal Strength")]
    [SerializeField]
    private Image signalStrengthImage;

    [SerializeField]
    private Sprite[] signalStrengthSprites = new Sprite[11];

    [SerializeField]
    private Sprite signalStrengthDoneSprite;

    [Header("Found Signals")]
    [SerializeField]
    private Image signalCountImage;

    [SerializeField]
    private Sprite[] signalCountSprites = new Sprite[4]; // index 0-3

    [Header("GPS")]
    [SerializeField]
    private Image gpsArrowImage;

    // 8 directional sprites, clockwise from North:
    // 0=N  1=NE  2=E  3=SE  4=S  5=SW  6=W  7=NW
    [SerializeField]
    private Sprite[] gpsArrowSprites = new Sprite[8];

    [SerializeField]
    private Image gpsCloseImage;

    [SerializeField]
    private Sprite gpsCloseSprite;

    [SerializeField]
    private float gpsArrowDistance = 80f;

    [SerializeField]
    private float gpsCloseDistance = 20f;

    [SerializeField]
    private Image radasSignalCountImage;

    [SerializeField]
    private Sprite[] radasSignalCountSprites = new Sprite[4]; // index 0-3

    [Header("Map")]
    [SerializeField]
    private Image mapImage;

    [SerializeField]
    private int mapResolution = 256;

    [SerializeField]
    private float signalCircleRadius = 20f;

    [SerializeField]
    private int dotPixelRadius = 5;

    [SerializeField]
    private float circleRevealSpeed = 30f; // world units per second

    [SerializeField]
    private int circleOutlineThickness = 2;

    [SerializeField]
    private Color mapBackground = new Color(0.08f, 0.08f, 0.08f, 1f);

    [SerializeField]
    private Color signalColor = Color.cyan;

    [SerializeField]
    private Color baseColor = Color.red;

    [SerializeField]
    private float baseCircleRadius = 15f;

    [SerializeField]
    private float baseCircleStartRadius = 600f;

    [SerializeField]
    private float baseCircleDelay = 0.5f;

    private float baseCircleDelayTimer = -1f;

    [SerializeField]
    private Image playerMarkerImage;

    [SerializeField]
    private Sprite playerCarSprite;

    // 4 directional sprites for out-of-bounds: 0=up, 1=right, 2=down, 3=left
    [SerializeField]
    private Sprite[] playerOutOfBoundsSprites = new Sprite[4];

    private Vector2 visiblePosition;
    private RectTransform panelRect;
    private InputAction phoneAction;
    private Texture2D mapTexture;
    private Color[] clearPixels;
    private Vector2 mapBoundsHalfExtents = new Vector2(500f, 500f);
    private bool triangulationComplete = false;
    private Vector2 triangulatedBasePosition;
    private float baseAnimatedRadius = 0f;
    private Vector2 radarVisiblePosition;
    private RectTransform radarRect;
    private bool radarSlideOut = false;
    private float[] animatedRadii = new float[3];
    private float[] targetRadii = new float[3];
    private RectTransform playerMarkerRect;
    private RectTransform mapRect;

    public bool IsPhoneActive => phoneAction.IsPressed();

    private void Awake()
    {
        phoneAction = InputSystem.actions.FindAction("Phone");
        panelRect = phonePanel.rectTransform;
        visiblePosition = panelRect.anchoredPosition;

        radarRect = radarFrame.rectTransform;
        radarVisiblePosition = radarRect.anchoredPosition;

        playerMarkerRect = playerMarkerImage.rectTransform;
        mapRect = mapImage.rectTransform;

        mapTexture = new Texture2D(mapResolution, mapResolution, TextureFormat.RGBA32, false);
        mapTexture.filterMode = FilterMode.Bilinear;
        clearPixels = new Color[mapResolution * mapResolution];
        for (int i = 0; i < clearPixels.Length; i++)
            clearPixels[i] = mapBackground;
    }

    private void OnEnable() => phoneAction.Enable();

    private void OnDisable() => phoneAction.Disable();

    void Start()
    {
        panelRect.anchoredPosition = hiddenPosition;
    }

    void Update()
    {
        bool phoneActive = phoneAction.IsPressed();

        Vector2 target = phoneActive ? visiblePosition : hiddenPosition;
        panelRect.anchoredPosition = Vector2.Lerp(
            panelRect.anchoredPosition,
            target,
            slideSpeed * Time.deltaTime
        );

        float targetAlpha = phoneActive ? dimTargetAlpha : 0f;
        Color c = dimOverlay.color;
        c.a = Mathf.Lerp(c.a, targetAlpha, dimFadeSpeed * Time.deltaTime);
        dimOverlay.color = c;

        Vector2 radarTarget =
            (radarSlideOut || phoneActive) ? radarHiddenPosition : radarVisiblePosition;
        radarRect.anchoredPosition = Vector2.Lerp(
            radarRect.anchoredPosition,
            radarTarget,
            slideSpeed * Time.deltaTime
        );

        for (int i = 0; i < animatedRadii.Length; i++)
            animatedRadii[i] = Mathf.MoveTowards(
                animatedRadii[i],
                targetRadii[i],
                circleRevealSpeed * Time.deltaTime
            );

        if (triangulationComplete)
        {
            if (baseCircleDelayTimer >= 0f && baseCircleDelayTimer < baseCircleDelay)
                baseCircleDelayTimer += Time.deltaTime;

            if (baseCircleDelayTimer >= baseCircleDelay)
                baseAnimatedRadius = Mathf.MoveTowards(
                    baseAnimatedRadius,
                    baseCircleRadius,
                    circleRevealSpeed * Time.deltaTime
                );
        }
    }

    public void StartCircleReveal(int index, float targetRadius)
    {
        targetRadii[index] = targetRadius;
    }

    public void SetSignalStrength(float t)
    {
        if (triangulationComplete)
            return;

        int index = Mathf.RoundToInt(Mathf.Clamp01(t) * (signalStrengthSprites.Length - 1));
        signalStrengthImage.sprite = signalStrengthSprites[index];

        int radarIndex = Mathf.RoundToInt(Mathf.Clamp01(t) * (radarStrengthSprites.Length - 1));
        radarStrengthImage.sprite = radarStrengthSprites[radarIndex];
    }

    public void SetSignalCount(int count)
    {
        if (triangulationComplete || count >= signalCountSprites.Length)
            return;

        signalCountImage.sprite = signalCountSprites[count];
        radasSignalCountImage.sprite = radasSignalCountSprites[count];
    }

    public void MarkTriangulationComplete(Vector2 basePosition)
    {
        triangulationComplete = true;
        triangulatedBasePosition = basePosition;
        baseAnimatedRadius = baseCircleStartRadius;
        baseCircleDelayTimer = 0f;
        signalStrengthImage.sprite = signalStrengthDoneSprite;
        radarStrengthImage.sprite = radarStrengthDoneSprite;
        radarSlideOut = true;
    }

    public void SetGPSDirection(Vector2 direction, float distance)
    {
        bool showClose = distance <= gpsCloseDistance;
        bool showArrow = !showClose && distance <= gpsArrowDistance;

        gpsCloseImage.gameObject.SetActive(showClose);
        if (showClose)
            gpsCloseImage.sprite = gpsCloseSprite;

        gpsArrowImage.gameObject.SetActive(showArrow || showClose);

        if (showArrow && gpsArrowSprites.Length == 8)
        {
            float angleCWFromNorth =
                (Mathf.Atan2(direction.x, direction.y) * Mathf.Rad2Deg + 360f) % 360f;
            int index = Mathf.RoundToInt(angleCWFromNorth / 45f) % 8;
            gpsArrowImage.sprite = gpsArrowSprites[index];
        }
    }

    public void UpdateMap(Vector2 playerPos, SignalData[] signals, Vector2 boundsHalfExtents)
    {
        mapBoundsHalfExtents = boundsHalfExtents;
        mapTexture.SetPixels(clearPixels);

        if (signals != null)
        {
            for (int i = 0; i < signals.Length; i++)
            {
                SignalData s = signals[i];
                if (s.revealed)
                {
                    DrawCircleOutline(s.position, animatedRadii[i], signalColor);
                    //DrawFilledCircle(s.position, dotPixelRadius, signalColor);
                }
            }
        }

        if (triangulationComplete && baseAnimatedRadius > 0f)
            DrawCircleOutline(triangulatedBasePosition, baseAnimatedRadius, baseColor);

        mapTexture.Apply();

        mapImage.sprite = Sprite.Create(
            mapTexture,
            new Rect(0, 0, mapResolution, mapResolution),
            new Vector2(0.5f, 0.5f)
        );

        UpdatePlayerMarker(playerPos);
    }

    private void UpdatePlayerMarker(Vector2 playerPos)
    {
        float nx = playerPos.x / (mapBoundsHalfExtents.x * 2f) + 0.5f;
        float ny = playerPos.y / (mapBoundsHalfExtents.y * 2f) + 0.5f;

        bool outOfBounds = nx < 0f || nx > 1f || ny < 0f || ny > 1f;

        float mapW = mapRect.rect.width;
        float mapH = mapRect.rect.height;

        if (outOfBounds)
        {
            float cx = Mathf.Clamp01(nx);
            float cy = Mathf.Clamp01(ny);
            playerMarkerRect.anchoredPosition = new Vector2(
                cx * mapW - mapW * 0.5f,
                cy * mapH - mapH * 0.5f
            );

            float dx = playerPos.x / mapBoundsHalfExtents.x; // signed excess
            float dy = playerPos.y / mapBoundsHalfExtents.y;
            if (Mathf.Abs(dy) >= Mathf.Abs(dx))
                playerMarkerImage.sprite = playerOutOfBoundsSprites[dy >= 0 ? 0 : 2]; // up / down
            else
                playerMarkerImage.sprite = playerOutOfBoundsSprites[dx >= 0 ? 1 : 3]; // right / left
        }
        else
        {
            playerMarkerRect.anchoredPosition = new Vector2(
                nx * mapW - mapW * 0.5f,
                ny * mapH - mapH * 0.5f
            );
            playerMarkerImage.sprite = playerCarSprite;
        }
    }

    private Vector2Int WorldToPixel(Vector2 worldPos)
    {
        float nx = worldPos.x / (mapBoundsHalfExtents.x * 2f) + 0.5f;
        float ny = worldPos.y / (mapBoundsHalfExtents.y * 2f) + 0.5f;
        return new Vector2Int(
            Mathf.RoundToInt(nx * mapResolution),
            Mathf.RoundToInt(ny * mapResolution)
        );
    }

    private void DrawFilledCircle(Vector2 worldPos, int pixelRadius, Color color)
    {
        Vector2Int center = WorldToPixel(worldPos);
        for (int y = -pixelRadius; y <= pixelRadius; y++)
            for (int x = -pixelRadius; x <= pixelRadius; x++)
            {
                if (x * x + y * y <= pixelRadius * pixelRadius)
                    SetPixelSafe(center.x + x, center.y + y, color);
            }
    }

    private void DrawCircleOutline(Vector2 worldPos, float worldRadius, Color color)
    {
        Vector2Int center = WorldToPixel(worldPos);
        int half = circleOutlineThickness / 2;
        for (int t = -half; t <= half; t++)
        {
            float r = worldRadius + t * (mapBoundsHalfExtents.x * 2f / mapResolution);
            if (r <= 0f)
                continue;
            float pixelRadiusX = r / (mapBoundsHalfExtents.x * 2f) * mapResolution;
            float pixelRadiusY = r / (mapBoundsHalfExtents.y * 2f) * mapResolution;
            int steps = Mathf.Max(
                64,
                Mathf.RoundToInt(2f * Mathf.PI * Mathf.Max(pixelRadiusX, pixelRadiusY))
            );
            for (int i = 0; i < steps; i++)
            {
                float angle = 2f * Mathf.PI * i / steps;
                int px = Mathf.RoundToInt(center.x + Mathf.Cos(angle) * pixelRadiusX);
                int py = Mathf.RoundToInt(center.y + Mathf.Sin(angle) * pixelRadiusY);
                SetPixelSafe(px, py, color);
            }
        }
    }

    private void SetPixelSafe(int x, int y, Color color)
    {
        if (x >= 0 && x < mapResolution && y >= 0 && y < mapResolution)
            mapTexture.SetPixel(x, y, color);
    }

    private void DrawCross(Vector2 worldPos, int size, Color color)
    {
        Vector2Int center = WorldToPixel(worldPos);
        for (int i = -size; i <= size; i++)
        {
            SetPixelSafe(center.x + i, center.y, color);
            SetPixelSafe(center.x, center.y + i, color);
        }
    }
}

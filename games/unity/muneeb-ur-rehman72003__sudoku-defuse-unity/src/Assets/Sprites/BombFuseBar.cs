using UnityEngine;
using UnityEngine.UI;

[RequireComponent(typeof(Slider))]
public class BombFuseBar : MonoBehaviour
{
    [Header("Fuse Settings")]
    [SerializeField]
    private float fallbackMaximumTime = 300f;

    [SerializeField]
    private float criticalTimeSeconds = 30f;

    [SerializeField]
    private float pulseSpeed = 6f;

    private Slider fuseSlider;
    private Image fillImage;
    private RectTransform fillRect;

    private float maximumTime;

    private readonly Color32 normalFuseColor =
        new Color32(245, 197, 66, 255);

    private readonly Color32 criticalFuseColor =
        new Color32(255, 65, 65, 255);

    private void Awake()
    {
        fuseSlider = GetComponent<Slider>();

        fuseSlider.minValue = 0f;
        fuseSlider.maxValue = 1f;
        fuseSlider.value = 1f;
        fuseSlider.interactable = false;
        fuseSlider.transition =
            Selectable.Transition.None;

        if (fuseSlider.fillRect != null)
        {
            fillRect = fuseSlider.fillRect;

            fillImage =
                fuseSlider.fillRect.GetComponent<Image>();
        }
    }

    private void Start()
    {
        if (GameTimer.Instance != null &&
            GameTimer.Instance.RemainingTime > 0f)
        {
            maximumTime =
                GameTimer.Instance.RemainingTime;
        }
        else
        {
            maximumTime =
                fallbackMaximumTime;
        }

        UpdateFuseBar();
    }

    private void Update()
    {
        UpdateFuseBar();
    }

    private void UpdateFuseBar()
    {
        if (GameTimer.Instance == null)
        {
            return;
        }

        float remainingTime =
            GameTimer.Instance.RemainingTime;

        if (maximumTime <= 0f)
        {
            maximumTime =
                fallbackMaximumTime;
        }

        float normalizedTime =
            Mathf.Clamp01(
                remainingTime / maximumTime
            );

        fuseSlider.value =
            normalizedTime;

        bool isCritical =
            remainingTime > 0f &&
            remainingTime <= criticalTimeSeconds;

        if (remainingTime <= 0f)
        {
            SetFuseColor(
                criticalFuseColor
            );

            SetFuseScale(1f);
            return;
        }

        if (!isCritical)
        {
            SetFuseColor(
                normalFuseColor
            );

            SetFuseScale(1f);
            return;
        }

        float pulse =
            (
                Mathf.Sin(
                    Time.unscaledTime *
                    pulseSpeed
                ) + 1f
            ) / 2f;

        Color pulsingColor =
            Color.Lerp(
                normalFuseColor,
                criticalFuseColor,
                pulse
            );

        SetFuseColor(
            pulsingColor
        );

        float heightScale =
            Mathf.Lerp(
                1f,
                1.35f,
                pulse
            );

        SetFuseScale(
            heightScale
        );
    }

    private void SetFuseColor(
        Color color
    )
    {
        if (fillImage != null)
        {
            fillImage.color = color;
        }
    }

    private void SetFuseScale(
        float heightScale
    )
    {
        if (fillRect == null)
        {
            return;
        }

        fillRect.localScale =
            new Vector3(
                1f,
                heightScale,
                1f
            );
    }
}
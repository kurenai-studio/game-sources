using System.Collections;
using TMPro;
using UnityEngine;

public class GameTimer : MonoBehaviour
{
    public static GameTimer Instance
    {
        get;
        private set;
    }

    [Header("Timer Settings")]
    [SerializeField]
    private float startingTimeSeconds = 300f;

    [SerializeField]
    private float criticalTimeSeconds = 30f;

    [SerializeField]
    private float criticalPulseSpeed = 5f;

    private TMP_Text timerText;
    private TMP_Text timeChangeText;

    private RectTransform timerRect;
    private RectTransform timeChangeRect;

    private float remainingTime;
    private bool isTimerRunning;
    private bool hasTriggeredGameOver;

    private Coroutine timeChangeAnimation;

    private Color normalTimerColor;
    private Vector3 normalTimerScale;

    private readonly Color32 criticalTimerColor =
        new Color32(255, 65, 65, 255);

    private readonly Color32 bonusColor =
        new Color32(70, 220, 120, 255);

    private readonly Color32 penaltyColor =
        new Color32(255, 80, 80, 255);

    public float RemainingTime
    {
        get
        {
            return remainingTime;
        }
    }

    public bool HasTimeEnded
    {
        get
        {
            return remainingTime <= 0f;
        }
    }

    private void Awake()
    {
        Instance = this;

        FindTimerTexts();

        if (timerText == null)
        {
            Debug.LogError(
                "GameTimer could not find TimerText."
            );
        }
        else
        {
            timerRect =
                timerText.GetComponent<RectTransform>();

            normalTimerColor =
                timerText.color;

            if (timerRect != null)
            {
                normalTimerScale =
                    timerRect.localScale;
            }
        }

        if (timeChangeText == null)
        {
            Debug.LogError(
                "GameTimer could not find TimeChangeText."
            );
        }
        else
        {
            timeChangeText.text = "";
            timeChangeText.alpha = 0f;

            timeChangeRect =
                timeChangeText.GetComponent<RectTransform>();
        }
    }

    private void Start()
    {
        ResetTimer();
    }

    private void Update()
    {
        if (!isTimerRunning)
        {
            return;
        }

        remainingTime -= Time.deltaTime;

        if (remainingTime <= 0f)
        {
            EndTimer();
            return;
        }

        UpdateTimerText();
        UpdateCriticalWarning();
    }

    private void FindTimerTexts()
    {
        TMP_Text[] allTexts =
            GetComponentsInChildren<TMP_Text>(true);

        foreach (TMP_Text textComponent in allTexts)
        {
            if (textComponent.gameObject.name ==
                "TimerText")
            {
                timerText = textComponent;
            }
            else if (
                textComponent.gameObject.name ==
                "TimeChangeText"
            )
            {
                timeChangeText = textComponent;
            }
        }
    }

    public void AddTime(float seconds)
    {
        if (seconds <= 0f ||
            HasTimeEnded ||
            !isTimerRunning)
        {
            return;
        }

        remainingTime += seconds;

        UpdateTimerText();
        UpdateCriticalWarning();

        ShowTimeChange(
            $"+{Mathf.RoundToInt(seconds)}s",
            bonusColor
        );
    }

    public void SubtractTime(float seconds)
    {
        if (seconds <= 0f ||
            HasTimeEnded ||
            !isTimerRunning)
        {
            return;
        }

        remainingTime -= seconds;

        ShowTimeChange(
            $"-{Mathf.RoundToInt(seconds)}s",
            penaltyColor
        );

        if (remainingTime <= 0f)
        {
            EndTimer();
            return;
        }

        UpdateTimerText();
        UpdateCriticalWarning();
    }

    private void EndTimer()
    {
        remainingTime = 0f;
        isTimerRunning = false;

        UpdateTimerText();

        if (timerText != null)
        {
            timerText.color =
                criticalTimerColor;
        }

        if (timerRect != null)
        {
            timerRect.localScale =
                normalTimerScale;
        }

        if (hasTriggeredGameOver)
        {
            return;
        }

        hasTriggeredGameOver = true;

        if (SudokuBoard.Instance != null)
        {
            SudokuBoard.Instance.SetGameLocked(true);
        }

        if (GameOverManager.Instance != null)
        {
            GameOverManager.Instance.ShowGameOver(
                "TIME'S UP"
            );
        }
        else
        {
            Debug.Log(
                "Time is up! Game Over."
            );
        }
    }

    private void UpdateCriticalWarning()
    {
        if (timerText == null)
        {
            return;
        }

        bool isCritical =
            isTimerRunning &&
            remainingTime > 0f &&
            remainingTime <= criticalTimeSeconds;

        if (!isCritical)
        {
            timerText.color =
                normalTimerColor;

            if (timerRect != null)
            {
                timerRect.localScale =
                    normalTimerScale;
            }

            return;
        }

        float pulse =
            (Mathf.Sin(
                Time.unscaledTime *
                criticalPulseSpeed
            ) + 1f) / 2f;

        timerText.color =
            Color.Lerp(
                normalTimerColor,
                criticalTimerColor,
                pulse
            );

        if (timerRect != null)
        {
            float scaleMultiplier =
                Mathf.Lerp(
                    1f,
                    1.12f,
                    pulse
                );

            timerRect.localScale =
                normalTimerScale *
                scaleMultiplier;
        }
    }

    private void ShowTimeChange(
        string message,
        Color textColor
    )
    {
        if (timeChangeText == null ||
            timeChangeRect == null)
        {
            return;
        }

        if (timeChangeAnimation != null)
        {
            StopCoroutine(
                timeChangeAnimation
            );
        }

        timeChangeAnimation =
            StartCoroutine(
                AnimateTimeChange(
                    message,
                    textColor
                )
            );
    }

    private IEnumerator AnimateTimeChange(
        string message,
        Color textColor
    )
    {
        timeChangeText.text = message;
        timeChangeText.color = textColor;
        timeChangeText.alpha = 1f;

        Vector2 startPosition =
            new Vector2(0f, -65f);

        Vector2 endPosition =
            new Vector2(0f, -20f);

        timeChangeRect.anchoredPosition =
            startPosition;

        const float animationDuration = 0.9f;

        float elapsedTime = 0f;

        while (elapsedTime < animationDuration)
        {
            elapsedTime += Time.deltaTime;

            float progress =
                Mathf.Clamp01(
                    elapsedTime /
                    animationDuration
                );

            timeChangeRect.anchoredPosition =
                Vector2.Lerp(
                    startPosition,
                    endPosition,
                    progress
                );

            timeChangeText.alpha =
                1f - progress;

            yield return null;
        }

        timeChangeText.alpha = 0f;
        timeChangeText.text = "";

        timeChangeAnimation = null;
    }

    public void PauseTimer()
    {
        if (HasTimeEnded ||
            hasTriggeredGameOver)
        {
            return;
        }

        isTimerRunning = false;

        if (timerRect != null)
        {
            timerRect.localScale =
                normalTimerScale;
        }
    }

    public void ResumeTimer()
    {
        if (HasTimeEnded ||
            hasTriggeredGameOver)
        {
            return;
        }

        if (GameOverManager.Instance != null &&
            GameOverManager.Instance.IsResultShowing)
        {
            return;
        }

        isTimerRunning = true;
    }

    public void StopTimer()
    {
        isTimerRunning = false;

        if (timerRect != null)
        {
            timerRect.localScale =
                normalTimerScale;
        }
    }

    public void ResetTimer()
    {
        // Selected level ke mutabiq starting time lega.
        startingTimeSeconds =
            LevelSettingsData.GetStartingTime();

        remainingTime =
            startingTimeSeconds;

        isTimerRunning = true;
        hasTriggeredGameOver = false;

        UpdateTimerText();

        if (timerText != null)
        {
            timerText.color =
                normalTimerColor;
        }

        if (timerRect != null)
        {
            timerRect.localScale =
                normalTimerScale;
        }

        if (timeChangeText != null)
        {
            timeChangeText.text = "";
            timeChangeText.alpha = 0f;
        }
    }

    private void UpdateTimerText()
    {
        if (timerText == null)
        {
            return;
        }

        int totalSeconds =
            Mathf.CeilToInt(
                remainingTime
            );

        int minutes =
            totalSeconds / 60;

        int seconds =
            totalSeconds % 60;

        timerText.text =
            $"{minutes:00}:{seconds:00}";
    }

    private void OnDestroy()
    {
        if (timeChangeAnimation != null)
        {
            StopCoroutine(
                timeChangeAnimation
            );
        }

        if (Instance == this)
        {
            Instance = null;
        }
    }
}
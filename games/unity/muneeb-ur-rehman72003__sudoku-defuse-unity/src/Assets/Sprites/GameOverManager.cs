using System.Collections;
using TMPro;
using UnityEngine;
//using UnityEngine.InputSystem;
using UnityEngine.SceneManagement;
using UnityEngine.UI;

public class GameOverManager : MonoBehaviour
{
    public static GameOverManager Instance
    {
        get;
        private set;
    }

    private const string MainMenuSceneName =
        "MainMenu";

    private GameObject gameOverPanel;
    private RectTransform gameOverBoxRect;

    private CanvasGroup resultCanvasGroup;
    private Image gameOverPanelImage;

    private TMP_Text gameOverTitle;
    private TMP_Text gameOverReason;

    private Button restartButton;
    private Button nextLevelButton;
    private Button mainMenuButton;

    private KeyboardNavigation keyboardNavigation;

    private Coroutine resultAnimation;

    private bool isResultShowing;

    private Vector2 normalBoxPosition;
    private Vector3 normalBoxScale;

    private readonly Color32 gameOverTitleColor =
        new Color32(255, 80, 80, 255);

    private readonly Color32 victoryTitleColor =
        new Color32(70, 220, 120, 255);

    private readonly Color32 reasonColor =
        new Color32(245, 197, 66, 255);

    private readonly Color32 normalOverlayColor =
        new Color32(8, 12, 16, 230);

    private readonly Color32 explosionFlashColor =
        new Color32(255, 55, 55, 235);

    private readonly Color32 victoryFlashColor =
        new Color32(55, 220, 125, 220);

    public bool IsResultShowing
    {
        get
        {
            return isResultShowing;
        }
    }

    private void Awake()
    {
        Instance = this;

        FindResultObjects();

        keyboardNavigation =
            GetComponent<KeyboardNavigation>();

        if (gameOverPanel == null)
        {
            Debug.LogError(
                "GameOverManager could not find GameOverPanel."
            );
        }

        if (gameOverBoxRect == null)
        {
            Debug.LogError(
                "GameOverManager could not find GameOverBox."
            );
        }

        if (gameOverTitle == null)
        {
            Debug.LogError(
                "GameOverManager could not find GameOverTitle."
            );
        }

        if (gameOverReason == null)
        {
            Debug.LogError(
                "GameOverManager could not find GameOverReason."
            );
        }

        if (restartButton == null)
        {
            Debug.LogError(
                "GameOverManager could not find RestartButton."
            );
        }
        else
        {
            restartButton.onClick.AddListener(
                RestartGame
            );
        }

        if (nextLevelButton == null)
        {
            Debug.LogError(
                "GameOverManager could not find NextLevelButton."
            );
        }
        else
        {
            nextLevelButton.onClick.AddListener(
                LoadNextLevel
            );
        }

        if (mainMenuButton == null)
        {
            Debug.LogError(
                "GameOverManager could not find MainMenuButton."
            );
        }
        else
        {
            mainMenuButton.onClick.AddListener(
                ReturnToMainMenu
            );
        }
    }

    private void Start()
    {
        isResultShowing = false;

        if (gameOverPanel != null)
        {
            gameOverPanel.SetActive(false);
        }
    }

    private void FindResultObjects()
    {
        Transform panelTransform =
            transform.Find("GameOverPanel");

        if (panelTransform == null)
        {
            return;
        }

        gameOverPanel =
            panelTransform.gameObject;

        gameOverPanelImage =
            gameOverPanel.GetComponent<Image>();

        resultCanvasGroup =
            gameOverPanel.GetComponent<CanvasGroup>();

        if (resultCanvasGroup == null)
        {
            resultCanvasGroup =
                gameOverPanel.AddComponent<CanvasGroup>();
        }

        Transform boxTransform =
            panelTransform.Find("GameOverBox");

        if (boxTransform != null)
        {
            gameOverBoxRect =
                boxTransform.GetComponent<RectTransform>();

            if (gameOverBoxRect != null)
            {
                normalBoxPosition =
                    gameOverBoxRect.anchoredPosition;

                normalBoxScale =
                    gameOverBoxRect.localScale;
            }
        }

        TMP_Text[] allTexts =
            panelTransform.GetComponentsInChildren<TMP_Text>(
                true
            );

        foreach (TMP_Text textComponent in allTexts)
        {
            if (textComponent.gameObject.name ==
                "GameOverTitle")
            {
                gameOverTitle =
                    textComponent;
            }
            else if (
                textComponent.gameObject.name ==
                "GameOverReason"
            )
            {
                gameOverReason =
                    textComponent;
            }
        }

        Button[] allButtons =
            panelTransform.GetComponentsInChildren<Button>(
                true
            );

        foreach (Button buttonComponent in allButtons)
        {
            if (buttonComponent.gameObject.name ==
                "RestartButton")
            {
                restartButton =
                    buttonComponent;
            }
            else if (
                buttonComponent.gameObject.name ==
                "NextLevelButton"
            )
            {
                nextLevelButton =
                    buttonComponent;
            }
            else if (
                buttonComponent.gameObject.name ==
                "MainMenuButton"
            )
            {
                mainMenuButton =
                    buttonComponent;
            }
        }
    }

    public void ShowGameOver(string reason)
    {
        ShowResult(
            "BOMB EXPLODED",
            reason,
            gameOverTitleColor,
            false
        );
    }

    public void ShowVictory()
    {
        ShowResult(
            "BOMB DEFUSED",
            "PUZZLE SOLVED",
            victoryTitleColor,
            true
        );
    }

    private void ShowResult(
        string title,
        string reason,
        Color32 titleColor,
        bool isVictory
    )
    {
        if (isResultShowing)
        {
            return;
        }

        if (isVictory)
        {
            LevelProgressData.UnlockNextLevel(
                LevelSelectionData.SelectedLevel
            );
        }

        isResultShowing = true;

        if (GameTimer.Instance != null)
        {
            GameTimer.Instance.StopTimer();
        }

        if (SudokuBoard.Instance != null)
        {
            SudokuBoard.Instance.SetGameLocked(true);
        }

        if (keyboardNavigation != null)
        {
            keyboardNavigation.enabled = false;
        }

        if (gameOverTitle != null)
        {
            gameOverTitle.text =
                title;

            gameOverTitle.color =
                titleColor;
        }

        if (gameOverReason != null)
        {
            gameOverReason.text =
                reason;

            gameOverReason.color =
                reasonColor;
        }

        ConfigureResultButtons(
            isVictory
        );

        if (gameOverPanel == null)
        {
            return;
        }

        gameOverPanel.SetActive(true);
        gameOverPanel.transform.SetAsLastSibling();

        if (resultAnimation != null)
        {
            StopCoroutine(
                resultAnimation
            );
        }

        resultAnimation =
            StartCoroutine(
                AnimateResult(isVictory)
            );
    }

    private void ConfigureResultButtons(
        bool isVictory
    )
    {
        bool canLoadNextLevel =
            isVictory &&
            LevelSelectionData.SelectedLevel < 3;

        if (restartButton == null ||
            mainMenuButton == null)
        {
            return;
        }

        if (nextLevelButton != null)
        {
            nextLevelButton.gameObject.SetActive(
                canLoadNextLevel
            );
        }

        mainMenuButton.gameObject.SetActive(true);
        restartButton.gameObject.SetActive(true);

        RectTransform restartRect =
            restartButton.GetComponent<RectTransform>();

        RectTransform mainMenuRect =
            mainMenuButton.GetComponent<RectTransform>();

        RectTransform nextLevelRect =
            nextLevelButton != null
                ? nextLevelButton.GetComponent<RectTransform>()
                : null;

        PrepareButtonRect(
            restartRect
        );

        PrepareButtonRect(
            mainMenuRect
        );

        if (nextLevelRect != null)
        {
            PrepareButtonRect(
                nextLevelRect
            );
        }

        if (canLoadNextLevel)
        {
            // Level 1 aur Level 2 victory:
            // TRY AGAIN aur NEXT LEVEL same row mein.
            // MAIN MENU neeche center mein.

            restartRect.anchoredPosition =
                new Vector2(-125f, -35f);

            if (nextLevelRect != null)
            {
                nextLevelRect.anchoredPosition =
                    new Vector2(125f, -35f);
            }

            mainMenuRect.anchoredPosition =
                new Vector2(0f, -110f);
        }
        else
        {
            // Level fail ya Level 3 complete:
            // TRY AGAIN aur MAIN MENU barabar same row mein.

            restartRect.anchoredPosition =
                new Vector2(-125f, -70f);

            mainMenuRect.anchoredPosition =
                new Vector2(125f, -70f);
        }
    }

    private void PrepareButtonRect(
        RectTransform buttonRect
    )
    {
        if (buttonRect == null)
        {
            return;
        }

        buttonRect.anchorMin =
            new Vector2(0.5f, 0.5f);

        buttonRect.anchorMax =
            new Vector2(0.5f, 0.5f);

        buttonRect.pivot =
            new Vector2(0.5f, 0.5f);

        buttonRect.sizeDelta =
            new Vector2(210f, 55f);

        buttonRect.localScale =
            Vector3.one;
    }

    private IEnumerator AnimateResult(
        bool isVictory
    )
    {
        if (resultCanvasGroup == null ||
            gameOverBoxRect == null)
        {
            yield break;
        }

        Color flashColor =
            isVictory
                ? victoryFlashColor
                : explosionFlashColor;

        resultCanvasGroup.alpha = 0f;
        resultCanvasGroup.interactable = true;
        resultCanvasGroup.blocksRaycasts = true;

        gameOverBoxRect.anchoredPosition =
            normalBoxPosition;

        gameOverBoxRect.localScale =
            normalBoxScale * 0.72f;

        if (gameOverPanelImage != null)
        {
            gameOverPanelImage.color =
                flashColor;
        }

        const float appearDuration = 0.22f;

        float elapsedTime = 0f;

        while (elapsedTime < appearDuration)
        {
            elapsedTime +=
                Time.unscaledDeltaTime;

            float progress =
                Mathf.Clamp01(
                    elapsedTime /
                    appearDuration
                );

            float smoothProgress =
                Mathf.SmoothStep(
                    0f,
                    1f,
                    progress
                );

            resultCanvasGroup.alpha =
                smoothProgress;

            gameOverBoxRect.localScale =
                Vector3.Lerp(
                    normalBoxScale * 0.72f,
                    normalBoxScale * 1.08f,
                    smoothProgress
                );

            if (gameOverPanelImage != null)
            {
                gameOverPanelImage.color =
                    Color.Lerp(
                        flashColor,
                        normalOverlayColor,
                        smoothProgress
                    );
            }

            yield return null;
        }

        if (isVictory)
        {
            yield return StartCoroutine(
                AnimateVictorySettle()
            );
        }
        else
        {
            yield return StartCoroutine(
                AnimateExplosionShake()
            );
        }

        gameOverBoxRect.anchoredPosition =
            normalBoxPosition;

        gameOverBoxRect.localScale =
            normalBoxScale;

        resultCanvasGroup.alpha = 1f;

        if (gameOverPanelImage != null)
        {
            gameOverPanelImage.color =
                normalOverlayColor;
        }

        resultAnimation = null;
    }

    private IEnumerator AnimateExplosionShake()
    {
        const float shakeDuration = 0.38f;
        const float maximumShakeDistance = 20f;

        float elapsedTime = 0f;

        while (elapsedTime < shakeDuration)
        {
            elapsedTime +=
                Time.unscaledDeltaTime;

            float progress =
                Mathf.Clamp01(
                    elapsedTime /
                    shakeDuration
                );

            float remainingStrength =
                1f - progress;

            Vector2 shakeOffset =
                Random.insideUnitCircle *
                maximumShakeDistance *
                remainingStrength;

            gameOverBoxRect.anchoredPosition =
                normalBoxPosition +
                shakeOffset;

            gameOverBoxRect.localScale =
                Vector3.Lerp(
                    normalBoxScale * 1.08f,
                    normalBoxScale,
                    progress
                );

            yield return null;
        }
    }

    private IEnumerator AnimateVictorySettle()
    {
        const float settleDuration = 0.42f;

        float elapsedTime = 0f;

        while (elapsedTime < settleDuration)
        {
            elapsedTime +=
                Time.unscaledDeltaTime;

            float progress =
                Mathf.Clamp01(
                    elapsedTime /
                    settleDuration
                );

            float bounce =
                Mathf.Sin(
                    progress * Mathf.PI
                ) * 0.05f;

            gameOverBoxRect.localScale =
                normalBoxScale *
                (
                    Mathf.Lerp(
                        1.08f,
                        1f,
                        progress
                    ) +
                    bounce
                );

            yield return null;
        }
    }

//#if UNITY_EDITOR
//    private void Update()
//    {
//        if (Keyboard.current != null &&
//            Keyboard.current.f8Key.wasPressedThisFrame)
//        {
//            ShowVictory();
//        }
//    }
//#endif

    private void RestartGame()
    {
        string currentSceneName =
            SceneManager.GetActiveScene().name;

        SceneManager.LoadScene(
            currentSceneName
        );
    }

    private void LoadNextLevel()
    {
        int currentLevel =
            LevelSelectionData.SelectedLevel;

        if (currentLevel >= 3)
        {
            return;
        }

        int nextLevel =
            currentLevel + 1;

        LevelSelectionData.SelectLevel(
            nextLevel
        );

        string currentSceneName =
            SceneManager.GetActiveScene().name;

        SceneManager.LoadScene(
            currentSceneName
        );
    }

    private void ReturnToMainMenu()
    {
        SceneManager.LoadScene(
            MainMenuSceneName
        );
    }

    private void OnDestroy()
    {
        if (resultAnimation != null)
        {
            StopCoroutine(
                resultAnimation
            );
        }

        if (restartButton != null)
        {
            restartButton.onClick.RemoveListener(
                RestartGame
            );
        }

        if (nextLevelButton != null)
        {
            nextLevelButton.onClick.RemoveListener(
                LoadNextLevel
            );
        }

        if (mainMenuButton != null)
        {
            mainMenuButton.onClick.RemoveListener(
                ReturnToMainMenu
            );
        }

        if (Instance == this)
        {
            Instance = null;
        }
    }
}
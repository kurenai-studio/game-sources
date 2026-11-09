using TMPro;
using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.UI;

public class MainMenuManager : MonoBehaviour
{
    private const string GameSceneName =
        "GameScene";

    [Header("Menu Panels")]
    [SerializeField]
    private GameObject menuPanel;

    [SerializeField]
    private GameObject levelSelectPanel;

    [SerializeField]
    private GameObject howToPlayPanel;

    [Header("Level Buttons")]
    [SerializeField]
    private Button level1Button;

    [SerializeField]
    private Button level2Button;

    [SerializeField]
    private Button level3Button;

    private readonly Color32 unlockedNumberColor =
        new Color32(217, 164, 65, 255);

    private readonly Color32 lockedNumberColor =
        new Color32(105, 110, 100, 255);

    private readonly Color32 lockedButtonColor =
        new Color32(45, 49, 42, 255);

    private void Start()
    {
        ShowMainMenu();
        RefreshLevelButtons();
    }

    public void PlayGame()
    {
        int latestUnlockedLevel =
            LevelProgressData.HighestUnlockedLevel;

        SelectLevelAndPlay(
            latestUnlockedLevel
        );
    }

    public void SelectLevelAndPlay(
        int levelNumber
    )
    {
        if (!LevelProgressData.IsLevelUnlocked(
                levelNumber
            ))
        {
            return;
        }

        LevelSelectionData.SelectLevel(
            levelNumber
        );

        SceneManager.LoadScene(
            GameSceneName
        );
    }

    public void OpenLevelSelect()
    {
        HideAllPanels();

        if (levelSelectPanel != null)
        {
            levelSelectPanel.SetActive(true);
        }

        RefreshLevelButtons();
    }

    public void CloseLevelSelect()
    {
        ShowMainMenu();
    }

    public void OpenHowToPlay()
    {
        HideAllPanels();

        if (howToPlayPanel != null)
        {
            howToPlayPanel.SetActive(true);
            howToPlayPanel.transform.SetAsLastSibling();
        }
    }

    public void CloseHowToPlay()
    {
        ShowMainMenu();
    }

    private void ShowMainMenu()
    {
        HideAllPanels();

        if (menuPanel != null)
        {
            menuPanel.SetActive(true);
        }
    }

    private void HideAllPanels()
    {
        if (menuPanel != null)
        {
            menuPanel.SetActive(false);
        }

        if (levelSelectPanel != null)
        {
            levelSelectPanel.SetActive(false);
        }

        if (howToPlayPanel != null)
        {
            howToPlayPanel.SetActive(false);
        }
    }

    private void RefreshLevelButtons()
    {
        ConfigureLevelButton(
            level1Button,
            1
        );

        ConfigureLevelButton(
            level2Button,
            2
        );

        ConfigureLevelButton(
            level3Button,
            3
        );
    }

    private void ConfigureLevelButton(
        Button levelButton,
        int levelNumber
    )
    {
        if (levelButton == null)
        {
            return;
        }

        bool isUnlocked =
            LevelProgressData.IsLevelUnlocked(
                levelNumber
            );

        levelButton.interactable =
            isUnlocked;

        ColorBlock buttonColors =
            levelButton.colors;

        buttonColors.disabledColor =
            lockedButtonColor;

        levelButton.colors =
            buttonColors;

        TMP_Text numberText =
            levelButton.GetComponentInChildren<TMP_Text>(
                true
            );

        if (numberText != null)
        {
            numberText.color =
                isUnlocked
                    ? unlockedNumberColor
                    : lockedNumberColor;
        }
    }

    public void QuitGame()
    {
#if UNITY_EDITOR
        UnityEditor.EditorApplication.isPlaying =
            false;
#else
        Application.Quit();
#endif
    }
}
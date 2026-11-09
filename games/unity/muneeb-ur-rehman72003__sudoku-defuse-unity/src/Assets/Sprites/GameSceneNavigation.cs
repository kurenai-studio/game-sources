using UnityEngine;
using UnityEngine.SceneManagement;

public class GameSceneNavigation : MonoBehaviour
{
    private const string MainMenuSceneName =
        "MainMenu";

    [Header("Back Confirmation")]
    [SerializeField]
    private GameObject backConfirmationPanel;

    private void Start()
    {
        if (backConfirmationPanel != null)
        {
            backConfirmationPanel.SetActive(false);
        }
    }

    public void OpenBackConfirmation()
    {
        if (backConfirmationPanel == null)
        {
            return;
        }

        backConfirmationPanel.SetActive(true);
        backConfirmationPanel.transform.SetAsLastSibling();

        if (SudokuBoard.Instance != null)
        {
            SudokuBoard.Instance.SetGameLocked(true);
        }

        if (GameTimer.Instance != null)
        {
            GameTimer.Instance.PauseTimer();
        }
    }

    public void CloseBackConfirmation()
    {
        if (backConfirmationPanel != null)
        {
            backConfirmationPanel.SetActive(false);
        }

        bool resultIsShowing =
            GameOverManager.Instance != null &&
            GameOverManager.Instance.IsResultShowing;

        if (!resultIsShowing)
        {
            if (SudokuBoard.Instance != null)
            {
                SudokuBoard.Instance.SetGameLocked(false);
            }

            if (GameTimer.Instance != null)
            {
                GameTimer.Instance.ResumeTimer();
            }
        }
    }

    public void ReturnToMainMenu()
    {
        SceneManager.LoadScene(
            MainMenuSceneName
        );
    }
}
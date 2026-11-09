using System.Collections;
using UnityEngine;
using UnityEngine.SceneManagement;

public class SceneLoader : MonoBehaviour
{
    private readonly static int firstBattleIndex = 1;

    public event System.Action GameLevelLoaded; // Event raises right after playable level is loaded

    [SerializeField]
    private LoadingScreen loadingScreen;

    private static void LoadLevel(int levelIndex, System.Action onComplete = null, bool disableLoadingScreen = false)
    {
        if (levelIndex >= 0 && levelIndex < SceneManager.sceneCountInBuildSettings
            && Application.CanStreamedLevelBeLoaded(levelIndex))
        {
            if (GameManager.Instance.SceneLoader != null)
            {
                GameManager.Instance.SceneLoader.LoadLevelAsync(levelIndex, onComplete, disableLoadingScreen);
            }
            else
            {
                Debug.LogError("LevelLoader: Not loading asynchronously!");
                SceneManager.LoadScene(levelIndex);
            }
        }
        else
        {
            Debug.LogErrorFormat("LevelLoader: Can not load level with index {0}!", levelIndex);
        }
    }

    private void LoadLevelAsync(int levelIndex, System.Action onComplete = null, bool disableLoadingScreen = false)
    {
        StartCoroutine(LoadLevelAsyncRoutine(levelIndex, onComplete, disableLoadingScreen));
    }

    private IEnumerator LoadLevelAsyncRoutine(int levelIndex, System.Action onComplete = null, bool disableLoadingScreen = false)
    {
        if (!disableLoadingScreen)
        {
            yield return StartCoroutine(this.loadingScreen.FadeOnRoutine());
        }

        AsyncOperation ao = SceneManager.LoadSceneAsync(levelIndex, LoadSceneMode.Single);
        ao.allowSceneActivation = false;

        while (!ao.isDone)
        {
            ao.allowSceneActivation = (ao.progress >= 0.9f);
            yield return null;
        }

        if (onComplete != null)
        {
            onComplete();
        }

        if (levelIndex >= firstBattleIndex && GameLevelLoaded != null)
        {
            GameLevelLoaded(); // Send Game Level Initialization Event
        }

        if (!disableLoadingScreen)
        {
            yield return StartCoroutine(this.loadingScreen.FadeOffRoutine());
        }
    }

    public static void RestartBattle(System.Action onComplete = null, bool disableLoadingScreen = false)
    {
        LoadLevel(SceneManager.GetActiveScene().buildIndex, onComplete, disableLoadingScreen);
    }

    public static void LoadNextBattle(System.Action onComplete = null, bool disableLoadingScreen = false)
    {
        int nextLevelIndex = (SceneManager.GetActiveScene().buildIndex + 1) % SceneManager.sceneCountInBuildSettings;
        nextLevelIndex = Mathf.Clamp(nextLevelIndex, firstBattleIndex, nextLevelIndex);

        LoadLevel(nextLevelIndex, onComplete, disableLoadingScreen);
    }
}

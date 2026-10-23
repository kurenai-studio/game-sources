using System.Collections;
using UnityEngine;
using UnityEngine.SceneManagement;

public class GameManager : MonoBehaviour
{
    public static GameManager Instance;
    
    private void Awake()
    {
        if (!Instance)
        {
            Instance = this;
        }
        else
        {
            Destroy(gameObject);
        }
    }

    private void Start()
    {
        // Pause game until player starts
        Time.timeScale = 0f;
    }
    
    public void StartGame()
    {
        Time.timeScale = 1f;
    }
    
    public void GameOver()
    {
        StartCoroutine(WaitBeforeRestart());
        
        Time.timeScale = 0f;
    }
    
    private IEnumerator WaitBeforeRestart()
    {
        yield return new WaitForSecondsRealtime(2f);

        Time.timeScale = 1;   

        SceneManager.LoadScene(SceneManager.GetActiveScene().buildIndex);
    }
}

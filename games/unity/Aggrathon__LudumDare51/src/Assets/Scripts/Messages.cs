using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class Messages : MonoBehaviour
{
    [SerializeField] GameObject tutorial1;
    [SerializeField] GameObject tutorial2;
    [SerializeField] GameObject tutorial3;
    [SerializeField] GameObject gameOverScreen;
    [SerializeField] GameObject victoryScreen;
    int tutorialCount = 0;


    void Start()
    {
        tutorial1.SetActive(false);
        tutorial2.SetActive(false);
        tutorial3.SetActive(false);
        gameOverScreen.SetActive(false);
        victoryScreen.SetActive(false);
        tutorialCount = 0;
    }

    public void ShowNextTutorial()
    {
        tutorialCount++;
        switch (tutorialCount)
        {
            case 1:
                tutorial1.SetActive(true);
                StopTime();
                break;
            case 2:
                tutorial2.SetActive(true);
                StopTime();
                break;
            case 3:
                tutorial3.SetActive(true);
                StopTime();
                break;
        }
    }

    public void ShowDefeat()
    {
        gameOverScreen.SetActive(true);
        StopTime();
    }

    public void ShowVictory()
    {
        victoryScreen.SetActive(true);
        StopTime();
    }

    public void StopTime()
    {
        Time.timeScale = 0f;
    }

    public void ContinueTime()
    {
        Time.timeScale = 1f;
    }

    public void Restart()
    {
        SceneManager.LoadScene(SceneManager.GetActiveScene().buildIndex, LoadSceneMode.Single);
    }

    public void NextLevel()
    {
        SceneManager.LoadScene(SceneManager.GetActiveScene().buildIndex + 1, LoadSceneMode.Single);
    }
}

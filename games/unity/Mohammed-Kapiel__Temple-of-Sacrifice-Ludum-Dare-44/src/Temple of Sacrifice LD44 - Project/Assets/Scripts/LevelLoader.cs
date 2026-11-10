using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;
using TMPro;

public class LevelLoader : MonoBehaviour
{
    public TextMeshProUGUI[] texts;
    public AudioSource music;

    public GameObject pausePanel;


    private void Update()
    {
        if (Input.GetKeyDown(KeyCode.Escape))
        {
            if (pausePanel.activeInHierarchy)
            {
                Resume();
            }
            else
            {
                PauseScreen();
            }
        }
    }

    public void PauseScreen()
    {
        pausePanel.SetActive(true);
    }

    public void LoadGame()
    {
        SceneManager.LoadScene("Game");
    }

    public void LoadGameFancy()
    {
        Invoke("LoadGame", 3f);

        music.Stop();

        foreach (TextMeshProUGUI text in texts)
        {
            text.CrossFadeColor(new Color(255, 255, 255, 0), 1, true, true);
        }
    }

    public void Resume()
    {
        pausePanel.SetActive(false);
    }


    public void LoadMainMenu()
    {
        SceneManager.LoadScene("MainMenu");
    }

    public void ExitGame()
    {
        Application.Quit();
    }
}

using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.SceneManagement;

public class GameManager : MonoBehaviour
{

    public static bool dead = false;
    public static bool alive = false;

    public GameObject deadPanel;
    public GameObject alivePanel;

    public Text levelText;

    void Awake()
    {
        levelText.text = "Level: " + PlayerPrefs.GetInt("Level", 1);
    }

    void Update()
    {
        if (dead)
        {
            deadPanel.SetActive(true);
        }
        else
        {
            deadPanel.SetActive(false);
        }

        if (alive)
        {
            alivePanel.SetActive(true);
        }
        else
        {
            alivePanel.SetActive(false);
        }

        if (Input.GetKey("escape"))
        {
            Application.Quit();
        }
    }

    public void NewLevel()
    {
        AddLevel();
        ReloadScene();
    }

    public void Retry()
    {
        ReloadScene();
    }

    public void Reset()
    {
        PlayerPrefs.SetInt("Level", 1);

        ReloadScene();
    }

    public void ReloadScene()
    {
        SceneManager.LoadScene(SceneManager.GetActiveScene().buildIndex);

        alive = false;
        dead = false;
    }

    private void AddLevel()
    {
        int currentLevel = PlayerPrefs.GetInt("Level", 1);
        PlayerPrefs.SetInt("Level", currentLevel + 1);
        PlayerPrefs.Save();
    }

    public void Quit()
    {
        Application.Quit();
    }
}

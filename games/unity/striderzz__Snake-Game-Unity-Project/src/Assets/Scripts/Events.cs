using UnityEngine;
using UnityEngine.SceneManagement;

/// <summary>UI button handlers for the menu and game-over panels.</summary>
public class Events : MonoBehaviour
{
    public void Menu()
    {
        SceneManager.LoadScene("Menu");
    }

    public void Quit()
    {
        Application.Quit();
    }

    public void ResetGame()
    {
        SceneManager.LoadScene("Level");
    }

    public void Level()
    {
        SceneManager.LoadScene("Level");
    }
}

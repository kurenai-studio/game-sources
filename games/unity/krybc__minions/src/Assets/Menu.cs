using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.UI;

public class Menu : MonoBehaviour
{
    [SerializeField] private Text scoreText;
    
    private void Start()
    {
        if (PlayerPrefs.HasKey("Score") && PlayerPrefs.GetInt("Score") > 0)
        {
            scoreText.text = "Score: " + PlayerPrefs.GetInt("Score");
        }
        else
        {
            scoreText.text = "";
        }
    }

    public void Play()
    {
        SceneManager.LoadScene(1);
    }

    public void Quit()
    {
        PlayerPrefs.SetInt("Score", 0);
        Application.Quit();
    }
}

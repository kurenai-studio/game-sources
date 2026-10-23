using UnityEngine;
using UnityEngine.SceneManagement;

public class GameMenu : MonoBehaviour
{
	// Change to MainGame scene
	public void NewGame()
	{
		SceneManager.LoadScene("MainGame");
	}

	// Quit Game
	public void QuitGame()
	{
		Application.Quit();
	}
}

using UnityEngine;
using UnityEngine.SceneManagement;

public class LastScene : MonoBehaviour {
	public void Restart()
	{
		SceneManager.LoadScene("Level 1");
	}

	public void Quit()
	{
		Application.Quit();
	}
}

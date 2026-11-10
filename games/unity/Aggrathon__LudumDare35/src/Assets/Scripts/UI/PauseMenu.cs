using UnityEngine;
using UnityEngine.UI;
using UnityEngine.SceneManagement;

public class PauseMenu : MonoBehaviour {

	public Text title;

	bool paused;
	bool ended;
	GameData data;

	void Start()
	{
		data = GameData.instance;
		ended = false;
		UnPause();
	}

	void Update () {
		if(!ended) {
			if (data.progress == 1f)
			{
				title.text = "You Won!";
				Pause();
				ended = true;
			}
			else if (data.progress == -1f)
			{
				title.text = "You Lost!";
				Pause();
				ended = true;
			}
		}
		if(Input.GetButtonUp("Cancel"))
		{
			TogglePause();
		}
	}

	public void Restart()
	{
		SceneManager.LoadScene(SceneManager.GetActiveScene().buildIndex);
	}

	public void Quit()
	{
		Application.Quit();
	}

	public void MainMenu()
	{
		SceneManager.LoadScene(0);
	}

	public void TogglePause()
	{
		if (paused)
		{
			UnPause();
		}
		else
		{
			Pause();
		}
	}

	public void Pause()
	{
		Time.timeScale = 0f;
		for (int i = 0; i < transform.childCount; i++)
		{
			transform.GetChild(i).gameObject.SetActive(true);
		}
		paused = true;
	}

	public void UnPause()
	{
		Time.timeScale = 1f;
		for (int i = 0; i < transform.childCount; i++)
		{
			transform.GetChild(i).gameObject.SetActive(false);
		}
		paused = false;
	}

}

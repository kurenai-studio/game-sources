using System.Collections;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.SceneManagement;

public class RestartMenu : MonoBehaviour {

	public float fadeSpeed = 1f;

	void OnEnable()
	{
		StartCoroutine(FadeIn());
		GameState.SetMenuActive(true);
	}

	IEnumerator FadeIn()
	{
		float lerp = 0f;
		while (true)
		{
			lerp += Time.unscaledDeltaTime * fadeSpeed;
			if (lerp > 1f)
			{
				GetComponent<Image>().color = Color.black * 1f;
				for (int i = 0; i < transform.childCount; i++)
				{
					transform.GetChild(i).gameObject.SetActive(true);
				}
				break;
			}
			GetComponent<Image>().color = Color.black * lerp;
			yield return null;
		}
	}

	public void Restart()
	{
		SceneManager.LoadScene(SceneManager.GetActiveScene().buildIndex);
	}
}

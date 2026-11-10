using UnityEngine;
using UnityEngine.UI;
using UnityEngine.SceneManagement;
using System.Collections;

public class OutroText : MonoBehaviour {

	public Text text;
	public string nextScene;
	float fadeSpeed = 1f;

	void OnEnable()
	{
		text.text = string.Format(text.text, (int)(Time.timeSinceLevelLoad));
		StartCoroutine(FadeIn());
		GameState.SetMenuActive(true);
	}

	IEnumerator FadeIn()
	{
		float lerp = 0f;
		while(true)
		{
			lerp += Time.unscaledDeltaTime * fadeSpeed;
			if(lerp > 1f)
			{
				GetComponent<Image>().color = Color.black * 1f;
				for(int i = 0; i < transform.childCount; i++)
				{
					transform.GetChild(i).gameObject.SetActive(true);
				}
				break;
			}
			GetComponent<Image>().color = Color.black * lerp;
			yield return null;
		}
	}

	public void NextLevel()
	{
		SceneManager.LoadScene(nextScene);
	}
}

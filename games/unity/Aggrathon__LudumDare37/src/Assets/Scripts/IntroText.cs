using UnityEngine;
using UnityEngine.UI;
using UnityEngine.Events;

public class IntroText : MonoBehaviour {

	[TextArea]
	public string[] story;
	public Text text;
	public float fadeSpeed = 2f;
	public UnityEvent onFinished;

	int index;
	int nextIndex;
	float lerp;

	void Start()
	{
		GameState.SetMenuActive(true);
		text.text = "";
		index = -1;
		nextIndex = 0;
		lerp = 1f;
	}

	public void NextStep()
	{
		nextIndex = index + 1;
	}

	public void PrevStep()
	{
		if(index > 0)
			nextIndex = index - 1;
	}

	void Update()
	{
		if(Input.GetButtonUp("Next"))
		{
			NextStep();
		}
		if(index == nextIndex)
		{
			if(lerp < 1f)
			{
				lerp += Time.unscaledDeltaTime * fadeSpeed;
				if (lerp > 1f) lerp = 1f;
				text.color = Color.white * lerp;
			}
		}
		else
		{
			if(nextIndex == story.Length)
			{
				lerp -= Time.unscaledDeltaTime * fadeSpeed;
				if (lerp < 0f)
				{
					lerp = 0f;
					gameObject.SetActive(false);
				}
				else
					GetComponent<Image>().color = Color.black * lerp;
			}
			else if (nextIndex > story.Length)
			{
				gameObject.SetActive(false);
			}
			else
			{
				lerp -= Time.unscaledDeltaTime * fadeSpeed;
				if (lerp < 0f)
				{
					text.text = story[nextIndex];
					index = nextIndex;
					lerp = 0f;
				}
				text.color = Color.white * lerp;
			}
		}
	}

	void OnDisable()
	{
		onFinished.Invoke();
		GameState.SetMenuActive(false);
	}
}

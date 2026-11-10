using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class PlayerUI : MonoBehaviour {

	[Header("Sprint")]
	public Image sprintbar;
	public Text sprintText;
	public float sprintFadeSpeed = 1f;
	float sprintLerp;

	[Header("Abilities")]
	public GameObject throwIcon;
	public Text throwCount;
	int throwCache;
	public GameObject bucketIcon;
	bool bucketCache;


	FPSController player;

	void Start()
	{
		player = GameState.instance.player;
		throwCache = player.numThrowable-1;
		bucketCache = !player.hasBucket;
	}

	void Update()
	{
		if(player.sprintAmount < 1f)
		{
			sprintLerp += Time.deltaTime * sprintFadeSpeed;
			if (sprintLerp > 1f) sprintLerp = 1f;
			Color c = Color.white;
			c.a *= sprintLerp;
			sprintbar.color = c;
			sprintText.color = c;
			sprintbar.fillAmount = player.sprintAmount;
		}
		else
		{
			sprintLerp -= Time.deltaTime * sprintFadeSpeed;
			if (sprintLerp < 0f) sprintLerp = 0f;
			Color c = Color.white;
			c.a *= sprintLerp;
			sprintbar.color = c;
			sprintText.color = c;
		}

		if(throwCache != player.numThrowable)
		{
			throwCache = player.numThrowable;
			throwCount.text = throwCache.ToString();
			throwIcon.SetActive(throwCache > 0);
		}

		if(bucketCache != player.hasBucket)
		{
			bucketCache = player.hasBucket;
			bucketIcon.SetActive(bucketCache);
		}
	}
}

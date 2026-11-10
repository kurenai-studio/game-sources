using System.Collections;
using UnityEngine;

public class WindowLight : MonoBehaviour {

	public float startOff = 0.5f;
	public float maxOnTime = 600f;

	void Start () {
		if(Random.value < startOff)
		{
			gameObject.SetActive(false);
		}
		else
		{
			StartCoroutine(TurnOff());
		}
	}

	IEnumerator TurnOff()
	{
		float rnd = Random.value;
		yield return new WaitForSeconds(rnd * rnd * maxOnTime);
		gameObject.SetActive(false);
	}
}

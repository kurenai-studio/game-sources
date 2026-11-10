using UnityEngine;
using System.Collections;

public class DisableAfter : MonoBehaviour {

	public float delay = 2f;

	WaitForSeconds wait;
	
	void Awake()
	{
		wait = new WaitForSeconds(delay);
	}

	void OnEnable () {
		StartCoroutine(Disable());
	}
	
	IEnumerator Disable()
	{
		yield return wait;
		gameObject.SetActive(false);
	}
}

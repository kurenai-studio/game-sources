using UnityEngine;
using System.Collections;

public class Expire : MonoBehaviour
{

	public float expiration = 30f;

	void OnEnable()
	{
		StartCoroutine(Expiration());
	}

	IEnumerator Expiration()
	{
		yield return new WaitForSeconds(expiration);
		gameObject.SetActive(false);
	}
}

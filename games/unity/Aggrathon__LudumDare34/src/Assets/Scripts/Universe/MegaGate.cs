using UnityEngine;
using System.Collections;

public class MegaGate : MonoBehaviour
{
	public void OnEnable()
	{
		WarpGate wg = GetComponent<WarpGate>();
		wg.SpawnLoopers();
		for (int i = 0; i < wg.loopers.Length; i++)
		{
			wg.loopers[i].GetComponent<Looper>().speed *= 3f;
			wg.loopers[i].GetComponent<Looper>().randomness *= 2f;
		}

	}

	public void OnTriggerEnter2D(Collider2D collision)
	{
		if(collision.gameObject.tag == "Player")
		{
			StartCoroutine(Finish());
		}
	}

	IEnumerator Finish ()
	{
		yield return new WaitForSeconds(3f);
		Quest.instance.End();
	}
}

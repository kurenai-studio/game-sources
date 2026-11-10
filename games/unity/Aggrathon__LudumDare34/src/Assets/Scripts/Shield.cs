using UnityEngine;
using System.Collections;

public class Shield : MonoBehaviour
{

	float time = 0f;

	public void EnableShield(float duration)
	{
		gameObject.SetActive(true);
		time = duration;
	}

	void Update()
	{
		time -= Time.deltaTime;
		if (time < 0)
		{
			gameObject.SetActive(false);
		}
	}

	public void OnTriggerEnter2D(Collider2D collision)
	{
		if (collision.gameObject.tag == "Missile" || collision.gameObject.tag == "Ship")
		{
			collision.gameObject.SetActive(false);
		}
	}
}

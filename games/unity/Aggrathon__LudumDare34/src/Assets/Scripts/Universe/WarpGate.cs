using UnityEngine;

public class WarpGate : MonoBehaviour
{
	private bool tempDisable = false;

	public WarpGate target;
	public Warper warper;
	public bool antiClockWiseOrbit = false;
	public GameObject looper;
	public int looperAmount = 10;
	public GameObject[] loopers;

	public void Awake()
	{
		ObjectPool.CreatePool(looper, looperAmount);
	}

	public void OnTriggerEnter2D(Collider2D collision)
	{
		if (collision.gameObject.tag == "Player")
		{
			if (tempDisable)
			{
				tempDisable = false;
			}
			else
			{
				warper.Warp(collision.gameObject.GetComponent<Ship>(), target, transform.position);
				Quest.instance.Travel();
			}
		}
	}

	public void WarpComplete()
	{
		tempDisable = true;
	}

	public void PrepareEnemies()
	{
		transform.parent.GetComponent<PlanetarySystem>().SpawnEnemies();
	}

	public void SpawnLoopers()
	{
		loopers = new GameObject[looperAmount];
		for (int i = 0; i < looperAmount; i++)
		{
			loopers[i] = ObjectPool.GetObject(looper);
			loopers[i].transform.position = transform.position;
			loopers[i].transform.parent = transform;
		}
	}
	public void DespawnLoopers()
	{
		for (int i = 0; i < loopers.Length; i++)
		{
			loopers[i].gameObject.SetActive(false);
		}
	}

	public void OnDrawGizmos()
	{
		if(target != null)
		{
			Gizmos.color = new Color(0.6f, 0.7f, 1f, 0.5f);
			Gizmos.DrawLine(transform.position, target.transform.position);
		}
	}
}

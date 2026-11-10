using UnityEngine;
using System.Collections.Generic;

public class GameObjectPool : MonoBehaviour
{
	private static Dictionary<GameObject, LinkedList<GameObject>> dict;

	private static bool exiting = false;

	void Awake()
	{
		exiting = false;
		if(dict == null)
		{
			dict = new Dictionary<GameObject, LinkedList<GameObject>>();
		}
	}

	void OnEnable()
	{
		exiting = false;
		if (dict == null)
		{
			dict = new Dictionary<GameObject, LinkedList<GameObject>>();
		}
	}

	void OnDisable()
	{
		exiting = true;
	}

	void OnDestroy()
	{
		dict.Clear();
	}

	public static void Recycle(PoolObject po)
	{
		if(!exiting)
		{
			dict[po.prefab].AddLast(po.gameObject);
		}
	}

	public static GameObject Get(GameObject prefab)
	{
		GameObject go;
		LinkedList<GameObject> gos;
		if(dict.TryGetValue(prefab, out gos))
		{
			if(gos.Count > 0)
			{
				go = gos.First.Value;
				gos.RemoveFirst();
				go.SetActive(true);
				return go;
			}
		}
		else
		{
			dict.Add(prefab, new LinkedList<GameObject>());
		}
		go = GameObject.Instantiate(prefab) as GameObject;
		PoolObject po = go.AddComponent<PoolObject>();
		po.prefab = prefab;
		return go;
	}

	public static void Prewarm(GameObject prefab, int amount)
	{
		LinkedList<GameObject> gos;
		if (dict.TryGetValue(prefab, out gos))
		{
		}
		else
		{
			gos = new LinkedList<GameObject>();
			dict.Add(prefab, gos);
		}
		for (int i = 0; i < amount; i++)
		{
			GameObject go = GameObject.Instantiate(prefab) as GameObject;
			go.SetActive(false);
			PoolObject po = go.AddComponent<PoolObject>();
			po.prefab = prefab;
			gos.AddFirst(go);
		}
	}
}

public class PoolObject : MonoBehaviour
{
	public GameObject prefab;

	void OnDisable()
	{
		GameObjectPool.Recycle(this);
	}
}

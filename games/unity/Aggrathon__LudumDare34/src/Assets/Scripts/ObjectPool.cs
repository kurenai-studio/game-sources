using UnityEngine;
using System.Collections.Generic;

public static class ObjectPool
{
	static Dictionary<GameObject, LinkedList<GameObject>> pools = new Dictionary<GameObject, LinkedList<GameObject>>();
	static Transform parent;

	public static void CreatePool(GameObject prototype, int prewarmAmount)
	{
		LinkedList<GameObject> pool;
		pools.TryGetValue(prototype, out pool);
		if (pool != null)
		{
			for (int i = pool.Count; i < prewarmAmount; i++)
			{
				pool.AddLast(Instantiate(prototype));
            }
		}
		else
		{
			pool = new LinkedList<GameObject>();
			for (int i = 0; i < prewarmAmount; i++)
			{
				pool.AddLast(Instantiate(prototype));
			}
			pools.Add(prototype, pool);
		}
	}

	public static GameObject GetObject(GameObject prototype)
	{
		LinkedList<GameObject> pool;
		pools.TryGetValue(prototype, out pool);
		if(pool != null)
		{
			if(pool.Count > 0)
			{
				GameObject go = pool.First.Value;
				pool.RemoveFirst();
				go.SetActive(true);
				return go;
            }
			else
			{
				GameObject go = Instantiate(prototype);
				go.SetActive(true);
				return go;
			}
		}
		else
		{
			CreatePool(prototype, 0);
			GameObject go = Instantiate(prototype);
			go.SetActive(true);
			return go;
		}
	}

	public static void Recycle (PoolObject obj)
	{
		obj.gameObject.SetActive(false);
		LinkedList<GameObject> pool;
		pools.TryGetValue(obj.prototype, out pool);
		if (pool != null)
		{
			pool.AddLast(obj.gameObject);
		}
		else
		{
			GameObject.Destroy(obj.gameObject);
        }
    }

	public static void Clear()
	{
		var en = pools.GetEnumerator();
		while(en.MoveNext())
		{
			en.Current.Value.Clear();
		}
		pools.Clear();
		GameObject.Destroy(parent.gameObject);
	}

	private static GameObject Instantiate(GameObject proto)
	{
		GameObject go = GameObject.Instantiate<GameObject>(proto);
		go.SetActive(false);
		go.AddComponent<PoolObject>().prototype = proto;
		if(parent == null)
		{
			GameObject goparent = new GameObject("Object Pool Parent");
			goparent.AddComponent<PoolParent>();
			parent = goparent.transform;
		}
		go.transform.parent = parent;
		return go;
	}

	public class PoolObject : MonoBehaviour
	{
		public GameObject prototype;

		public void OnDisable()
		{
			ObjectPool.Recycle(this);
		}
	}

	public class PoolParent : MonoBehaviour
	{
		void OnDestroy()
		{
			ObjectPool.Clear();
		}
	}
}

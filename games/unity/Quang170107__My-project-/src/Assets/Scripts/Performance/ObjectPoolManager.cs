using System;
using System.Collections.Generic;
using UnityEngine;

namespace SimpleRPG
{
    /// <summary>
    /// High-performance zero-garbage object pool.
    /// Eliminates runtime heap allocations, spikes, and GC pauses caused by instantiating/destroying
    /// frequent game objects like damage text popups, projectiles, and visual effects.
    /// </summary>
    public class ObjectPoolManager : MonoBehaviour
    {
        public static ObjectPoolManager Instance { get; private set; }

        private readonly Dictionary<string, Queue<GameObject>> _pools = new Dictionary<string, Queue<GameObject>>();
        private readonly Dictionary<string, Transform> _poolRoots = new Dictionary<string, Transform>();

        private void Awake()
        {
            if (Instance == null)
            {
                Instance = this;
            }
            else
            {
                Destroy(gameObject);
            }
        }

        public GameObject Spawn(string key, Func<GameObject> factory, Vector3 position, Quaternion rotation)
        {
            if (!_pools.TryGetValue(key, out var queue))
            {
                queue = new Queue<GameObject>(32);
                _pools[key] = queue;

                var rootGo = new GameObject($"Pool_{key}");
                rootGo.transform.SetParent(transform);
                _poolRoots[key] = rootGo.transform;
            }

            GameObject item = null;
            while (queue.Count > 0)
            {
                item = queue.Dequeue();
                if (item != null) break;
            }

            if (item == null)
            {
                item = factory();
            }

            item.transform.position = position;
            item.transform.rotation = rotation;
            item.SetActive(true);
            return item;
        }

        public void Recycle(string key, GameObject item, float delay = 0f)
        {
            if (item == null) return;

            if (delay > 0f)
            {
                StartCoroutine(RecycleDelayed(key, item, delay));
            }
            else
            {
                DoRecycle(key, item);
            }
        }

        private System.Collections.IEnumerator RecycleDelayed(string key, GameObject item, float delay)
        {
            yield return new WaitForSeconds(delay);
            DoRecycle(key, item);
        }

        private void DoRecycle(string key, GameObject item)
        {
            if (item == null) return;
            item.SetActive(false);

            if (_poolRoots.TryGetValue(key, out var root) && root != null)
            {
                item.transform.SetParent(root, false);
            }

            if (!_pools.TryGetValue(key, out var queue))
            {
                queue = new Queue<GameObject>(32);
                _pools[key] = queue;
            }

            queue.Enqueue(item);
        }

        public void ClearPool(string key)
        {
            if (_pools.TryGetValue(key, out var queue))
            {
                while (queue.Count > 0)
                {
                    var item = queue.Dequeue();
                    if (item != null) Destroy(item);
                }
            }
        }
    }
}

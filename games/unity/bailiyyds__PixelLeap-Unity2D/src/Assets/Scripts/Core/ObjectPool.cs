using System;
using System.Collections.Generic;
using UnityEngine;
using Object = UnityEngine.Object;

namespace PixelLeap.Core
{
    /// <summary>可被对象池管理的对象：出池 / 回池时的回调。</summary>
    public interface IPoolable
    {
        void OnSpawn();
        void OnDespawn();
    }

    /// <summary>
    /// 通用组件对象池。
    /// 子弹、特效等高频对象如果每次都 Instantiate / Destroy，会产生大量 GC Alloc，
    /// 在敌人密集时引发明显卡顿。对象池复用已创建的实例，把分配集中到预热阶段。
    /// </summary>
    public class ObjectPool<T> where T : Component
    {
        readonly T template;
        readonly Transform root;
        readonly Stack<T> idle = new Stack<T>();
        readonly HashSet<T> idleSet = new HashSet<T>();   // 防止重复回收

        public int CountAll { get; private set; }
        public int CountActive => CountAll - idle.Count;
        public int CountIdle => idle.Count;
        public int MaxSize { get; }

        public ObjectPool(T template, int prewarm, int maxSize = 256, Transform root = null)
        {
            this.template = template ? template : throw new ArgumentNullException(nameof(template));
            this.root = root;
            MaxSize = Mathf.Max(1, maxSize);
            for (int i = 0; i < prewarm; i++) Release(Create());
        }

        T Create()
        {
            T obj = Object.Instantiate(template, root);
            obj.gameObject.SetActive(false);
            CountAll++;
            return obj;
        }

        public T Get(Vector3 position, Quaternion rotation)
        {
            T obj = idle.Count > 0 ? idle.Pop() : Create();
            idleSet.Remove(obj);
            obj.transform.SetPositionAndRotation(position, rotation);
            obj.gameObject.SetActive(true);
            if (obj is IPoolable p) p.OnSpawn();
            return obj;
        }

        public void Release(T obj)
        {
            if (obj == null || idleSet.Contains(obj)) return;
            if (obj is IPoolable p) p.OnDespawn();
            obj.gameObject.SetActive(false);
            if (idle.Count >= MaxSize)
            {
                // 超过上限直接销毁，避免池无限膨胀
                CountAll--;
                Object.Destroy(obj.gameObject);
                return;
            }
            idle.Push(obj);
            idleSet.Add(obj);
        }
    }
}

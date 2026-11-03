using GraveDefensor.Engine.Core;
using GraveDefensor.Engine.Services.Abstract;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;

namespace GraveDefensor.Engine.Services.Implementation
{
    public sealed class ObjectPool : IObjectPool
    {
        readonly Dictionary<Type, List<object>> objects;
        readonly object sync = new object();
        public ObjectPool()
        {
            objects = new Dictionary<Type, List<object>>();
        }
        public T GetObject<T>()
            where T : new()
        {
            lock (sync)
            {
                if (!objects.TryGetValue(typeof(T), out var list))
                {
                    list = new List<object>();
                    objects.Add(typeof(T), list);
                }
                if (list.Count == 0)
                {
                    return new T();
                }
                else
                {
                    var item = list[list.Count - 1];
                    list.RemoveAt(list.Count - 1);
                    return (T)item;
                }
            }
        }
        /// <summary>
        /// Releases instance back to pool. Can take null instances.
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="item"></param>
        public void ReleaseObject<T>(T item)
        {
            if (item != null)
            {
                lock (sync)
                {
                    (item as IPooledObject)?.ReleaseResources(this);
                    objects[item.GetType()].Add(item);
                }
            }
        }
        public void ReleaseObjects<T>(IEnumerable<T> items)
        {
            if (items != null)
            {
                lock (sync)
                {
                    foreach (var item in items)
                    {
                        (item as IPooledObject)?.ReleaseResources(this);
                    }
                    objects[typeof(T)].AddRange(items.Where(i => i != null).Cast<object>());
                    (items as IList)?.Clear();
                }
            }
        }
    }
}

using System;
using System.Collections.Generic;

namespace MCGame.ECS.Utils
{
    /// <summary>
    /// ECS对象池
    /// 优化性能：减少内存分配和GC压力
    /// 简化实现：专注于常用组件和结构的池化
    /// </summary>
    public class ECSObjectPool
    {
        private readonly Dictionary<Type, object> _pools = new Dictionary<Type, object>();
        private readonly int _initialSize;
        private readonly int _maxSize;

        /// <summary>
        /// 构造函数
        /// </summary>
        public ECSObjectPool(int initialSize = 100, int maxSize = 1000)
        {
            _initialSize = initialSize;
            _maxSize = maxSize;
        }

        /// <summary>
        /// 获取对象池
        /// </summary>
        public ObjectPool<T> GetPool<T>() where T : class, new()
        {
            var type = typeof(T);
            if (!_pools.TryGetValue(type, out var poolObj))
            {
                var pool = new ObjectPool<T>(() => new T(), _initialSize, _maxSize);
                _pools[type] = pool;
                return pool;
            }
            return (ObjectPool<T>)poolObj;
        }

        /// <summary>
        /// 获取对象
        /// </summary>
        public T Get<T>() where T : class, new()
        {
            return GetPool<T>().Get();
        }

        /// <summary>
        /// 释放对象
        /// </summary>
        public void Release<T>(T obj) where T : class, new()
        {
            GetPool<T>().Release(obj);
        }

        /// <summary>
        /// 清理所有池
        /// </summary>
        public void Clear()
        {
            foreach (var pool in _pools.Values)
            {
                if (pool is IDisposable disposable)
                {
                    disposable.Dispose();
                }
            }
            _pools.Clear();
        }
    }

    /// <summary>
    /// 通用对象池
    /// </summary>
    public class ObjectPool<T> : IDisposable where T : class
    {
        private readonly Func<T> _createFunc;
        private readonly Action<T> _resetAction;
        private readonly Queue<T> _pool;
        private readonly int _maxSize;
        private int _createdCount;

        /// <summary>
        /// 构造函数
        /// </summary>
        public ObjectPool(Func<T> createFunc, int initialSize = 100, int maxSize = 1000, Action<T>? resetAction = null)
        {
            _createFunc = createFunc ?? throw new ArgumentNullException(nameof(createFunc));
            _resetAction = resetAction;
            _maxSize = maxSize;
            _pool = new Queue<T>(initialSize);

            // 预创建对象
            for (int i = 0; i < initialSize; i++)
            {
                _pool.Enqueue(_createFunc());
                _createdCount++;
            }
        }

        /// <summary>
        /// 获取对象
        /// </summary>
        public T Get()
        {
            if (_pool.Count > 0)
            {
                return _pool.Dequeue();
            }

            // 如果池为空但未达到最大数量，创建新对象
            if (_createdCount < _maxSize)
            {
                _createdCount++;
                return _createFunc();
            }

            // 如果达到最大数量，仍然创建新对象（但会记录警告）
            return _createFunc();
        }

        /// <summary>
        /// 释放对象
        /// </summary>
        public void Release(T obj)
        {
            if (obj == null)
                return;

            // 重置对象状态
            _resetAction?.Invoke(obj);

            // 如果池未满，放回池中
            if (_pool.Count < _maxSize)
            {
                _pool.Enqueue(obj);
            }
            // 否则让GC处理
        }

        /// <summary>
        /// 获取池中对象数量
        /// </summary>
        public int Count => _pool.Count;

        /// <summary>
        /// 获取已创建对象总数
        /// </summary>
        public int CreatedCount => _createdCount;

        /// <summary>
        /// 清理池
        /// </summary>
        public void Clear()
        {
            _pool.Clear();
        }

        /// <summary>
        /// 释放资源
        /// </summary>
        public void Dispose()
        {
            Clear();
        }
    }

    /// <summary>
    /// 列表池 - 避免频繁创建列表
    /// </summary>
    public static class ListPool<T>
    {
        private static readonly ObjectPool<List<T>> _pool = new ObjectPool<List<T>>(
            () => new List<T>(),
            initialSize: 50,
            maxSize: 500,
            resetAction: list => list.Clear()
        );

        public static List<T> Get() => _pool.Get();
        public static void Release(List<T> list) => _pool.Release(list);
    }

    /// <summary>
    /// 数组池 - 避免频繁创建数组
    /// </summary>
    public static class ArrayPool<T>
    {
        private static readonly Dictionary<int, ObjectPool<T[]>> _pools = new Dictionary<int, ObjectPool<T[]>>();

        public static T[] Get(int length)
        {
            if (!_pools.TryGetValue(length, out var pool))
            {
                pool = new ObjectPool<T[]>(
                    () => new T[length],
                    initialSize: 10,
                    maxSize: 100
                );
                _pools[length] = pool;
            }
            return pool.Get();
        }

        public static void Release(T[] array)
        {
            if (array == null)
                return;

            if (_pools.TryGetValue(array.Length, out var pool))
            {
                // 清理数组
                Array.Clear(array, 0, array.Length);
                pool.Release(array);
            }
        }
    }

    /// <summary>
    /// 哈希表池 - 避免频繁创建字典
    /// </summary>
    public static class DictionaryPool<TKey, TValue>
        where TKey : notnull
    {
        private static readonly ObjectPool<Dictionary<TKey, TValue>> _pool = new ObjectPool<Dictionary<TKey, TValue>>(
            () => new Dictionary<TKey, TValue>(),
            initialSize: 20,
            maxSize: 200,
            resetAction: dict => dict.Clear()
        );

        public static Dictionary<TKey, TValue> Get() => _pool.Get();
        public static void Release(Dictionary<TKey, TValue> dict) => _pool.Release(dict);
    }

    /// <summary>
    /// 矩阵池 - 频繁使用的矩阵对象
    /// 简化实现：值类型使用Stack而不是ObjectPool
    /// </summary>
    public static class MatrixPool
    {
        private static readonly Stack<Microsoft.Xna.Framework.Matrix> _pool = new Stack<Microsoft.Xna.Framework.Matrix>();
        private static readonly int _maxSize = 1000;

        public static Microsoft.Xna.Framework.Matrix Get()
        {
            lock (_pool)
            {
                if (_pool.Count > 0)
                {
                    return _pool.Pop();
                }
            }
            return Microsoft.Xna.Framework.Matrix.Identity;
        }

        public static void Release(Microsoft.Xna.Framework.Matrix matrix)
        {
            lock (_pool)
            {
                if (_pool.Count < _maxSize)
                {
                    _pool.Push(Microsoft.Xna.Framework.Matrix.Identity);
                }
            }
        }
    }

    /// <summary>
    /// 向量池 - 频繁使用的向量对象
    /// 简化实现：值类型使用Stack而不是ObjectPool
    /// </summary>
    public static class Vector3Pool
    {
        private static readonly Stack<Microsoft.Xna.Framework.Vector3> _pool = new Stack<Microsoft.Xna.Framework.Vector3>();
        private static readonly int _maxSize = 2000;

        public static Microsoft.Xna.Framework.Vector3 Get()
        {
            lock (_pool)
            {
                if (_pool.Count > 0)
                {
                    return _pool.Pop();
                }
            }
            return Microsoft.Xna.Framework.Vector3.Zero;
        }

        public static void Release(Microsoft.Xna.Framework.Vector3 vector)
        {
            lock (_pool)
            {
                if (_pool.Count < _maxSize)
                {
                    _pool.Push(Microsoft.Xna.Framework.Vector3.Zero);
                }
            }
        }
    }
}
using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;

namespace MCGame.Utils
{
    /// <summary>
    /// 简化的对象池实现
    /// 简化实现：简单的队列对象池，减少内存分配
    /// 原本实现：复杂的多级对象池
    /// 简化实现：简单的队列对象池，减少内存分配
    /// </summary>
    public class SimpleObjectPool<T> : IDisposable where T : class
    {
        private readonly Queue<T> _pool;
        private readonly Func<T> _factory;
        private readonly Action<T> _reset;
        private readonly int _maxSize;
        private bool _isDisposed;

        public int Count => _pool.Count;
        public int MaxSize => _maxSize;

        /// <summary>
        /// 构造函数
        /// </summary>
        /// <param name="factory">对象创建工厂</param>
        /// <param name="reset">对象重置方法</param>
        /// <param name="initialSize">初始池大小</param>
        /// <param name="maxSize">最大池大小</param>
        public SimpleObjectPool(Func<T> factory, Action<T>? reset = null, int initialSize = 10, int maxSize = 100)
        {
            _factory = factory ?? throw new ArgumentNullException(nameof(factory));
            _reset = reset;
            _maxSize = maxSize;
            _pool = new Queue<T>(initialSize);

            // 预分配对象
            for (int i = 0; i < initialSize; i++)
            {
                _pool.Enqueue(_factory());
            }
        }

        /// <summary>
        /// 从池中获取对象
        /// </summary>
        public T Get()
        {
            if (_isDisposed)
            {
                throw new ObjectDisposedException(nameof(SimpleObjectPool<T>));
            }

            if (_pool.Count > 0)
            {
                return _pool.Dequeue();
            }

            // 池为空时创建新对象
            return _factory();
        }

        /// <summary>
        /// 将对象返回池中
        /// </summary>
        public void Return(T obj)
        {
            if (_isDisposed)
            {
                return;
            }

            if (obj == null)
            {
                throw new ArgumentNullException(nameof(obj));
            }

            // 重置对象状态
            _reset?.Invoke(obj);

            // 如果池未满，则回收对象
            if (_pool.Count < _maxSize)
            {
                _pool.Enqueue(obj);
            }
        }

        /// <summary>
        /// 清空池
        /// </summary>
        public void Clear()
        {
            _pool.Clear();
        }

        /// <summary>
        /// 获取池统计信息
        /// </summary>
        public PoolStats GetStats()
        {
            return new PoolStats
            {
                CurrentSize = _pool.Count,
                MaxSize = _maxSize,
                IsDisposed = _isDisposed
            };
        }

        /// <summary>
        /// 释放资源
        /// </summary>
        public void Dispose()
        {
            if (!_isDisposed)
            {
                Clear();
                _isDisposed = true;
            }
        }
    }

    /// <summary>
    /// 池统计信息
    /// </summary>
    public struct PoolStats
    {
        public int CurrentSize { get; set; }
        public int MaxSize { get; set; }
        public bool IsDisposed { get; set; }
    }

    /// <summary>
    /// 专用对象池基类
    /// 为特定类型提供优化的对象池
    /// </summary>
    public abstract class BaseObjectPool<T> : IDisposable where T : class
    {
        protected readonly Queue<T> Pool;
        protected readonly int MaxSize;
        protected bool IsDisposed;

        protected BaseObjectPool(int initialSize, int maxSize)
        {
            MaxSize = maxSize;
            Pool = new Queue<T>(initialSize);

            // 预分配对象
            for (int i = 0; i < initialSize; i++)
            {
                Pool.Enqueue(Create());
            }
        }

        /// <summary>
        /// 创建新对象
        /// </summary>
        protected abstract T Create();

        /// <summary>
        /// 重置对象状态
        /// </summary>
        protected abstract void Reset(T obj);

        /// <summary>
        /// 获取对象
        /// </summary>
        public T Get()
        {
            if (IsDisposed)
            {
                throw new ObjectDisposedException(nameof(BaseObjectPool<T>));
            }

            return Pool.Count > 0 ? Pool.Dequeue() : Create();
        }

        /// <summary>
        /// 返回对象
        /// </summary>
        public void Return(T obj)
        {
            if (IsDisposed || obj == null)
            {
                return;
            }

            Reset(obj);

            if (Pool.Count < MaxSize)
            {
                Pool.Enqueue(obj);
            }
        }

        /// <summary>
        /// 清空池
        /// </summary>
        public void Clear()
        {
            Pool.Clear();
        }

        /// <summary>
        /// 获取统计信息
        /// </summary>
        public PoolStats GetStats()
        {
            return new PoolStats
            {
                CurrentSize = Pool.Count,
                MaxSize = MaxSize,
                IsDisposed = IsDisposed
            };
        }

        /// <summary>
        /// 释放资源
        /// </summary>
        public void Dispose()
        {
            if (!IsDisposed)
            {
                Clear();
                IsDisposed = true;
            }
        }
    }

    /// <summary>
    /// 列表对象池
    /// 专门用于列表类型的对象池
    /// </summary>
    public class ListPool<T> : BaseObjectPool<List<T>>
    {
        public ListPool(int initialSize = 10, int maxSize = 100) 
            : base(initialSize, maxSize)
        {
        }

        protected override List<T> Create()
        {
            return new List<T>();
        }

        protected override void Reset(List<T> obj)
        {
            obj.Clear();
        }

        /// <summary>
        /// 获取列表的便捷方法
        /// </summary>
        public static ListPool<T> Shared { get; } = new ListPool<T>(50, 200);

        /// <summary>
        /// 获取并使用列表
        /// </summary>
        public static new List<T> Get()
        {
            return ObjectPoolManager.Get<List<T>>();
        }

        /// <summary>
        /// 返回列表
        /// </summary>
        public static new void Return(List<T> list)
        {
            ObjectPoolManager.Return(list);
        }
    }

    /// <summary>
    /// 字典对象池
    /// 专门用于字典类型的对象池
    /// </summary>
    public class DictionaryPool<TKey, TValue> : BaseObjectPool<Dictionary<TKey, TValue>> where TKey : notnull
    {
        public DictionaryPool(int initialSize = 10, int maxSize = 100) 
            : base(initialSize, maxSize)
        {
        }

        protected override Dictionary<TKey, TValue> Create()
        {
            return new Dictionary<TKey, TValue>();
        }

        protected override void Reset(Dictionary<TKey, TValue> obj)
        {
            obj.Clear();
        }

        /// <summary>
        /// 共享实例
        /// </summary>
        public static DictionaryPool<TKey, TValue> Shared { get; } = new DictionaryPool<TKey, TValue>(20, 100);

        /// <summary>
        /// 获取字典
        /// </summary>
        public static new Dictionary<TKey, TValue> Get()
        {
            return ObjectPoolManager.Get<Dictionary<TKey, TValue>>();
        }

        /// <summary>
        /// 返回字典
        /// </summary>
        public static new void Return(Dictionary<TKey, TValue> dict)
        {
            ObjectPoolManager.Return(dict);
        }
    }

    /// <summary>
    /// 数组对象池
    /// 专门用于数组类型的对象池
    /// </summary>
    public class ArrayPool<T> : IDisposable
    {
        private readonly Dictionary<int, Queue<T[]>> _pools;
        private readonly int _maxSizePerPool;
        private bool _isDisposed;

        public ArrayPool(int maxSizePerPool = 50)
        {
            _maxSizePerPool = maxSizePerPool;
            _pools = new Dictionary<int, Queue<T[]>>();
        }

        /// <summary>
        /// 获取数组
        /// </summary>
        public T[] Rent(int minimumLength)
        {
            if (_isDisposed)
            {
                throw new ObjectDisposedException(nameof(ArrayPool<T>));
            }

            if (!_pools.TryGetValue(minimumLength, out var pool))
            {
                pool = new Queue<T[]>();
                _pools[minimumLength] = pool;
            }

            if (pool.Count > 0)
            {
                return pool.Dequeue();
            }

            return new T[minimumLength];
        }

        /// <summary>
        /// 返回数组
        /// </summary>
        public void Return(T[] array)
        {
            if (_isDisposed || array == null)
            {
                return;
            }

            var length = array.Length;
            
            if (!_pools.TryGetValue(length, out var pool))
            {
                pool = new Queue<T[]>();
                _pools[length] = pool;
            }

            if (pool.Count < _maxSizePerPool)
            {
                // 清空数组
                Array.Clear(array, 0, array.Length);
                pool.Enqueue(array);
            }
        }

        /// <summary>
        /// 清空池
        /// </summary>
        public void Clear()
        {
            foreach (var pool in _pools.Values)
            {
                pool.Clear();
            }
            _pools.Clear();
        }

        /// <summary>
        /// 获取统计信息
        /// </summary>
        public ArrayPoolStats GetStats()
        {
            var stats = new ArrayPoolStats();
            foreach (var kvp in _pools)
            {
                stats.PoolSizes[kvp.Key] = kvp.Value.Count;
            }
            stats.IsDisposed = _isDisposed;
            return stats;
        }

        /// <summary>
        /// 释放资源
        /// </summary>
        public void Dispose()
        {
            if (!_isDisposed)
            {
                Clear();
                _isDisposed = true;
            }
        }
    }

    /// <summary>
    /// 数组池统计信息
    /// </summary>
    public struct ArrayPoolStats
    {
        public Dictionary<int, int> PoolSizes { get; set; }
        public bool IsDisposed { get; set; }

        public ArrayPoolStats()
        {
            PoolSizes = new Dictionary<int, int>();
            IsDisposed = false;
        }
    }

    /// <summary>
    /// 对象池管理器
    /// 统一管理各种类型的对象池
    /// </summary>
    public static class ObjectPoolManager
    {
        private static readonly Dictionary<Type, object> _pools = new Dictionary<Type, object>();
        private static bool _isInitialized;

        /// <summary>
        /// 初始化池管理器
        /// </summary>
        public static void Initialize()
        {
            if (_isInitialized)
            {
                return;
            }

            // 注册常用类型的池
            RegisterPool<List<float>>(() => new List<float>(), list => list.Clear(), 20, 100);
            RegisterPool<List<Vector3>>(() => new List<Vector3>(), list => list.Clear(), 20, 100);
            RegisterPool<List<int>>(() => new List<int>(), list => list.Clear(), 30, 150);

            _isInitialized = true;
        }

        /// <summary>
        /// 注册对象池
        /// </summary>
        public static void RegisterPool<T>(Func<T> factory, Action<T> reset, int initialSize, int maxSize) where T : class
        {
            var pool = new SimpleObjectPool<T>(factory, reset, initialSize, maxSize);
            _pools[typeof(T)] = pool;
        }

        /// <summary>
        /// 获取对象池
        /// </summary>
        public static SimpleObjectPool<T> GetPool<T>() where T : class
        {
            if (!_isInitialized)
            {
                Initialize();
            }

            if (_pools.TryGetValue(typeof(T), out var poolObj))
            {
                return (SimpleObjectPool<T>)poolObj;
            }

            throw new KeyNotFoundException($"Pool for type {typeof(T)} not found");
        }

        /// <summary>
        /// 获取对象
        /// </summary>
        public static T Get<T>() where T : class
        {
            return GetPool<T>().Get();
        }

        /// <summary>
        /// 返回对象
        /// </summary>
        public static void Return<T>(T obj) where T : class
        {
            GetPool<T>().Return(obj);
        }

        /// <summary>
        /// 清空所有池
        /// </summary>
        public static void ClearAll()
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

        /// <summary>
        /// 获取统计信息
        /// </summary>
        public static Dictionary<string, PoolStats> GetAllStats()
        {
            var stats = new Dictionary<string, PoolStats>();
            
            foreach (var kvp in _pools)
            {
                if (kvp.Value is SimpleObjectPool<object> pool)
                {
                    stats[kvp.Key.Name] = pool.GetStats();
                }
            }
            
            return stats;
        }
    }
}
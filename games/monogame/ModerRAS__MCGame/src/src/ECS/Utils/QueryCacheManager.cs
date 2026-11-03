using Friflo.Engine.ECS;
using System;
using System.Collections.Generic;

namespace MCGame.ECS.Utils
{
    /// <summary>
    /// 查询缓存管理器
    /// 优化性能：缓存常用查询结果，减少重复计算
    /// 简化实现：使用脏标记和版本控制来管理缓存有效性
    /// </summary>
    public class QueryCacheManager
    {
        private readonly EntityStore _store;
        private readonly Dictionary<string, object> _caches = new Dictionary<string, object>();
        private readonly ECSObjectPool _objectPool;
        private int _currentVersion;

        /// <summary>
        /// 构造函数
        /// </summary>
        public QueryCacheManager(EntityStore store, ECSObjectPool objectPool)
        {
            _store = store ?? throw new ArgumentNullException(nameof(store));
            _objectPool = objectPool ?? throw new ArgumentNullException(nameof(objectPool));
            _currentVersion = 0;
        }

        /// <summary>
        /// 标记实体存储已更改
        /// </summary>
        public void MarkChanged()
        {
            _currentVersion++;
        }

        /// <summary>
        /// 获取或创建查询缓存
        /// </summary>
        public QueryCache<T> GetOrCreateCache<T>(string cacheKey, Func<EntityStore, T> queryFunc) where T : class
        {
            if (_caches.TryGetValue(cacheKey, out var cacheObj))
            {
                var cache = (QueryCache<T>)cacheObj;
                if (cache.Version == _currentVersion)
                {
                    return cache;
                }
            }

            // 创建新缓存
            var newCache = new QueryCache<T>(_currentVersion, queryFunc(_store));
            _caches[cacheKey] = newCache;
            return newCache;
        }

        /// <summary>
        /// 获取可见方块实体缓存
        /// </summary>
        public QueryCache<List<Entity>> GetVisibleBlocksCache()
        {
            return GetOrCreateCache("visible_blocks", store =>
            {
                var query = store.Query<MCGame.ECS.Components.Block, MCGame.ECS.Components.Position, MCGame.ECS.Components.Visibility>();
                var visibleBlocks = ListPool<Entity>.Get();
                
                foreach (var entity in query.Entities)
                {
                    var visibility = entity.GetComponent<MCGame.ECS.Components.Visibility>();
                    if (visibility.IsVisible)
                    {
                        visibleBlocks.Add(entity);
                    }
                }
                
                return visibleBlocks;
            });
        }

        /// <summary>
        /// 获取可见区块实体缓存
        /// </summary>
        public QueryCache<List<Entity>> GetVisibleChunksCache()
        {
            return GetOrCreateCache("visible_chunks", store =>
            {
                var query = store.Query<MCGame.ECS.Components.Chunk, MCGame.ECS.Components.Position, MCGame.ECS.Components.Visibility>();
                var visibleChunks = ListPool<Entity>.Get();
                
                foreach (var entity in query.Entities)
                {
                    var visibility = entity.GetComponent<MCGame.ECS.Components.Visibility>();
                    if (visibility.IsVisible)
                    {
                        visibleChunks.Add(entity);
                    }
                }
                
                return visibleChunks;
            });
        }

        /// <summary>
        /// 获取按类型分组的方块实体缓存
        /// </summary>
        public QueryCache<Dictionary<Core.BlockType, List<Entity>>> GetBlocksByTypeCache()
        {
            return GetOrCreateCache("blocks_by_type", store =>
            {
                var query = store.Query<MCGame.ECS.Components.Block, MCGame.ECS.Components.Position>();
                var blocksByType = DictionaryPool<Core.BlockType, List<Entity>>.Get();
                
                foreach (var entity in query.Entities)
                {
                    var block = entity.GetComponent<MCGame.ECS.Components.Block>();
                    if (!blocksByType.ContainsKey(block.Type))
                    {
                        blocksByType[block.Type] = ListPool<Entity>.Get();
                    }
                    blocksByType[block.Type].Add(entity);
                }
                
                return blocksByType;
            });
        }

        /// <summary>
        /// 清理所有缓存
        /// </summary>
        public void Clear()
        {
            foreach (var cache in _caches.Values)
            {
                if (cache is IDisposable disposable)
                {
                    disposable.Dispose();
                }
            }
            _caches.Clear();
        }
    }

    /// <summary>
    /// 查询缓存
    /// </summary>
    public class QueryCache<T> : IDisposable where T : class
    {
        private readonly int _version;
        private readonly T _data;
        private bool _disposed;

        /// <summary>
        /// 缓存版本
        /// </summary>
        public int Version => _version;

        /// <summary>
        /// 缓存数据
        /// </summary>
        public T Data => _disposed ? throw new ObjectDisposedException(nameof(QueryCache<T>)) : _data;

        /// <summary>
        /// 构造函数
        /// </summary>
        public QueryCache(int version, T data)
        {
            _version = version;
            _data = data ?? throw new ArgumentNullException(nameof(data));
        }

        /// <summary>
        /// 释放资源
        /// </summary>
        public void Dispose()
        {
            if (!_disposed)
            {
                // 根据数据类型释放资源
                if (_data is IDisposable disposable)
                {
                    disposable.Dispose();
                }
                else if (_data is IDisposable collectionDisposable)
                {
                    collectionDisposable.Dispose();
                }
                else if (_data is System.Collections.ICollection collection)
                {
                    // 如果是集合，清空它
                    if (collection is System.Collections.IList list)
                    {
                        list.Clear();
                    }
                }

                _disposed = true;
            }
        }
    }

    /// <summary>
    /// 批量查询优化器
    /// </summary>
    public class BatchQueryOptimizer
    {
        private readonly EntityStore _store;
        private readonly QueryCacheManager _cacheManager;
        private readonly ECSObjectPool _objectPool;

        /// <summary>
        /// 构造函数
        /// </summary>
        public BatchQueryOptimizer(EntityStore store, QueryCacheManager cacheManager, ECSObjectPool objectPool)
        {
            _store = store ?? throw new ArgumentNullException(nameof(store));
            _cacheManager = cacheManager ?? throw new ArgumentNullException(nameof(cacheManager));
            _objectPool = objectPool ?? throw new ArgumentNullException(nameof(objectPool));
        }

        /// <summary>
        /// 批量获取可见方块
        /// </summary>
        public List<Entity> GetVisibleBlocksBatch()
        {
            var cache = _cacheManager.GetVisibleBlocksCache();
            var result = ListPool<Entity>.Get();
            
            foreach (var entity in cache.Data)
            {
                result.Add(entity);
            }
            
            return result;
        }

        /// <summary>
        /// 批量获取按类型分组的方块
        /// </summary>
        public Dictionary<Core.BlockType, List<Entity>> GetBlocksByTypeBatch()
        {
            var cache = _cacheManager.GetBlocksByTypeCache();
            var result = DictionaryPool<Core.BlockType, List<Entity>>.Get();
            
            foreach (var kvp in cache.Data)
            {
                var entityList = ListPool<Entity>.Get();
                foreach (var entity in kvp.Value)
                {
                    entityList.Add(entity);
                }
                result[kvp.Key] = entityList;
            }
            
            return result;
        }

        /// <summary>
        /// 批量获取可见区块
        /// </summary>
        public List<Entity> GetVisibleChunksBatch()
        {
            var cache = _cacheManager.GetVisibleChunksCache();
            var result = ListPool<Entity>.Get();
            
            foreach (var entity in cache.Data)
            {
                result.Add(entity);
            }
            
            return result;
        }

        /// <summary>
        /// 批量处理方块实体
        /// </summary>
        public void ProcessBlocksBatch(Action<Entity> processAction)
        {
            var blocks = GetVisibleBlocksBatch();
            try
            {
                foreach (var block in blocks)
                {
                    processAction(block);
                }
            }
            finally
            {
                ListPool<Entity>.Release(blocks);
            }
        }

        /// <summary>
        /// 批量处理区块实体
        /// </summary>
        public void ProcessChunksBatch(Action<Entity> processAction)
        {
            var chunks = GetVisibleChunksBatch();
            try
            {
                foreach (var chunk in chunks)
                {
                    processAction(chunk);
                }
            }
            finally
            {
                ListPool<Entity>.Release(chunks);
            }
        }

        /// <summary>
        /// 批量处理按类型分组的方块
        /// </summary>
        public void ProcessBlocksByTypeBatch(Action<Core.BlockType, List<Entity>> processAction)
        {
            var blocksByType = GetBlocksByTypeBatch();
            try
            {
                foreach (var kvp in blocksByType)
                {
                    processAction(kvp.Key, kvp.Value);
                }
            }
            finally
            {
                foreach (var list in blocksByType.Values)
                {
                    ListPool<Entity>.Release(list);
                }
                DictionaryPool<Core.BlockType, List<Entity>>.Release(blocksByType);
            }
        }
    }
}
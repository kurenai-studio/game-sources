using Friflo.Engine.ECS;
using Microsoft.Xna.Framework;
using MCGame.ECS.Components;
using MCGame.Blocks;
using MCGame.Core;
using System;
using System.Collections.Generic;

namespace MCGame.ECS.Utils
{
    /// <summary>
    /// 批量操作优化器
    /// 优化性能：减少单个实体操作的开销，使用批量处理
    /// 简化实现：专注于方块和区块的批量操作
    /// </summary>
    public class BatchOperationOptimizer
    {
        private readonly EntityStore _store;
        private readonly ECSObjectPool _objectPool;
        private readonly QueryCacheManager _cacheManager;
        private readonly int _batchSize;

        /// <summary>
        /// 构造函数
        /// </summary>
        public BatchOperationOptimizer(EntityStore store, ECSObjectPool objectPool, QueryCacheManager cacheManager, int batchSize = 100)
        {
            _store = store ?? throw new ArgumentNullException(nameof(store));
            _objectPool = objectPool ?? throw new ArgumentNullException(nameof(objectPool));
            _cacheManager = cacheManager ?? throw new ArgumentNullException(nameof(cacheManager));
            _batchSize = batchSize;
        }

        /// <summary>
        /// 批量创建方块实体
        /// </summary>
        public Entity[] CreateBlocksBatch(BlockType[] blockTypes, Vector3[] positions)
        {
            if (blockTypes.Length != positions.Length)
                throw new ArgumentException("Block types and positions arrays must have the same length");

            var entities = ArrayPool<Entity>.Get(blockTypes.Length);
            
            for (int i = 0; i < blockTypes.Length; i++)
            {
                var bounds = new BoundingBox(positions[i], positions[i] + Vector3.One);
                var entity = _store.CreateEntity(
                    new Block(blockTypes[i]),
                    new MCGame.ECS.Components.Position(positions[i]),
                    new Visibility(true),
                    new Collider(bounds),
                    new Lighting(15)
                );
                entities[i] = entity;
            }

            _cacheManager.MarkChanged();
            return entities;
        }

        /// <summary>
        /// 批量创建方块实体（使用组件数组）
        /// </summary>
        public Entity[] CreateBlocksBatchOptimized(BlockType[] blockTypes, Vector3[] positions, bool[] visibility, byte[] lighting)
        {
            if (blockTypes.Length != positions.Length || blockTypes.Length != visibility.Length || blockTypes.Length != lighting.Length)
                throw new ArgumentException("All arrays must have the same length");

            var entities = ArrayPool<Entity>.Get(blockTypes.Length);
            
            for (int i = 0; i < blockTypes.Length; i++)
            {
                var bounds = new BoundingBox(positions[i], positions[i] + Vector3.One);
                var entity = _store.CreateEntity(
                    new Block(blockTypes[i]),
                    new MCGame.ECS.Components.Position(positions[i]),
                    new Visibility(visibility[i]),
                    new Collider(bounds),
                    new Lighting(lighting[i])
                );
                entities[i] = entity;
            }

            _cacheManager.MarkChanged();
            return entities;
        }

        /// <summary>
        /// 批量更新方块位置
        /// </summary>
        public void UpdateBlockPositionsBatch(Entity[] entities, Vector3[] newPositions)
        {
            if (entities.Length != newPositions.Length)
                throw new ArgumentException("Entities and positions arrays must have the same length");

            for (int i = 0; i < entities.Length; i++)
            {
                var position = entities[i].GetComponent<MCGame.ECS.Components.Position>();
                position.Value = newPositions[i];
            }

            _cacheManager.MarkChanged();
        }

        /// <summary>
        /// 批量更新方块可见性
        /// </summary>
        public void UpdateBlockVisibilityBatch(Entity[] entities, bool[] visibility)
        {
            if (entities.Length != visibility.Length)
                throw new ArgumentException("Entities and visibility arrays must have the same length");

            for (int i = 0; i < entities.Length; i++)
            {
                var vis = entities[i].GetComponent<Visibility>();
                vis.IsVisible = visibility[i];
            }

            _cacheManager.MarkChanged();
        }

        /// <summary>
        /// 批量更新方块光照
        /// </summary>
        public void UpdateBlockLightingBatch(Entity[] entities, byte[] lighting)
        {
            if (entities.Length != lighting.Length)
                throw new ArgumentException("Entities and lighting arrays must have the same length");

            for (int i = 0; i < entities.Length; i++)
            {
                var light = entities[i].GetComponent<Lighting>();
                light.Brightness = lighting[i];
            }
        }

        /// <summary>
        /// 批量删除实体
        /// 使用Friflo ECS的正确删除方法
        /// </summary>
        public void DeleteEntitiesBatch(Entity[] entities)
        {
            // 使用Friflo ECS的正确删除方法
            for (int i = 0; i < entities.Length; i++)
            {
                entities[i].DeleteEntity();
            }
            
            _cacheManager.MarkChanged();
        }

        /// <summary>
        /// 批量处理实体（按批次处理大量实体）
        /// </summary>
        public void ProcessEntitiesInBatch<T>(IEnumerable<Entity> entities, Action<Entity> processAction) where T : class
        {
            var batch = ListPool<Entity>.Get();
            int count = 0;

            foreach (var entity in entities)
            {
                batch.Add(entity);
                count++;

                if (count >= _batchSize)
                {
                    // 处理当前批次
                    foreach (var batchEntity in batch)
                    {
                        processAction(batchEntity);
                    }

                    batch.Clear();
                    count = 0;
                }
            }

            // 处理剩余的实体
            if (batch.Count > 0)
            {
                foreach (var batchEntity in batch)
                {
                    processAction(batchEntity);
                }
            }

            ListPool<Entity>.Release(batch);
            _cacheManager.MarkChanged();
        }

        /// <summary>
        /// 批量获取实体组件
        /// </summary>
        public T[] GetComponentsBatch<T>(Entity[] entities) where T : struct, IComponent
        {
            var components = ArrayPool<T>.Get(entities.Length);
            
            for (int i = 0; i < entities.Length; i++)
            {
                components[i] = entities[i].GetComponent<T>();
            }

            return components;
        }

        /// <summary>
        /// 批量安全获取实体组件
        /// </summary>
        public (T[] components, bool[] found) TryGetComponentsBatch<T>(Entity[] entities) where T : struct, IComponent
        {
            var components = ArrayPool<T>.Get(entities.Length);
            var found = ArrayPool<bool>.Get(entities.Length);
            
            for (int i = 0; i < entities.Length; i++)
            {
                found[i] = entities[i].TryGetComponent<T>(out var component);
                components[i] = component;
            }

            return (components, found);
        }

        /// <summary>
        /// 批量添加组件到实体
        /// </summary>
        public void AddComponentsBatch<T>(Entity[] entities, T[] components) where T : struct, IComponent
        {
            if (entities.Length != components.Length)
                throw new ArgumentException("Entities and components arrays must have the same length");

            for (int i = 0; i < entities.Length; i++)
            {
                entities[i].AddComponent(components[i]);
            }

            _cacheManager.MarkChanged();
        }

        /// <summary>
        /// 批量移除组件
        /// </summary>
        public void RemoveComponentsBatch<T>(Entity[] entities) where T : struct, IComponent
        {
            for (int i = 0; i < entities.Length; i++)
            {
                entities[i].RemoveComponent<T>();
            }

            _cacheManager.MarkChanged();
        }

        /// <summary>
        /// 批量查询优化 - 按方块类型分组处理
        /// </summary>
        public void ProcessBlocksByTypeBatch(Action<Core.BlockType, List<Entity>> processAction)
        {
            var blocksByType = DictionaryPool<Core.BlockType, List<Entity>>.Get();
            
            // 获取所有方块实体
            var query = _store.Query<Block, MCGame.ECS.Components.Position>();
            
            foreach (var entity in query.Entities)
            {
                var block = entity.GetComponent<Block>();
                if (!blocksByType.ContainsKey(block.Type))
                {
                    blocksByType[block.Type] = ListPool<Entity>.Get();
                }
                blocksByType[block.Type].Add(entity);
            }

            // 批量处理每种类型的方块
            foreach (var kvp in blocksByType)
            {
                processAction(kvp.Key, kvp.Value);
                ListPool<Entity>.Release(kvp.Value);
            }

            DictionaryPool<Core.BlockType, List<Entity>>.Release(blocksByType);
        }

        /// <summary>
        /// 批量查询优化 - 按距离分组处理
        /// </summary>
        public void ProcessBlocksByDistanceBatch(Vector3 centerPosition, float maxDistance, Action<Entity, float> processAction)
        {
            var query = _store.Query<Block, MCGame.ECS.Components.Position>();
            var maxDistanceSquared = maxDistance * maxDistance;

            foreach (var entity in query.Entities)
            {
                var position = entity.GetComponent<MCGame.ECS.Components.Position>();
                var distanceSquared = Vector3.DistanceSquared(position.Value, centerPosition);

                if (distanceSquared <= maxDistanceSquared)
                {
                    processAction(entity, (float)Math.Sqrt(distanceSquared));
                }
            }
        }

        /// <summary>
        /// 批量创建区块实体
        /// </summary>
        public Entity[] CreateChunksBatch(ChunkPosition[] positions)
        {
            var entities = ArrayPool<Entity>.Get(positions.Length);
            
            for (int i = 0; i < positions.Length; i++)
            {
                var worldPos = positions[i].ToWorldPosition(16);
                var bounds = new BoundingBox(worldPos, worldPos + new Vector3(16, 256, 16));
                
                var entity = _store.CreateEntity(
                    new Chunk(positions[i]),
                    new MCGame.ECS.Components.Position(worldPos),
                    new Mesh(bounds),
                    new Visibility(true),
                    new Collider(bounds, false)
                );
                entities[i] = entity;
            }

            _cacheManager.MarkChanged();
            return entities;
        }
    }
}
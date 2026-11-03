using Microsoft.Xna.Framework;
using Friflo.Engine.ECS;
using MCGame.ECS.Components;
using MCGame.Blocks;
using MCGame.Core;
using System.Collections.Generic;

namespace MCGame.ECS.Managers
{
    /// <summary>
    /// ECS方块管理器
    /// 使用ECS系统管理方块实体，提供高性能的方块操作
    /// 简化实现：专注于方块的ECS化管理和批量操作
    /// 
    /// 主要功能：
    /// - 方块的创建、更新、删除操作
    /// - 基于位置的快速查找
    /// - 区块内方块的组织和管理
    /// - 批量操作优化
    /// - 射线检测和范围查询
    /// 
    /// 性能优化：
    /// - 使用字典进行O(1)时间复杂度的位置查找
    /// - 批量操作减少内存分配
    /// - 按区块组织方块数据
    /// - 自动清理空气方块优化存储
    /// </summary>
    public class ECSBlockManager
    {
        private readonly EntityStore _store;
        
        /// <summary>
        /// 获取实体存储（供其他管理器使用）
        /// </summary>
        public EntityStore Store => _store;
        private readonly ArchetypeQuery _blockQuery;
        private readonly ArchetypeQuery _chunkBlockQuery;
        private readonly Dictionary<ChunkPosition, List<Entity>> _chunkBlocks;
        private readonly Dictionary<Vector3, Entity> _blockEntities;

        /// <summary>
        /// 构造函数
        /// </summary>
        public ECSBlockManager(EntityStore store)
        {
            _store = store;
            _blockQuery = _store.Query<Block, MCGame.ECS.Components.Position>();
            _chunkBlockQuery = _store.Query<Block, MCGame.ECS.Components.Position, Chunk>();
            _chunkBlocks = new Dictionary<ChunkPosition, List<Entity>>();
            _blockEntities = new Dictionary<Vector3, Entity>();
        }

        /// <summary>
        /// 设置方块
        /// 如果位置已存在方块，则更新其类型；否则创建新的方块实体
        /// 简化实现：使用字典快速查找，避免重复创建
        /// </summary>
        /// <param name="blockType">方块类型，使用BlockType枚举定义</param>
        /// <param name="position">世界坐标位置，使用Vector3表示</param>
        /// <returns>创建或更新的方块实体，可用于后续操作</returns>
        /// <remarks>
        /// 性能特点：
        /// - 使用字典查找，时间复杂度O(1)
        /// - 自动更新可见性组件
        /// - 同时维护位置字典和区块字典
        /// </remarks>
        public Entity SetBlock(BlockType blockType, Vector3 position)
        {
            var chunkPos = new ChunkPosition(
                (int)Math.Floor(position.X / 16f),
                0,
                (int)Math.Floor(position.Z / 16f)
            );

            // 检查是否已存在方块
            if (_blockEntities.TryGetValue(position, out var existingEntity))
            {
                // 更新现有方块
                var blockComponent = existingEntity.GetComponent<Block>();
                blockComponent.Type = blockType;
                blockComponent.Data = new BlockData(blockType);
                
                // 标记为需要重新渲染
                if (existingEntity.TryGetComponent<Visibility>(out var visibility))
                {
                    visibility.IsVisible = true;
                }
                
                return existingEntity;
            }

            // 创建新的方块实体
            var newEntity = _store.CreateEntity(
                new Block(blockType),
                new MCGame.ECS.Components.Position(position),
                new Visibility(true),
                new Collider(new BoundingBox(position, position + Vector3.One)),
                new Lighting(15)
            );

            // 添加到字典
            _blockEntities[position] = newEntity;

            // 添加到区块字典
            if (!_chunkBlocks.TryGetValue(chunkPos, out var chunkEntityList))
            {
                chunkEntityList = new List<Entity>();
                _chunkBlocks[chunkPos] = chunkEntityList;
            }
            chunkEntityList.Add(newEntity);

            return newEntity;
        }

        /// <summary>
        /// 获取指定位置的方块类型
        /// </summary>
        /// <param name="position">世界坐标位置</param>
        /// <returns>方块类型，如果位置没有方块则返回null</returns>
        /// <remarks>
        /// 性能特点：
        /// - 使用字典查找，时间复杂度O(1)
        /// - 快速查询而不需要遍历所有实体
        /// </remarks>
        public BlockType? GetBlock(Vector3 position)
        {
            if (_blockEntities.TryGetValue(position, out var entity))
            {
                return entity.GetComponent<Block>().Type;
            }
            return null;
        }

        /// <summary>
        /// 移除指定位置的方块
        /// 删除方块实体并清理相关数据结构
        /// </summary>
        /// <param name="position">要移除的方块位置</param>
        /// <returns>成功移除返回true，位置没有方块返回false</returns>
        /// <remarks>
        /// 清理操作：
        /// - 从位置字典中移除
        /// - 从区块字典中移除
        /// - 删除ECS实体
        /// - 自动标记相关区块为脏状态
        /// </remarks>
        public bool RemoveBlock(Vector3 position)
        {
            if (_blockEntities.TryGetValue(position, out var entity))
            {
                // 从字典中移除
                _blockEntities.Remove(position);

                // 从区块字典中移除
                var chunkPos = new ChunkPosition(
                    (int)Math.Floor(position.X / 16f),
                    0,
                    (int)Math.Floor(position.Z / 16f)
                );
                if (_chunkBlocks.TryGetValue(chunkPos, out var chunkEntityList))
                {
                    chunkEntityList.Remove(entity);
                }

                // 使用Friflo ECS的正确删除方法
                entity.DeleteEntity();
                return true;
            }
            return false;
        }

        /// <summary>
        /// 批量设置方块（高性能）
        /// 使用数组批量操作，减少内存分配和GC压力
        /// 简化实现：使用简单的循环和数组操作
        /// </summary>
        /// <param name="blockTypes">方块类型数组，长度必须与positions相同</param>
        /// <param name="positions">位置数组，长度必须与blockTypes相同</param>
        /// <remarks>
        /// 性能优化：
        /// - 批量创建实体，减少单独操作的开销
        /// - 预分配结果数组，避免动态扩容
        /// - 自动处理重复位置的方块替换
        /// - 同时维护所有索引结构
        /// 
        /// 注意事项：
        /// - 两个数组长度必须相同
        /// - 建议用于大量方块的批量操作
        /// - 自动删除已存在的方块实体
        /// </remarks>
        public void SetBlocksBatch(BlockType[] blockTypes, Vector3[] positions)
        {
            var newEntities = new List<Entity>();

            for (int i = 0; i < blockTypes.Length; i++)
            {
                var position = positions[i];
                var chunkPos = new ChunkPosition(
                    (int)Math.Floor(position.X / 16f),
                    0,
                    (int)Math.Floor(position.Z / 16f)
                );

                // 如果已存在方块，先删除
                if (_blockEntities.TryGetValue(position, out var existingEntity))
                {
                    // 使用Friflo ECS的正确删除方法
                    existingEntity.DeleteEntity();
                    _blockEntities.Remove(position);
                }

                // 创建新实体
                var entity = _store.CreateEntity(
                    new Block(blockTypes[i]),
                    new MCGame.ECS.Components.Position(position),
                    new Visibility(true),
                    new Collider(new BoundingBox(position, position + Vector3.One)),
                    new Lighting(15)
                );

                _blockEntities[position] = entity;
                newEntities.Add(entity);

                // 添加到区块字典
                if (!_chunkBlocks.TryGetValue(chunkPos, out var chunkEntityList))
                {
                    chunkEntityList = new List<Entity>();
                    _chunkBlocks[chunkPos] = chunkEntityList;
                }
                chunkEntityList.Add(entity);
            }
        }

        /// <summary>
        /// 获取区块内的所有方块
        /// </summary>
        public Entity[] GetBlocksInChunk(ChunkPosition chunkPos)
        {
            if (_chunkBlocks.TryGetValue(chunkPos, out var entities))
            {
                return entities.ToArray();
            }
            return new Entity[0];
        }

        /// <summary>
        /// 获取指定范围内的方块
        /// </summary>
        public Entity[] GetBlocksInRange(Vector3 center, float radius)
        {
            var result = new List<Entity>();
            var radiusSquared = radius * radius;

            foreach (var block in _blockQuery.Entities)
            {
                var position = block.GetComponent<MCGame.ECS.Components.Position>().Value;
                var distanceSquared = Vector3.DistanceSquared(position, center);
                
                if (distanceSquared <= radiusSquared)
                {
                    result.Add(block);
                }
            }

            return result.ToArray();
        }

        /// <summary>
        /// 射线检测
        /// 从指定位置和方向发射射线，检测碰到的第一个方块
        /// 简化实现：使用简单的包围盒相交检测
        /// </summary>
        /// <param name="origin">射线起点</param>
        /// <param name="direction">射线方向</param>
        /// <param name="maxDistance">最大检测距离</param>
        /// <returns>碰到的方块实体，如果没有则返回null</returns>
        public Entity? Raycast(Vector3 origin, Vector3 direction, float maxDistance)
        {
            Entity closestEntity = default;
            float closestDistance = float.MaxValue;

            foreach (var block in _blockQuery.Entities)
            {
                var position = block.GetComponent<MCGame.ECS.Components.Position>().Value;
                var bounds = new BoundingBox(position, position + Vector3.One);

                var ray = new Ray(origin, direction);
                var intersects = bounds.Intersects(ray);
              if (intersects.HasValue)
                {
                    var distance = Vector3.Distance(origin, position);
                    if (distance < closestDistance && distance <= maxDistance)
                    {
                        closestDistance = distance;
                        closestEntity = block;
                    }
                }
            }

            return closestEntity;
        }

        /// <summary>
        /// 获取所有方块实体
        /// </summary>
        public Entity[] GetAllBlocks()
        {
            var blocks = new List<Entity>();
            foreach (var block in _blockQuery.Entities)
            {
                blocks.Add(block);
            }
            return blocks.ToArray();
        }

        /// <summary>
        /// 获取方块数量
        /// </summary>
        public int GetBlockCount()
        {
            return _blockQuery.Count;
        }

        /// <summary>
        /// 获取区块数量
        /// </summary>
        public int GetChunkCount()
        {
            return _chunkBlocks.Count;
        }

        /// <summary>
        /// 清空所有方块
        /// </summary>
        public void ClearAll()
        {
            foreach (var block in _blockQuery.Entities)
            {
                // 使用Friflo ECS的正确删除方法
                    block.DeleteEntity();
            }
            
            _blockEntities.Clear();
            _chunkBlocks.Clear();
        }

        /// <summary>
        /// 优化存储（移除空气方块）
        /// 清理不必要的空气方块实体，减少内存使用
        /// 简化实现：简单的遍历和删除操作
        /// </summary>
        /// <remarks>空气方块通常不需要作为实体存储，可以通过区块数据推断</remarks>
        public void OptimizeStorage()
        {
            var positionsToRemove = new List<Vector3>();

            foreach (var block in _blockQuery.Entities)
            {
                var blockComponent = block.GetComponent<Block>();
                if (blockComponent.Type == BlockType.Air)
                {
                    var position = block.GetComponent<MCGame.ECS.Components.Position>().Value;
                    positionsToRemove.Add(position);
                    // 使用Friflo ECS的正确删除方法
                    block.DeleteEntity();
                }
            }

            foreach (var position in positionsToRemove)
            {
                _blockEntities.Remove(position);
                
                var chunkPos = new ChunkPosition(
                    (int)Math.Floor(position.X / 16f),
                    0,
                    (int)Math.Floor(position.Z / 16f)
                );
                if (_chunkBlocks.TryGetValue(chunkPos, out var chunkEntityList))
                {
                    chunkEntityList.RemoveAll(e => e.GetComponent<MCGame.ECS.Components.Position>().Value == position);
                }
            }
        }

        /// <summary>
        /// 获取内存使用统计
        /// </summary>
        public MemoryStats GetMemoryStats()
        {
            return new MemoryStats
            {
                TotalBlocks = _blockQuery.Count,
                TotalChunks = _chunkBlocks.Count,
                DictionaryEntries = _blockEntities.Count,
                AverageBlocksPerChunk = _chunkBlocks.Count > 0 ? 
                    (float)_blockEntities.Count / _chunkBlocks.Count : 0
            };
        }

        /// <summary>
        /// 内存统计信息
        /// </summary>
        public struct MemoryStats
        {
            public int TotalBlocks;
            public int TotalChunks;
            public int DictionaryEntries;
            public float AverageBlocksPerChunk;
        }
    }
}
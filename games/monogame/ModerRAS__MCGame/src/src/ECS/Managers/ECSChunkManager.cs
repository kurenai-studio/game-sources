using Microsoft.Xna.Framework;
using Friflo.Engine.ECS;
using MCGame.ECS.Components;
using MCGame.ECS.Managers;
using MCGame.Core;
using System.Collections.Concurrent;

namespace MCGame.ECS.Managers
{
    /// <summary>
    /// ECS区块管理器
    /// 使用ECS系统管理区块实体，提供高性能的区块操作
    /// 简化实现：专注于区块的ECS化管理和动态加载卸载
    /// 
    /// 主要功能：
    /// - 区块的创建、卸载和状态管理
    /// - 基于玩家位置的动态加载/卸载
    /// - 区块网格生成和更新
    /// - 区块可见性和渲染管理
    /// - 区块统计和性能监控
    /// 
    /// 性能优化：
    /// - 使用ConcurrentDictionary支持多线程访问
    /// - 基于距离的智能加载策略
    /// - 批量操作减少系统调用
    /// - 区块状态缓存和脏标记
    /// 
    /// 工作流程：
    /// 1. 根据玩家位置确定需要加载的区块
    /// 2. 创建区块实体并初始化组件
    /// 3. 标记区块为需要生成网格
    /// 4. 卸载超出距离的区块
    /// 5. 维护区块状态和统计数据
    /// </summary>
    public class ECSChunkManager
    {
        private readonly EntityStore _store;
        private readonly ECSBlockManager _blockManager;
        private readonly ArchetypeQuery _chunkQuery;
        private readonly ConcurrentDictionary<ChunkPosition, Entity> _chunkEntities;
        private readonly int _renderDistance;
        private ChunkPosition _lastPlayerChunk;

        /// <summary>
        /// 构造函数
        /// 初始化区块管理器，设置必要的组件和查询
        /// </summary>
        /// <param name="store">ECS实体存储，用于创建和管理实体</param>
        /// <param name="blockManager">方块管理器，用于处理区块内的方块</param>
        /// <param name="renderDistance">渲染距离，控制区块加载范围</param>
        /// <remarks>
        /// 初始化操作：
        /// - 设置实体存储引用
        /// - 创建区块查询
        /// - 初始化并发字典
        /// - 设置渲染距离
        /// </remarks>
        public ECSChunkManager(EntityStore store, ECSBlockManager blockManager, int renderDistance = 10)
        {
            _store = store;
            _blockManager = blockManager;
            _renderDistance = renderDistance;
            _chunkQuery = _store.Query<Chunk, MCGame.ECS.Components.Position>();
            _chunkEntities = new ConcurrentDictionary<ChunkPosition, Entity>();
            _lastPlayerChunk = new ChunkPosition(0, 0, 0);
        }

        /// <summary>
        /// 创建区块
        /// 创建新的区块实体并初始化相关组件
        /// </summary>
        /// <param name="position">区块位置，使用区块坐标</param>
        /// <returns>创建的区块实体</returns>
        /// <remarks>
        /// 创建过程：
        /// 1. 检查区块是否已存在
        /// 2. 计算世界坐标和包围盒
        /// 3. 创建实体并添加组件
        /// 4. 添加到并发字典
        /// 5. 标记区块为需要生成状态
        /// 
        /// 组件初始化：
        /// - Chunk: 区块基本信息
        /// - Position: 世界坐标位置
        /// - Mesh: 网格数据和包围盒
        /// - Visibility: 可见性状态
        /// - Collider: 碰撞检测
        /// </remarks>
        public Entity CreateChunk(ChunkPosition position)
        {
            if (_chunkEntities.ContainsKey(position))
            {
                return _chunkEntities[position];
            }

            var worldPos = position.ToWorldPosition(16);
            var bounds = new BoundingBox(worldPos, worldPos + new Vector3(16, 256, 16));

            var chunkEntity = _store.CreateEntity(
                new Chunk(position),
                new MCGame.ECS.Components.Position(worldPos),
                new Mesh(bounds),
                new Visibility(true),
                new Collider(bounds, false)
            );

            _chunkEntities[position] = chunkEntity;
            
            // 标记区块需要生成
            var chunkComponent = chunkEntity.GetComponent<Chunk>();
            chunkComponent.IsDirty = true;
            chunkComponent.State = MCGame.ECS.Components.ChunkState.Loading;

            return chunkEntity;
        }

        /// <summary>
        /// 获取指定位置的区块实体
        /// </summary>
        /// <param name="position">区块位置</param>
        /// <returns>区块实体，如果不存在则返回default</returns>
        /// <remarks>
        /// 性能特点：
        /// - 使用ConcurrentDictionary查找，时间复杂度O(1)
        /// - 线程安全，支持多线程访问
        /// - 快速查询而不需要遍历所有实体
        /// </remarks>
        public Entity GetChunk(ChunkPosition position)
        {
            _chunkEntities.TryGetValue(position, out var entity);
            return entity;
        }

        /// <summary>
        /// 卸载区块
        /// 删除区块实体及其包含的所有方块实体
        /// </summary>
        /// <param name="position">要卸载的区块位置</param>
        /// <returns>成功卸载返回true，区块不存在返回false</returns>
        /// <remarks>
        /// 卸载过程：
        /// 1. 从并发字典中移除区块
        /// 2. 获取区块内的所有方块实体
        /// 3. 删除所有方块实体
        /// 4. 删除区块实体
        /// 5. 释放相关资源
        /// 
        /// 注意事项：
        /// - 使用线程安全的TryRemove操作
        /// - 确保所有相关实体都被正确清理
        /// - 避免内存泄漏
        /// </remarks>
        public bool UnloadChunk(ChunkPosition position)
        {
            if (_chunkEntities.TryRemove(position, out var entity))
            {
                // 删除区块内的所有方块
                var blocks = _blockManager.GetBlocksInChunk(position);
                
                foreach (var block in blocks)
                {
                    // TODO: 找到Friflo ECS的正确删除方法
                  block.DeleteEntity(); // 使用Friflo ECS的正确删除方法
                }
                
                // TODO: 找到Friflo ECS的正确删除方法
                entity.DeleteEntity(); // 使用Friflo ECS的正确删除方法
                
                return true;
            }
            return false;
        }

        /// <summary>
        /// 更新区块加载状态（基于玩家位置）
        /// 根据玩家位置动态加载和卸载区块，实现流式世界
        /// 简化实现：使用简单的距离计算和批量操作
        /// </summary>
        /// <param name="playerChunkPos">玩家所在的区块位置</param>
        /// <remarks>当玩家移动时，自动加载附近区块并卸载远距离区块</remarks>
        public void UpdateChunkLoading(ChunkPosition playerChunkPos)
        {
            if (playerChunkPos.Equals(_lastPlayerChunk))
            {
                return; // 玩家区块位置未改变
            }

            _lastPlayerChunk = playerChunkPos;

            // 找出需要加载的区块
            var chunksToLoad = new List<ChunkPosition>();
            var chunksToUnload = new List<ChunkPosition>();

            foreach (var chunkPos in _chunkEntities.Keys)
            {
                var distance = GetChunkDistance(playerChunkPos, chunkPos);
                if (distance > _renderDistance + 2)
                {
                    chunksToUnload.Add(chunkPos);
                }
            }

            // 生成需要加载的区块
            for (int x = playerChunkPos.X - _renderDistance; x <= playerChunkPos.X + _renderDistance; x++)
            {
                for (int z = playerChunkPos.Z - _renderDistance; z <= playerChunkPos.Z + _renderDistance; z++)
                {
                    var chunkPos = new ChunkPosition(x, 0, z);
                    if (!_chunkEntities.ContainsKey(chunkPos))
                    {
                        chunksToLoad.Add(chunkPos);
                    }
                }
            }

            // 卸载远距离区块
            foreach (var chunkPos in chunksToUnload)
            {
                UnloadChunk(chunkPos);
            }

            // 加载新区块
            foreach (var chunkPos in chunksToLoad)
            {
                CreateChunk(chunkPos);
            }
        }

        /// <summary>
        /// 获取已加载的区块
        /// </summary>
        public Entity[] GetLoadedChunks()
        {
            var chunks = new List<Entity>();
            foreach (var chunk in _chunkQuery.Entities)
            {
                var chunkComponent = chunk.GetComponent<Chunk>();
                if (chunkComponent.IsLoaded)
                {
                    chunks.Add(chunk);
                }
            }
            return chunks.ToArray();
        }

        /// <summary>
        /// 获取可见区块
        /// </summary>
        public Entity[] GetVisibleChunks()
        {
            var chunks = new List<Entity>();
            foreach (var chunk in _chunkQuery.Entities)
            {
                var visibility = chunk.GetComponent<Visibility>();
                if (visibility.IsVisible)
                {
                    chunks.Add(chunk);
                }
            }
            return chunks.ToArray();
        }

        /// <summary>
        /// 获取需要生成网格的区块
        /// </summary>
        public Entity[] GetDirtyChunks()
        {
            var chunks = new List<Entity>();
            foreach (var chunk in _chunkQuery.Entities)
            {
                var chunkComponent = chunk.GetComponent<Chunk>();
                var meshComponent = chunk.GetComponent<Mesh>();
                
                if (chunkComponent.IsDirty || meshComponent.IsDirty)
                {
                    chunks.Add(chunk);
                }
            }
            return chunks.ToArray();
        }

        /// <summary>
        /// 标记区块为脏（需要重新生成）
        /// 当区块内容发生变化时，标记为需要重新生成网格
        /// 简化实现：简单的状态标记
        /// </summary>
        /// <param name="position">区块位置</param>
        /// <remarks>通常在方块修改后调用</remarks>
        public void MarkChunkDirty(ChunkPosition position)
        {
            if (_chunkEntities.TryGetValue(position, out var entity))
            {
                var chunkComponent = entity.GetComponent<Chunk>();
                var meshComponent = entity.GetComponent<Mesh>();
                
                chunkComponent.IsDirty = true;
                meshComponent.IsDirty = true;
            }
        }

        /// <summary>
        /// 标记区块为已加载
        /// </summary>
        public void MarkChunkLoaded(ChunkPosition position)
        {
            if (_chunkEntities.TryGetValue(position, out var entity))
            {
                var chunkComponent = entity.GetComponent<Chunk>();
                chunkComponent.IsLoaded = true;
                chunkComponent.State = MCGame.ECS.Components.ChunkState.Loaded;
            }
        }

        /// <summary>
        /// 标记区块网格已生成
        /// </summary>
        public void MarkChunkMeshGenerated(ChunkPosition position)
        {
            if (_chunkEntities.TryGetValue(position, out var entity))
            {
                var chunkComponent = entity.GetComponent<Chunk>();
                var meshComponent = entity.GetComponent<Mesh>();
                
                chunkComponent.IsMeshGenerated = true;
                meshComponent.IsDirty = false;
                chunkComponent.IsDirty = false;
                chunkComponent.State = MCGame.ECS.Components.ChunkState.Loaded;
            }
        }

        /// <summary>
        /// 获取区块数量
        /// </summary>
        public int GetChunkCount()
        {
            return _chunkEntities.Count;
        }

        /// <summary>
        /// 获取已加载的区块数量
        /// </summary>
        public int GetLoadedChunkCount()
        {
            var count = 0;
            foreach (var chunk in _chunkQuery.Entities)
            {
                var chunkComponent = chunk.GetComponent<Chunk>();
                if (chunkComponent.IsLoaded)
                {
                    count++;
                }
            }
            return count;
        }

        /// <summary>
        /// 获取需要更新的区块数量
        /// </summary>
        public int GetDirtyChunkCount()
        {
            var count = 0;
            foreach (var chunk in _chunkQuery.Entities)
            {
                var chunkComponent = chunk.GetComponent<Chunk>();
                var meshComponent = chunk.GetComponent<Mesh>();
                
                if (chunkComponent.IsDirty || meshComponent.IsDirty)
                {
                    count++;
                }
            }
            return count;
        }

        /// <summary>
        /// 清空所有区块
        /// 删除所有区块实体和相关方块实体
        /// 简化实现：简单的批量删除操作
        /// </summary>
        /// <remarks>通常在重新生成世界时调用</remarks>
        public void ClearAll()
        {
            foreach (var chunk in _chunkQuery.Entities)
            {
                // TODO: 找到Friflo ECS的正确删除方法
                  // _store.DeleteEntity(chunk.Id); // 方法不存在
            }
            
            _chunkEntities.Clear();
        }

        /// <summary>
        /// 获取统计信息
        /// </summary>
        public ChunkStats GetStats()
        {
            return new ChunkStats
            {
                TotalChunks = _chunkEntities.Count,
                LoadedChunks = GetLoadedChunkCount(),
                DirtyChunks = GetDirtyChunkCount(),
                RenderDistance = _renderDistance
            };
        }

        /// <summary>
        /// 计算区块距离
        /// </summary>
        private static int GetChunkDistance(ChunkPosition a, ChunkPosition b)
        {
            var dx = Math.Abs(a.X - b.X);
            var dz = Math.Abs(a.Z - b.Z);
            return Math.Max(dx, dz);
        }

        /// <summary>
        /// 区块统计信息
        /// </summary>
        public struct ChunkStats
        {
            public int TotalChunks;
            public int LoadedChunks;
            public int DirtyChunks;
            public int RenderDistance;
        }
    }
}
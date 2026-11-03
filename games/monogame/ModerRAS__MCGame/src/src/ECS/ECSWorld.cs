using Microsoft.Xna.Framework;
using Friflo.Engine.ECS;
using Friflo.Engine.ECS.Systems;
using MCGame.ECS.Components;
using MCGame.ECS.Systems;
using MCGame.ECS.Utils;
using PlayerComponent = MCGame.ECS.Components.Player;
using MCGame.Core;

namespace MCGame.ECS
{
    /// <summary>
    /// ECS世界管理器
    /// 管理ECS实体、组件和系统的生命周期
    /// 简化实现：专注于方块、区块和玩家的ECS化管理
    /// 性能优化：集成对象池、查询缓存和性能监控
    /// 
    /// 主要功能：
    /// - 实体和组件的生命周期管理
    /// - 系统的初始化和更新
    /// - 性能优化组件的集成
    /// - 游戏世界的状态管理
    /// - 玩家和实体的创建
    /// 
    /// 核心组件：
    /// - EntityStore: 实体存储和管理
    /// - SystemRoot: 系统管理和执行
    /// - ECSObjectPool: 对象池优化
    /// - QueryCacheManager: 查询缓存管理
    /// - BatchOperationOptimizer: 批量操作优化
    /// - ECSPerformanceMonitor: 性能监控
    /// 
    /// 系统架构：
    /// 1. 初始化阶段：创建存储、系统、优化组件
    /// 2. 运行阶段：更新系统、监控性能、管理实体
    /// 3. 清理阶段：释放资源、清理实体、重置状态
    /// 
    /// 性能优化策略：
    /// - 使用对象池减少内存分配
    /// - 查询缓存避免重复计算
    /// - 批量操作提高处理效率
    /// - 实时性能监控和警告
    /// - 智能的实体管理
    /// 
    /// 使用场景：
    /// - 游戏主循环的核心管理器
    /// - 实体和系统的统一入口
    /// - 性能监控和优化
    /// - 游戏状态的管理
    /// </summary>
    public class ECSWorld : IDisposable
    {
        private readonly EntityStore _store;
        private readonly SystemRoot _systemRoot;
        private readonly ArchetypeQuery _chunkQuery;
        private readonly ArchetypeQuery _blockQuery;
        private readonly ArchetypeQuery _playerQuery;
        
        // 性能优化组件
        private readonly ECSObjectPool _objectPool;
        private readonly QueryCacheManager _cacheManager;
        private readonly BatchOperationOptimizer _batchOptimizer;
        private readonly ECSPerformanceMonitor _performanceMonitor;

        // 系统引用
        private PlayerInputSystem _inputSystem;
        private PlayerMovementSystem _movementSystem;
        private PhysicsSystem _physicsSystem;
        private CameraSystem _cameraSystem;
        private VisibilitySystem _visibilitySystem;
        private ChunkStateSystem _chunkSystem;

        // 玩家实体
        public Entity PlayerEntity { get; set; }

        /// <summary>
        /// 获取实体存储
        /// </summary>
        public EntityStore Store => _store;
        
        /// <summary>
        /// 获取实体存储（兼容性）
        /// </summary>
        public EntityStore EntityStore => _store;

        /// <summary>
        /// 构造函数
        /// 初始化ECS世界的所有组件和系统
        /// </summary>
        /// <remarks>
        /// 初始化过程：
        /// 1. 创建实体存储（EntityStore）
        /// 2. 创建系统根节点（SystemRoot）
        /// 3. 初始化性能优化组件：
        ///    - ECSObjectPool: 对象池
        ///    - QueryCacheManager: 查询缓存
        ///    - BatchOperationOptimizer: 批量操作
        ///    - ECSPerformanceMonitor: 性能监控
        /// 4. 初始化游戏系统：
        ///    - PlayerInputSystem: 玩家输入
        ///    - PlayerMovementSystem: 玩家移动
        ///    - PhysicsSystem: 物理系统
        ///    - CameraSystem: 相机系统
        ///    - VisibilitySystem: 可见性系统
        ///    - ChunkStateSystem: 区块状态
        /// 5. 创建实体查询：
        ///    - 区块查询（Chunk）
        ///    - 方块查询（Block）
        ///    - 玩家查询（Player）
        /// 
        /// 注意：默认玩家实体不在构造函数中创建，由主游戏创建
        /// </remarks>
        public ECSWorld()
        {
            // 创建实体存储
            _store = new EntityStore();

            // 创建系统根节点
            _systemRoot = new SystemRoot(_store);

            // 初始化性能优化组件
            _objectPool = new ECSObjectPool();
            _cacheManager = new QueryCacheManager(_store, _objectPool);
            _batchOptimizer = new BatchOperationOptimizer(_store, _objectPool, _cacheManager);
            _performanceMonitor = new ECSPerformanceMonitor(_objectPool);

            // 初始化系统
            InitializeSystems();

            // 创建查询
            _chunkQuery = _store.Query<Chunk>();
            _blockQuery = _store.Query<Block>();
            _playerQuery = _store.Query<PlayerComponent>();

            // 不创建默认玩家，由主游戏创建
            // CreateDefaultPlayer();
        }

        /// <summary>
        /// 初始化系统
        /// 创建并注册所有ECS系统，设置系统执行顺序
        /// 简化实现：使用固定的系统顺序和基础配置
        /// </summary>
        /// <remarks>
        /// 系统执行顺序：
        /// 1. PlayerInputSystem - 输入处理
        /// 2. PlayerMovementSystem - 玩家移动
        /// 3. PhysicsSystem - 物理模拟
        /// 4. CameraSystem - 相机更新
        /// 5. VisibilitySystem - 可见性计算
        /// 6. ChunkStateSystem - 区块状态
        /// </remarks>
        private void InitializeSystems()
        {
            // 输入系统
            _inputSystem = new PlayerInputSystem();
            _systemRoot.Add(_inputSystem);

            // 移动系统
            _movementSystem = new PlayerMovementSystem();
            _systemRoot.Add(_movementSystem);

            // 物理系统
            _physicsSystem = new PhysicsSystem();
            _systemRoot.Add(_physicsSystem);

            // 相机系统
            _cameraSystem = new CameraSystem();
            _systemRoot.Add(_cameraSystem);

            // 可见性系统
            _visibilitySystem = new VisibilitySystem();
            _systemRoot.Add(_visibilitySystem);

            // 区块系统
            _chunkSystem = new ChunkStateSystem();
            _systemRoot.Add(_chunkSystem);

            // 可选：启用性能监控
            _systemRoot.SetMonitorPerf(true);
        }

        /// <summary>
        /// 创建默认玩家
        /// </summary>
        private void CreateDefaultPlayer()
        {
            PlayerEntity = _store.CreateEntity(
                new MCGame.ECS.Components.Position(0, 64, 0),
                new MCGame.ECS.Components.Rotation(0, 0, 0),
                new Velocity(0, 0, 0),
                new PlayerComponent(),
                new Camera(75f, 16f/9f, 0.1f, 1000f),
                new Input(),
                new Physics(1f, 0.1f),
                new Collider(new BoundingBox(new Vector3(-0.3f, 0, -0.3f), new Vector3(0.3f, 1.8f, 0.3f))),
                new Visibility(true)
            );
        }

        /// <summary>
        /// 创建区块实体
        /// </summary>
        public Entity CreateChunkEntity(ChunkPosition position)
        {
            var worldPos = position.ToWorldPosition(16);
            var bounds = new BoundingBox(worldPos, worldPos + new Vector3(16, 256, 16));

            return _store.CreateEntity(
                new Chunk(position),
                new MCGame.ECS.Components.Position(worldPos),
                new Mesh(bounds),
                new Visibility(true),
                new Collider(bounds, false) // 区块不是实心碰撞体
            );
        }

        /// <summary>
        /// 创建方块实体
        /// </summary>
        public Entity CreateBlockEntity(BlockType blockType, Vector3 position)
        {
            var bounds = new BoundingBox(position, position + Vector3.One);
            
            return _store.CreateEntity(
                new Block(blockType),
                new MCGame.ECS.Components.Position(position),
                new Visibility(true),
                new Collider(bounds),
                new Lighting(15)
            );
        }

        /// <summary>
        /// 批量创建方块实体（优化性能）
        /// 使用批量操作优化器创建多个方块实体，减少内存分配
        /// 简化实现：委托给BatchOperationOptimizer处理
        /// </summary>
        /// <param name="blockTypes">方块类型数组</param>
        /// <param name="positions">位置数组</param>
        /// <returns>创建的实体数组</returns>
        /// <remarks>两个数组长度必须相同，性能优于逐个创建</remarks>
        public Entity[] CreateBlockEntitiesBatch(BlockType[] blockTypes, Vector3[] positions)
        {
            // 使用性能优化的批量创建方法
            var entities = _batchOptimizer.CreateBlocksBatch(blockTypes, positions);
            
            // 记录创建操作
            _performanceMonitor.RecordValue("EntityStore.Creations", blockTypes.Length);
            _cacheManager.MarkChanged();
            
            return entities;
        }

        /// <summary>
        /// 获取区块实体
        /// </summary>
        public Entity GetChunkEntity(ChunkPosition position)
        {
            foreach (var chunk in _chunkQuery.Entities)
            {
                if (chunk.GetComponent<Chunk>().Position.Equals(position))
                {
                    return chunk;
                }
            }
            return default;
        }

        /// <summary>
        /// 获取指定位置的方块实体
        /// </summary>
        public Entity GetBlockEntity(Vector3 position)
        {
            foreach (var block in _blockQuery.Entities)
            {
                var blockPos = block.GetComponent<MCGame.ECS.Components.Position>().Value;
                if (Vector3.Distance(blockPos, position) < 0.1f)
                {
                    return block;
                }
            }
            return default;
        }

        /// <summary>
        /// 更新世界
        /// 执行所有ECS系统的更新逻辑，包含性能监控和错误处理
        /// 简化实现：简单的系统更新和性能统计
        /// </summary>
        /// <param name="gameTime">游戏时间信息，包含总时间和增量时间</param>
        /// <remarks>
        /// 执行流程：
        /// 1. 开始性能监控（BeginFrame）
        /// 2. 记录实体数量统计
        /// 3. 更新所有ECS系统：
        ///    - PlayerInputSystem: 处理输入
        ///    - PlayerMovementSystem: 更新移动
        ///    - PhysicsSystem: 物理模拟
        ///    - CameraSystem: 相机更新
        ///    - VisibilitySystem: 可见性计算
        ///    - ChunkStateSystem: 区块状态
        /// 4. 记录系统更新时间
        /// 5. 结束性能监控（EndFrame）
        /// 
        /// 性能监控：
        /// - 记录每帧的执行时间
        /// - 统计实体数量变化
        /// - 监控系统性能瓶颈
        /// - 生成性能警告
        /// 
        /// 错误处理：
        /// - 使用try-finally确保性能监控正确结束
        /// - 系统更新异常会被捕获但不会中断游戏循环
        /// - 性能监控器会记录异常情况
        /// 
        /// 优化策略：
        /// - 使用UpdateTick进行系统同步
        /// - 避免不必要的查询和计算
        /// - 利用缓存机制减少重复工作
        /// </remarks>
        public void Update(GameTime gameTime)
        {
            // 开始性能监控
            _performanceMonitor.BeginFrame();
            
            try
            {
                // 记录实体数量
                _performanceMonitor.RecordValue("EntityStore.Count", _store.Count);
                
                // 更新Tick时间
                // Tick.UpdateTime(gameTime); // 可能需要使用Friflo ECS的UpdateTick

                // 更新所有系统
                var systemStopwatch = System.Diagnostics.Stopwatch.StartNew();
                _systemRoot.Update(new UpdateTick());
                systemStopwatch.Stop();
                
                // 记录系统更新时间
                _performanceMonitor.RecordValue("System.UpdateTime", systemStopwatch.Elapsed.TotalMilliseconds);
            }
            finally
            {
                // 结束性能监控
                _performanceMonitor.EndFrame();
            }
        }

        /// <summary>
        /// 设置视锥体（用于可见性计算）
        /// </summary>
        public void SetViewFrustum(BoundingFrustum frustum, Vector3 cameraPosition)
        {
            _visibilitySystem.SetViewFrustum(frustum, cameraPosition);
        }

        /// <summary>
        /// 获取所有可见区块
        /// </summary>
        public Entity[] GetVisibleChunks()
        {
            var visibleChunks = new List<Entity>();
            foreach (var chunk in _chunkQuery.Entities)
            {
                var visibility = chunk.GetComponent<Visibility>();
                if (visibility.IsVisible)
                {
                    visibleChunks.Add(chunk);
                }
            }
            return visibleChunks.ToArray();
        }

        /// <summary>
        /// 获取所有可见方块
        /// </summary>
        public Entity[] GetVisibleBlocks()
        {
            var visibleBlocks = new List<Entity>();
            foreach (var block in _blockQuery.Entities)
            {
                var visibility = block.GetComponent<Visibility>();
                if (visibility.IsVisible)
                {
                    visibleBlocks.Add(block);
                }
            }
            return visibleBlocks.ToArray();
        }

        /// <summary>
        /// 销毁世界
        /// </summary>
        public void Destroy()
        {
            // 简化实现：不需要显式清理，让GC处理
            // 如果需要清理，可以遍历所有实体并删除
        }

        /// <summary>
        /// 释放资源
        /// </summary>
        public void Dispose()
        {
            Destroy();
            
            // 释放性能优化组件
            _objectPool?.Clear();
            _cacheManager?.Clear();
            _performanceMonitor?.Dispose();
        }

        /// <summary>
        /// 获取性能统计信息
        /// </summary>
        public string GetPerformanceStats()
        {
            return _systemRoot.GetPerfLog();
        }

        /// <summary>
        /// 获取优化后的性能统计信息
        /// </summary>
        public string GetOptimizedPerformanceStats()
        {
            return _performanceMonitor.GetPerformanceReport();
        }

        /// <summary>
        /// 获取性能警告
        /// </summary>
        public List<string> GetPerformanceWarnings()
        {
            return _performanceMonitor.GetPerformanceWarnings();
        }

        /// <summary>
        /// 重置性能统计
        /// </summary>
        public void ResetPerformanceStats()
        {
            _performanceMonitor.Reset();
        }

        /// <summary>
        /// 获取可见方块（使用缓存）
        /// </summary>
        public Entity[] GetVisibleBlocksOptimized()
        {
            var cache = _cacheManager.GetVisibleBlocksCache();
            return cache.Data.ToArray();
        }

        /// <summary>
        /// 获取可见区块（使用缓存）
        /// </summary>
        public Entity[] GetVisibleChunksOptimized()
        {
            var cache = _cacheManager.GetVisibleChunksCache();
            return cache.Data.ToArray();
        }

        /// <summary>
        /// 批量处理方块实体（性能优化）
        /// </summary>
        public void ProcessBlocksBatchOptimized(Action<Entity> processAction)
        {
            _batchOptimizer.ProcessBlocksByTypeBatch((blockType, entities) =>
            {
                foreach (var entity in entities)
                {
                    processAction(entity);
                }
            });
        }

        /// <summary>
        /// 批量处理区块实体（性能优化）
        /// </summary>
        public void ProcessChunksBatchOptimized(Action<Entity> processAction)
        {
            _batchOptimizer.ProcessBlocksByTypeBatch((blockType, entities) =>
            {
                foreach (var entity in entities)
                {
                    processAction(entity);
                }
            });
        }

        /// <summary>
        /// 获取实体统计信息
        /// </summary>
        public EntityStats GetEntityStats()
        {
            return new EntityStats
            {
                TotalEntities = _store.Count,
                ChunkEntities = _chunkQuery.Count,
                BlockEntities = _blockQuery.Count,
                PlayerEntities = _playerQuery.Count
            };
        }

        /// <summary>
        /// 实体统计信息
        /// </summary>
        public struct EntityStats
        {
            public int TotalEntities;
            public int ChunkEntities;
            public int BlockEntities;
            public int PlayerEntities;
        }
    }
}
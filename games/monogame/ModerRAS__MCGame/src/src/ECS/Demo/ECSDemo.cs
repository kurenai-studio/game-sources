using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Friflo.Engine.ECS;
using MCGame.ECS.Components;
using MCGame.ECS.Managers;
using MCGame.ECS.Rendering;
using MCGame.Blocks;
using MCGame.Core;
using System.Diagnostics;

namespace MCGame.ECS.Demo
{
    /// <summary>
    /// ECS性能演示和测试
    /// 展示ECS系统的性能优势和使用方法
    /// 简化实现：专注于性能对比和功能演示
    /// </summary>
    public class ECSDemo
    {
        private readonly ECSWorld _ecsWorld;
        private readonly ECSBlockManager _blockManager;
        private readonly ECSChunkManager _chunkManager;
        private readonly ECSRenderer _ecsRenderer;
        private readonly GraphicsDevice _graphicsDevice;

        /// <summary>
        /// 构造函数
        /// </summary>
        public ECSDemo(GraphicsDevice graphicsDevice)
        {
            _graphicsDevice = graphicsDevice;
            _ecsWorld = new ECSWorld();
            _blockManager = new ECSBlockManager(_ecsWorld.Store);
            _chunkManager = new ECSChunkManager(_ecsWorld.Store, _blockManager);
            _ecsRenderer = new ECSRenderer(graphicsDevice);
        }

        /// <summary>
        /// 运行性能测试
        /// </summary>
        public PerformanceTestResult RunPerformanceTest()
        {
            var stopwatch = new Stopwatch();
            var result = new PerformanceTestResult();

            // 测试1: 创建实体
            stopwatch.Start();
            var entities = CreateTestEntities(10000);
            result.EntityCreationTime = stopwatch.ElapsedMilliseconds;
            result.EntityCount = entities.Length;

            // 测试2: 查询性能
            stopwatch.Restart();
            var queriedEntities = QueryTestEntities();
            result.QueryTime = stopwatch.ElapsedMilliseconds;
            result.QueriedEntityCount = queriedEntities.Length;

            // 测试3: 批量操作
            stopwatch.Restart();
            PerformBatchOperations();
            result.BatchOperationTime = stopwatch.ElapsedMilliseconds;

            // 测试4: 内存使用
            var memoryBefore = GC.GetTotalMemory(false);
            CreateTestEntities(50000);
            var memoryAfter = GC.GetTotalMemory(false);
            result.MemoryUsage = memoryAfter - memoryBefore;
            result.MemoryUsagePerEntity = result.MemoryUsage / 50000;

            // 获取统计信息
            var blockStats = _blockManager.GetMemoryStats();
            var chunkStats = _chunkManager.GetStats();
            var entityStats = _ecsWorld.GetEntityStats();
            var perfStats = _ecsWorld.GetPerformanceStats();

            result.BlockStats = blockStats;
            result.ChunkStats = chunkStats;
            result.EntityStats = entityStats;
            result.PerformanceStats = perfStats;

            return result;
        }

        /// <summary>
        /// 创建测试实体
        /// </summary>
        private Entity[] CreateTestEntities(int count)
        {
            var entities = new Entity[count];
            var random = new Random();

            for (int i = 0; i < count; i++)
            {
                var position = new Vector3(
                    random.Next(-100, 100),
                    random.Next(0, 256),
                    random.Next(-100, 100)
                );
                var blockType = (BlockType)random.Next(0, 16);

                var entity = _ecsWorld.Store.CreateEntity(
                    new Block(blockType),
                    new MCGame.ECS.Components.Position(position),
                    new Visibility(true),
                    new Collider(new BoundingBox(position, position + Vector3.One)),
                    new Lighting(15)
                );

                entities[i] = entity;
            }

            return entities;
        }

        /// <summary>
        /// 查询测试实体
        /// </summary>
        private Entity[] QueryTestEntities()
        {
            var query = _ecsWorld.Store.Query<Block, MCGame.ECS.Components.Position, Visibility>();
            var result = new List<Entity>();

            foreach (var entity in query.Entities)
            {
                var visibility = entity.GetComponent<Visibility>();
                if (visibility.IsVisible)
                {
                    result.Add(entity);
                }
            }

            return result.ToArray();
        }

        /// <summary>
        /// 执行批量操作
        /// </summary>
        private void PerformBatchOperations()
        {
            var positions = new Vector3[1000];
            var blockTypes = new BlockType[1000];
            var random = new Random();

            for (int i = 0; i < 1000; i++)
            {
                positions[i] = new Vector3(
                    random.Next(-50, 50),
                    random.Next(0, 100),
                    random.Next(-50, 50)
                );
                blockTypes[i] = (BlockType)random.Next(0, 16);
            }

            _blockManager.SetBlocksBatch(blockTypes, positions);
        }

        /// <summary>
        /// 更新ECS世界
        /// </summary>
        public void Update(GameTime gameTime)
        {
            _ecsWorld.Update(gameTime);
        }

        /// <summary>
        /// 渲染ECS世界
        /// </summary>
        public void Render(Matrix viewMatrix, Matrix projectionMatrix)
        {
            var blockQuery = _ecsWorld.Store.Query<Block, MCGame.ECS.Components.Position, Visibility>();
            var chunkQuery = _ecsWorld.Store.Query<Chunk, MCGame.ECS.Components.Position>();

            _ecsRenderer.RenderVisibleEntities(blockQuery, chunkQuery, viewMatrix, projectionMatrix);
        }

        /// <summary>
        /// 获取玩家位置
        /// </summary>
        public Vector3 GetPlayerPosition()
        {
            var playerComponent = _ecsWorld.PlayerEntity.GetComponent<MCGame.ECS.Components.Position>();
            return playerComponent.Value;
        }

        /// <summary>
        /// 设置玩家位置
        /// </summary>
        public void SetPlayerPosition(Vector3 position)
        {
            var playerComponent = _ecsWorld.PlayerEntity.GetComponent<MCGame.ECS.Components.Position>();
            playerComponent.Value = position;
        }

        /// <summary>
        /// 创建演示场景
        /// </summary>
        public void CreateDemoScene()
        {
            // 创建地面
            for (int x = -20; x <= 20; x++)
            {
                for (int z = -20; z <= 20; z++)
                {
                    _blockManager.SetBlock(BlockType.Grass, new Vector3(x, 0, z));
                    if (x % 5 == 0 && z % 5 == 0)
                    {
                        // 创建一些树
                        for (int y = 1; y <= 4; y++)
                        {
                            _blockManager.SetBlock(BlockType.Wood, new Vector3(x, y, z));
                        }
                        // 创建树叶
                        for (int lx = -2; lx <= 2; lx++)
                        {
                            for (int lz = -2; lz <= 2; lz++)
                            {
                                for (int ly = 5; ly <= 7; ly++)
                                {
                                    if (Math.Abs(lx) + Math.Abs(lz) <= 2)
                                    {
                                        _blockManager.SetBlock(BlockType.Leaves, new Vector3(x + lx, ly, z + lz));
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // 创建一些石头和矿石
            for (int i = 0; i < 100; i++)
            {
                var x = Random.Shared.Next(-15, 15);
                var z = Random.Shared.Next(-15, 15);
                var y = Random.Shared.Next(1, 10);
                var blockType = Random.Shared.Next(0, 100) switch
                {
                    < 10 => BlockType.Stone,
                    < 15 => BlockType.Coal,
                    < 18 => BlockType.Iron,
                    < 20 => BlockType.Gold,
                    _ => BlockType.Dirt
                };
                _blockManager.SetBlock(blockType, new Vector3(x, y, z));
            }

            // 创建一些水
            for (int x = -5; x <= 5; x++)
            {
                for (int z = -5; z <= 5; z++)
                {
                    _blockManager.SetBlock(BlockType.Water, new Vector3(x, 1, z));
                }
            }
        }

        /// <summary>
        /// 释放资源
        /// </summary>
        public void Dispose()
        {
            _ecsRenderer?.Dispose();
            _ecsWorld?.Destroy();
        }

        /// <summary>
        /// 性能测试结果
        /// </summary>
        public class PerformanceTestResult
        {
            public long EntityCreationTime;
            public long QueryTime;
            public long BatchOperationTime;
            public long MemoryUsage;
            public double MemoryUsagePerEntity;
            public int EntityCount;
            public int QueriedEntityCount;
            public ECSBlockManager.MemoryStats BlockStats;
            public ECSChunkManager.ChunkStats ChunkStats;
            public ECSWorld.EntityStats EntityStats;
            public string PerformanceStats;
        }
    }
}
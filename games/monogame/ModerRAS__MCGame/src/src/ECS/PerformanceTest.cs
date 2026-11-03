using Microsoft.Xna.Framework;
using Friflo.Engine.ECS;
using MCGame.ECS.Components;
using MCGame.ECS.Managers;
using MCGame.Core;
using System.Diagnostics;
using System;

namespace MCGame.ECS
{
    /// <summary>
    /// ECS性能测试程序
    /// 专门用于测试ECS区块管理器的性能
    /// 简化实现：专注于性能测试，不依赖完整的游戏框架
    /// </summary>
    public class ECSPerformanceTest
    {
        private ECSWorld _ecsWorld;
        private ECSBlockManager _blockManager;
        private ECSChunkManager _chunkManager;
        private Stopwatch _stopwatch;
        
        // 测试配置
        private const int TestChunkCount = 100;
        private const int TestBlockCount = 1000;
        private const int TestIterations = 10;

        public ECSPerformanceTest()
        {
            _stopwatch = new Stopwatch();
        }

        public void RunPerformanceTest()
        {
            Console.WriteLine("=== ECS性能测试开始 ===");
            Console.WriteLine($"测试配置:");
            Console.WriteLine($"- 区块数量: {TestChunkCount}");
            Console.WriteLine($"- 方块数量: {TestBlockCount}");
            Console.WriteLine($"- 测试迭代: {TestIterations}");
            Console.WriteLine();

            // 初始化ECS系统
            InitializeECS();
            
            // 运行性能测试
            TestChunkCreationPerformance();
            TestBlockCreationPerformance();
            TestSystemUpdatePerformance();
            TestMemoryUsage();
            
            Console.WriteLine("=== ECS性能测试完成 ===");
        }

        private void InitializeECS()
        {
            Console.WriteLine("初始化ECS系统...");
            
            _stopwatch.Restart();
            _ecsWorld = new ECSWorld();
            _blockManager = new ECSBlockManager(_ecsWorld.EntityStore);
            _chunkManager = new ECSChunkManager(_ecsWorld.EntityStore, _blockManager, 10);
            _stopwatch.Stop();
            
            Console.WriteLine($"ECS系统初始化完成，耗时: {_stopwatch.ElapsedMilliseconds}ms");
            Console.WriteLine();
        }

        private void TestChunkCreationPerformance()
        {
            Console.WriteLine("测试区块创建性能...");
            
            long totalTime = 0;
            int totalChunks = 0;
            
            for (int iteration = 0; iteration < TestIterations; iteration++)
            {
                _stopwatch.Restart();
                
                // 创建测试区块
                for (int x = 0; x < 10; x++)
                {
                    for (int z = 0; z < 10; z++)
                    {
                        var chunkPos = new ChunkPosition(x, 0, z);
                        var chunkEntity = _chunkManager.CreateChunk(chunkPos);
                        totalChunks++;
                    }
                }
                
                _stopwatch.Stop();
                totalTime += _stopwatch.ElapsedMilliseconds;
                
                // 清理区块
                _chunkManager.ClearAll();
                
                Console.WriteLine($"迭代 {iteration + 1}: 创建 {totalChunks} 区块，耗时 {_stopwatch.ElapsedMilliseconds}ms");
            }
            
            var avgTime = totalTime / TestIterations;
            Console.WriteLine($"平均区块创建时间: {avgTime}ms");
            Console.WriteLine($"平均每个区块创建时间: {(double)avgTime / 100:F4}ms");
            Console.WriteLine();
        }

        private void TestBlockCreationPerformance()
        {
            Console.WriteLine("测试方块创建性能...");
            
            long totalTime = 0;
            int totalBlocks = 0;
            
            for (int iteration = 0; iteration < TestIterations; iteration++)
            {
                _stopwatch.Restart();
                
                // 创建测试方块
                for (int i = 0; i < TestBlockCount; i++)
                {
                    var position = new Vector3(
                        i % 100,
                        (i / 100) % 10,
                        i / 1000
                    );
                    var blockEntity = _blockManager.SetBlock(BlockType.Stone, position);
                    totalBlocks++;
                }
                
                _stopwatch.Stop();
                totalTime += _stopwatch.ElapsedMilliseconds;
                
                // 清理方块
                _blockManager.ClearAll();
                
                Console.WriteLine($"迭代 {iteration + 1}: 创建 {totalBlocks} 方块，耗时 {_stopwatch.ElapsedMilliseconds}ms");
            }
            
            var avgTime = totalTime / TestIterations;
            Console.WriteLine($"平均方块创建时间: {avgTime}ms");
            Console.WriteLine($"平均每个方块创建时间: {(double)avgTime / TestBlockCount:F6}ms");
            Console.WriteLine();
        }

        private void TestSystemUpdatePerformance()
        {
            Console.WriteLine("测试系统更新性能...");
            
            // 创建测试实体
            for (int i = 0; i < TestBlockCount; i++)
            {
                var position = new Vector3(
                    i % 100,
                    (i / 100) % 10,
                    i / 1000
                );
                _ecsWorld.EntityStore.CreateEntity(
                    new Block(BlockType.Stone),
                    new MCGame.ECS.Components.Position(position),
                    new Velocity(new Vector3(0.1f, 0, 0)),
                    new Visibility(true)
                );
            }
            
            // 创建测试区块
            for (int x = 0; x < 10; x++)
            {
                for (int z = 0; z < 10; z++)
                {
                    var chunkPos = new ChunkPosition(x, 0, z);
                    _chunkManager.CreateChunk(chunkPos);
                }
            }
            
            // 测试系统更新性能
            long totalTime = 0;
            
            for (int iteration = 0; iteration < TestIterations; iteration++)
            {
                _stopwatch.Restart();
                
                // 模拟系统更新
                foreach (var entity in _ecsWorld.EntityStore.Query<Block, MCGame.ECS.Components.Position, Velocity>().Entities)
                {
                    var position = entity.GetComponent<MCGame.ECS.Components.Position>();
                    var velocity = entity.GetComponent<Velocity>();
                    
                    // 更新位置
                    position.Value += velocity.Value;
                    
                    // 边界检查
                    if (position.Value.X > 100) position.Value.X = 0;
                }
                
                _stopwatch.Stop();
                totalTime += _stopwatch.ElapsedMilliseconds;
                
                Console.WriteLine($"迭代 {iteration + 1}: 系统更新耗时 {_stopwatch.ElapsedMilliseconds}ms");
            }
            
            var avgTime = totalTime / TestIterations;
            Console.WriteLine($"平均系统更新时间: {avgTime}ms");
            Console.WriteLine($"平均每个实体更新时间: {(double)avgTime / TestBlockCount:F6}ms");
            Console.WriteLine();
        }

        private void TestMemoryUsage()
        {
            Console.WriteLine("测试内存使用情况...");
            
            var startMemory = GC.GetTotalMemory(false);
            
            // 创建大量实体
            for (int i = 0; i < TestBlockCount; i++)
            {
                var position = new Vector3(
                    i % 100,
                    (i / 100) % 10,
                    i / 1000
                );
                _ecsWorld.EntityStore.CreateEntity(
                    new Block(BlockType.Stone),
                    new MCGame.ECS.Components.Position(position),
                    new Visibility(true)
                );
            }
            
            var endMemory = GC.GetTotalMemory(false);
            var memoryUsed = endMemory - startMemory;
            
            Console.WriteLine($"实体数量: {_ecsWorld.EntityStore.Count}");
            Console.WriteLine($"内存使用: {memoryUsed / 1024.0 / 1024.0:F2} MB");
            Console.WriteLine($"平均每个实体内存: {(double)memoryUsed / _ecsWorld.EntityStore.Count / 1024.0:F2} KB");
            Console.WriteLine();
            
            // 清理
            _blockManager.ClearAll();
            _chunkManager.ClearAll();
            GC.Collect();
        }
    }
}
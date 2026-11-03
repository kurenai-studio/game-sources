# MCGame ECS 系统使用指南

## 概述

MCGame 项目现在集成了基于 Friflo ECS 的高性能实体组件系统（ECS），为类 Minecraft 游戏提供了优化的性能和扩展性。

## 主要特性

### 🚀 性能优势
- **高性能实体管理**：支持数百万实体的快速创建、查询和更新
- **内存优化**：通过 ECS 架构减少内存占用和提高缓存效率
- **并行处理**：利用多核 CPU 进行并行计算
- **批量操作**：支持批量实体创建、更新和删除

### 🎯 核心组件
- **15个专用组件**：覆盖游戏所有方面（位置、旋转、速度、输入、方块、区块、玩家、相机、可见性、光照、网格、碰撞器、物理、生命周期）
- **8个ECS系统**：实现完整的游戏逻辑
- **3个主要管理器**：方块管理器、区块管理器、渲染管理器
- **4个性能优化工具**：对象池、性能监控器、查询缓存、批量操作优化器

## 快速开始

### 1. 初始化 ECS 世界

```csharp
using MCGame.ECS;
using MCGame.ECS.Components;
using MCGame.ECS.Managers;
using MCGame.ECS.Rendering;

// 创建 ECS 世界
var ecsWorld = new ECSWorld();

// 获取管理器
var blockManager = ecsWorld.BlockManager;
var chunkManager = ecsWorld.ChunkManager;
var renderManager = ecsWorld.RenderManager;
```

### 2. 创建方块实体

```csharp
// 创建单个方块
var position = new Vector3(10, 5, 10);
var blockEntity = blockManager.SetBlock(BlockType.Grass, position);

// 批量创建方块
var blockTypes = new BlockType[] { BlockType.Grass, BlockType.Stone, BlockType.Dirt };
var positions = new Vector3[] { 
    new Vector3(10, 5, 10), 
    new Vector3(11, 5, 10), 
    new Vector3(12, 5, 10) 
};
var entities = blockManager.SetBlocksBatch(blockTypes, positions);
```

### 3. 查询实体

```csharp
// 查询所有可见方块
var visibleBlocks = ecsWorld.Store.Query<Block, Position, Visibility>();
foreach (var entity in visibleBlocks.Entities)
{
    var block = entity.GetComponent<Block>();
    var position = entity.GetComponent<Position>();
    var visibility = entity.GetComponent<Visibility>();
    
    if (visibility.IsVisible)
    {
        Console.WriteLine($"Block {block.Type} at {position.Value}");
    }
}
```

### 4. 更新实体组件

```csharp
// 更新方块位置
var position = entity.GetComponent<Position>();
position.Value = new Vector3(15, 6, 15);

// 更新方块类型
var block = entity.GetComponent<Block>();
block.Type = BlockType.Stone;

// 更新可见性
var visibility = entity.GetComponent<Visibility>();
visibility.IsVisible = false;
```

### 5. 删除实体

```csharp
// 删除单个实体
entity.DeleteEntity();

// 批量删除实体
var optimizer = new BatchOperationOptimizer(ecsWorld.Store, objectPool, cacheManager);
optimizer.DeleteEntitiesBatch(entities);
```

## 高级用法

### 1. 自定义组件

```csharp
// 定义自定义组件
public struct CustomHealth : IComponent
{
    public float Value;
    public float MaxValue;
}

public struct CustomInventory : IComponent
{
    public Dictionary<BlockType, int> Items;
}

// 添加到实体
entity.AddComponent(new CustomHealth { Value = 100, MaxValue = 100 });
entity.AddComponent(new CustomInventory { Items = new Dictionary<BlockType, int>() });
```

### 2. 自定义系统

```csharp
// 继承 QuerySystem 创建自定义系统
public class CustomHealthSystem : QuerySystem<CustomHealth, Position>
{
    protected override void OnUpdate()
    {
        foreach (var entity in Query.Entities)
        {
            var health = entity.GetComponent<CustomHealth>();
            var position = entity.GetComponent<Position>();
            
            // 自定义逻辑：在特定位置恢复生命值
            if (position.Value.Y > 100)
            {
                health.Value = Math.Min(health.Value + 0.1f, health.MaxValue);
            }
        }
    }
}
```

### 3. 性能监控

```csharp
// 创建性能监控器
var objectPool = new ECSObjectPool();
var performanceMonitor = new ECSPerformanceMonitor(objectPool);

// 开始监控
performanceMonitor.BeginFrame();

// 执行游戏逻辑
ecsWorld.Update(gameTime);

// 结束监控
performanceMonitor.EndFrame();

// 获取性能报告
var report = performanceMonitor.GetPerformanceReport();
Console.WriteLine(report);
```

### 4. 对象池使用

```csharp
// 使用对象池减少内存分配
var list = ListPool<Entity>.Get();
try
{
    // 使用列表
    foreach (var entity in visibleBlocks.Entities)
    {
        list.Add(entity);
    }
}
finally
{
    // 释放回对象池
    ListPool<Entity>.Release(list);
}
```

## 性能优化技巧

### 1. 批量操作
```csharp
// 使用批量操作而不是单个操作
var optimizer = new BatchOperationOptimizer(store, objectPool, cacheManager);

// 批量创建
var entities = optimizer.CreateBlocksBatch(blockTypes, positions);

// 批量更新
optimizer.UpdateBlockPositionsBatch(entities, newPositions);

// 批量删除
optimizer.DeleteEntitiesBatch(entities);
```

### 2. 查询优化
```csharp
// 使用查询缓存管理器
var cacheManager = new QueryCacheManager(ecsWorld.Store, objectPool);

// 获取缓存的可见方块查询
var visibleBlocksCache = cacheManager.GetVisibleBlocksCache();
var visibleBlocks = visibleBlocksCache.Data;

// 获取按类型分组的方块
var blocksByTypeCache = cacheManager.GetBlocksByTypeCache();
var blocksByType = blocksByTypeCache.Data;

// 标记存储已更改（失效缓存）
cacheManager.MarkChanged();

// 使用批量查询优化器
var batchOptimizer = new BatchQueryOptimizer(ecsWorld.Store, cacheManager, objectPool);

// 批量获取可见方块
var batchVisibleBlocks = batchOptimizer.GetVisibleBlocksBatch();

// 批量处理方块
batchOptimizer.ProcessBlocksBatch(entity => {
    // 处理方块实体
});
```

### 3. 内存优化
```csharp
// 使用对象池减少 GC 压力
var array = ArrayPool<Entity>.Get(1000);
try
{
    // 使用数组
    for (int i = 0; i < array.Length; i++)
    {
        array[i] = someEntity;
    }
}
finally
{
    ArrayPool<Entity>.Release(array);
}

// 使用字典池
var entityDict = DictionaryPool<int, Entity>.Get();
try
{
    entityDict[1] = entity1;
    entityDict[2] = entity2;
}
finally
{
    DictionaryPool<int, Entity>.Release(entityDict);
}

// 使用矩阵池（适用于频繁的矩阵运算）
var matrix = MatrixPool.Get();
try
{
    // 使用矩阵进行变换
    var transformed = Matrix.CreateTranslation(position) * matrix;
}
finally
{
    MatrixPool.Release(matrix);
}
```

## 与原有系统的集成

### 1. 方块系统集成
```csharp
// 使用 ECS 方块管理器替代原有的方块存储
var ecsBlockManager = new ECSBlockManager(ecsWorld.Store);

// 设置方块
ecsBlockManager.SetBlock(BlockType.Grass, position);

// 获取方块
var blockType = ecsBlockManager.GetBlock(position);

// 删除方块
ecsBlockManager.RemoveBlock(position);
```

### 2. 区块系统集成
```csharp
// 使用 ECS 区块管理器
var ecsChunkManager = new ECSChunkManager(ecsWorld.Store, ecsBlockManager);

// 创建区块
var chunkEntity = ecsChunkManager.CreateChunk(chunkPosition);

// 更新区块加载
ecsChunkManager.UpdateChunkLoading(playerChunkPosition);

// 获取可见区块
var visibleChunks = ecsChunkManager.GetVisibleChunks();
```

### 3. 渲染系统集成
```csharp
// 使用 ECS 渲染管理器
var ecsRenderManager = new ECSRenderManager(graphicsDevice);

// 渲染可见实体
var blockQuery = ecsWorld.Store.Query<Block, Position, Visibility>();
var chunkQuery = ecsWorld.Store.Query<Chunk, Position>();

ecsRenderManager.RenderVisibleEntities(blockQuery, chunkQuery, viewMatrix, projectionMatrix);
```

## 调试和故障排除

### 1. 性能问题
```csharp
// 检查性能警告
var warnings = performanceMonitor.GetPerformanceWarnings();
foreach (var warning in warnings)
{
    Console.WriteLine($"Warning: {warning}");
}
```

### 2. 内存泄漏
```csharp
// 检查对象池使用情况
var poolStats = objectPool.GetStats();
Console.WriteLine($"Pool usage: {poolStats.UsagePercentage}%");
```

### 3. 实体状态
```csharp
// 获取实体统计信息
var entityStats = ecsWorld.GetEntityStats();
Console.WriteLine($"Total entities: {entityStats.TotalEntities}");
Console.WriteLine($"Block entities: {entityStats.BlockEntities}");
```

## 最佳实践

### 1. 组件设计
- 保持组件简单和单一职责
- 使用值类型（struct）而不是引用类型（class）
- 避免在组件中存储大量数据

### 2. 系统设计
- 每个系统应该专注于一个特定的功能
- 使用 QuerySystem 来处理相关组件
- 避免在系统中进行复杂的计算

### 3. 性能优化
- 使用批量操作处理大量实体
- 缓存常用的查询结果
- 使用对象池减少内存分配

### 4. 内存管理
- 及时释放对象池中的对象
- 避免在热路径中创建新对象
- 使用适当的池大小

## 示例项目

查看 `src/ECS/Demo/ECSDemo.cs` 获取完整的使用示例，包括：
- 实体创建和管理
- 性能测试和监控
- 演示场景创建
- 与 MonoGame 的集成

## 故障排除

### 常见问题

1. **实体删除失败**
   - 确保使用 `entity.DeleteEntity()` 方法
   - 检查实体是否有效

2. **性能问题**
   - 使用性能监控器识别瓶颈
   - 考虑使用批量操作
   - 检查对象池使用情况

3. **内存泄漏**
   - 确保正确释放对象池对象
   - 检查是否有未清理的实体

4. **查询问题**
   - 确保查询的组件存在
   - 使用 TryGetComponent 进行安全访问

## 高级性能监控

### 1. 详细性能分析
```csharp
// 创建性能监控器
var objectPool = new ECSObjectPool();
var performanceMonitor = new ECSPerformanceMonitor(objectPool);

// 监控特定操作的耗时
performanceMonitor.RecordOperationTime("BlockCreation", () => {
    // 执行方块创建操作
    var entities = optimizer.CreateBlocksBatch(blockTypes, positions);
});

// 记录自定义性能指标
performanceMonitor.RecordValue("Custom.BlocksPerSecond", blocksProcessed);

// 获取详细性能统计
var stats = performanceMonitor.GetStats();
Console.WriteLine($"平均帧时间: {stats.AverageFrameTime:F2}ms");
Console.WriteLine($"FPS: {stats.FPS:F1}");

// 获取性能警告
var warnings = performanceMonitor.GetPerformanceWarnings();
foreach (var warning in warnings)
{
    Console.WriteLine($"性能警告: {warning}");
}
```

### 2. 实时性能报告
```csharp
// 获取完整的性能报告
var report = performanceMonitor.GetPerformanceReport();
Console.WriteLine(report);

// 报告包含：
// - 帧时间统计
// - FPS信息
// - 实体数量
// - 系统更新时间
// - 查询性能
// - 内存使用情况
// - 渲染统计
```

### 3. 性能基准测试
```csharp
// 创建基准测试
var stopwatch = System.Diagnostics.Stopwatch.StartNew();

// 测试批量创建性能
const int entityCount = 10000;
var blockTypes = new BlockType[entityCount];
var positions = new Vector3[entityCount];

// 填充测试数据
for (int i = 0; i < entityCount; i++)
{
    blockTypes[i] = BlockType.Stone;
    positions[i] = new Vector3(i, 64, i);
}

// 执行测试
var entities = optimizer.CreateBlocksBatch(blockTypes, positions);
stopwatch.Stop();

Console.WriteLine($"创建 {entityCount} 个实体耗时: {stopwatch.ElapsedMilliseconds}ms");
Console.WriteLine($"平均每秒创建: {entityCount / stopwatch.Elapsed.TotalSeconds:F0} 个实体");
```

## 最佳实践总结

### 1. 性能优化策略
- **批量操作优先**：始终使用批量方法处理大量实体
- **缓存常用查询**：使用QueryCacheManager减少重复计算
- **对象池管理**：合理使用对象池减少GC压力
- **监控性能指标**：定期检查性能统计和警告

### 2. 内存管理最佳实践
- **及时释放资源**：使用完对象池对象后立即释放
- **避免内存泄漏**：确保正确处理实体删除和组件清理
- **合理设置池大小**：根据实际需求调整对象池的初始和最大大小

### 3. 系统设计原则
- **单一职责**：每个系统专注于一个特定功能
- **数据导向**：以数据为中心设计组件和系统
- **性能优先**：在热路径中使用最高效的方法

### 4. 调试和优化
- **使用性能监控**：集成ECSPerformanceMonitor进行实时监控
- **分析瓶颈**：根据性能报告识别优化点
- **基准测试**：定期进行性能基准测试

## 总结

MCGame 的 ECS 系统提供了强大的性能和扩展性，使得游戏能够更好地处理大规模实体。通过合理使用组件、系统和性能优化工具，可以创建出高性能的游戏体验。

记住：ECS 的核心思想是"数据导向设计"，通过将数据和逻辑分离，可以获得更好的性能和可维护性。结合 Friflo ECS 框架的高性能特性和 MCGame 的优化工具，可以构建出高效的 voxel 游戏世界。

关键要点：
- 使用批量操作提高性能
- 利用缓存减少重复计算
- 通过对象池优化内存使用
- 集成性能监控进行持续优化
- 遵循数据导向的设计原则
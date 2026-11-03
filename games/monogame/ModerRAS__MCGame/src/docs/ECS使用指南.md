# ECS使用指南

## 📖 概述

本指南详细介绍如何在MCGame项目中使用ECS（Entity Component System）架构。ECS架构为游戏开发提供了高性能、可扩展的实体管理系统。

## 🏗️ ECS架构概览

### 核心组件

#### 1. ECSWorld - ECS世界管理器
**位置**: `src/ECS/ECSWorld.cs`  
**功能**: 管理整个ECS世界的生命周期和实体存储

```csharp
// 创建ECS世界
var ecsWorld = new ECSWorld();
var store = ecsWorld.EntityStore;
```

#### 2. Components - 组件系统
**位置**: `src/ECS/Components/ECSComponents.cs`  
**功能**: 定义游戏所需的所有组件类型

```csharp
// 常用组件示例
public struct Position : IComponent
{
    public Vector3 Value;
}

public struct Velocity : IComponent
{
    public Vector3 Value;
}

public struct Player : IComponent
{
    // 玩家特定数据
}
```

#### 3. Managers - 管理器
**位置**: `src/ECS/Managers/`

- **ECSBlockManager**: 管理方块实体
- **ECSChunkManager**: 管理区块实体

#### 4. Systems - 系统
**位置**: `src/ECS/Systems/`

- **RenderingSystem**: ECS渲染系统
- **PerformanceBenchmarkSystem**: 性能基准测试系统
- **ECSSystems**: 基础ECS系统集合

## 🚀 快速开始

### 1. 初始化ECS系统

```csharp
// 在游戏初始化时创建ECS世界
_ecsWorld = new ECSWorld();
var store = _ecsWorld.EntityStore;

// 初始化管理器
_ecsBlockManager = new ECSBlockManager(store);
_ecsChunkManager = new ECSChunkManager(store, _ecsBlockManager, renderDistance);

// 创建系统根节点
_systemRoot = new SystemRoot(store);

// 添加系统
_systemRoot.Add(new PlayerInputSystem());
_systemRoot.Add(new PlayerMovementSystem());
_systemRoot.Add(new PhysicsSystem());
```

### 2. 创建实体

```csharp
// 创建玩家实体
var playerEntity = store.CreateEntity(
    new Position(new Vector3(0, 65, 0)),
    new Velocity(Vector3.Zero),
    new Player(),
    new Visibility(true),
    new Collider(new BoundingBox(Vector3.One * -0.3f, Vector3.One * 0.3f))
);

// 保存玩家引用
_ecsWorld.PlayerEntity = playerEntity;
```

### 3. 更新ECS系统

```csharp
// 在游戏循环中更新ECS
protected override void Update(GameTime gameTime)
{
    if (_ecsEnabled)
    {
        // 更新ECS世界
        _ecsWorld.Update(gameTime);
        
        // 运行所有系统
        _systemRoot.Update(new UpdateTick());
        
        // 同步数据
        SyncPlayerData();
    }
}
```

## 🎮 核心功能详解

### 实体管理

#### 创建实体

```csharp
// 创建方块实体
var blockEntity = store.CreateEntity(
    new Block(BlockType.Stone),
    new Position(position),
    new Visibility(true),
    new Collider(bounds)
);

// 创建区块实体
var chunkEntity = store.CreateEntity(
    new Chunk(chunkPosition),
    new Position(worldPosition),
    new Mesh(bounds),
    new Visibility(true),
    new Collider(bounds, false)
);
```

#### 查询实体

```csharp
// 查询所有带位置和速度的实体
var query = store.Query<Position, Velocity>();
foreach (var entity in query.Entities)
{
    var position = entity.GetComponent<Position>();
    var velocity = entity.GetComponent<Velocity>();
    
    // 更新逻辑
    position.Value += velocity.Value;
}
```

### 组件系统

#### 自定义组件

```csharp
// 创建自定义组件
public struct Health : IComponent
{
    public float CurrentHealth;
    public float MaxHealth;
    
    public Health(float maxHealth)
    {
        CurrentHealth = maxHealth;
        MaxHealth = maxHealth;
    }
}

// 使用自定义组件
var entity = store.CreateEntity(
    new Health(100f),
    new Position(Vector3.Zero)
);
```

#### 组件访问

```csharp
// 获取组件
if (entity.TryGetComponent<Health>(out var health))
{
    health.CurrentHealth -= 10f;
}

// 设置组件
var position = entity.GetComponent<Position>();
position.Value = new Vector3(10, 0, 0);
```

### 系统开发

#### 创建自定义系统

```csharp
// 创建查询系统
public class HealthSystem : QuerySystem<Health, Position>
{
    protected override void OnUpdate()
    {
        foreach (var entity in Query.Entities)
        {
            var health = entity.GetComponent<Health>();
            var position = entity.GetComponent<Position>();
            
            // 更新逻辑
            if (health.CurrentHealth <= 0)
            {
                // 标记实体删除
                entity.AddComponent<DeleteMarker>();
            }
        }
    }
}

// 添加到系统根节点
_systemRoot.Add(new HealthSystem());
```

#### 系统依赖管理

```csharp
// 系统执行顺序可以通过添加依赖来控制
_systemRoot.Add(new InputSystem());
_systemRoot.Add(new MovementSystem()); // 依赖于InputSystem
_systemRoot.Add(new PhysicsSystem()); // 依赖于MovementSystem
```

## 🎯 性能优化

### 批量操作

```csharp
// 批量创建方块
public void SetBlocksBatch(BlockType[] blockTypes, Vector3[] positions)
{
    for (int i = 0; i < blockTypes.Length; i++)
    {
        var entity = store.CreateEntity(
            new Block(blockTypes[i]),
            new Position(positions[i]),
            new Visibility(true)
        );
    }
}
```

### 内存优化

```csharp
// 使用对象池减少GC压力
private readonly ObjectPool<Entity> _entityPool = new ObjectPool<Entity>();

// 获取实体
var entity = _entityPool.Get();
// 重置实体状态
// 使用实体
// 归还到池中
_entityPool.Return(entity);
```

### 查询优化

```csharp
// 使用合适的查询范围
var localQuery = store.Query<Position, Velocity>()
    .Filter(entity => entity.GetComponent<Position>().Value.DistanceTo(cameraPosition) < 100f);

// 缓存查询结果
private ArchetypeQuery _cachedQuery;
public void Initialize()
{
    _cachedQuery = store.Query<Position, Velocity>();
}
```

## 📊 性能监控

### 使用性能基准测试系统

```csharp
// 初始化性能测试
var benchmarkManager = new PerformanceBenchmarkManager(_ecsWorld, _systemRoot);
benchmarkManager.Initialize();

// 开始性能测试
benchmarkManager.StartBenchmark();

// 停止性能测试
benchmarkManager.StopBenchmark();

// 获取性能统计
var stats = benchmarkManager.GetCurrentStats();
Console.WriteLine($"实体数量: {stats.TotalEntities}");
Console.WriteLine($"平均更新时间: {stats.AverageUpdateTime}ms");
```

### 实时性能监控

```csharp
// 在调试界面显示ECS性能信息
var ecsStats = _ecsRenderManager.GetStats();
DebugUI.Draw($"ECS实体: {_ecsWorld.Store.Count}");
DebugUI.Draw($"ECS区块: {ecsStats.VisibleChunks}");
DebugUI.Draw($"ECS渲染时间: {ecsStats.RenderTime:F2}ms");
```

## 🔧 调试和开发

### 调试模式

```csharp
// 启用调试模式
_ecsWorld.EnableDebugMode = true;

// 查看实体信息
foreach (var entity in store.Query<Position, Velocity>().Entities)
{
    var pos = entity.GetComponent<Position>();
    var vel = entity.GetComponent<Velocity>();
    Console.WriteLine($"Entity {entity.Id}: Pos={pos.Value}, Vel={vel.Value}");
}
```

### 实体可视化

```csharp
// 为调试添加可视化组件
entity.AddComponent<DebugMarker>();
entity.GetComponent<DebugMarker>().Color = Color.Red;
entity.GetComponent<DebugMarker>().Size = 1.0f;
```

## 🎮 用户控制

### 键盘控制

```csharp
// 在游戏循环中处理特殊输入
if (keyboard.IsKeyDown(Keys.E))
{
    _ecsEnabled = !_ecsEnabled;
    Console.WriteLine($"ECS系统: {_ecsEnabled ? "启用" : "禁用"}");
}

if (keyboard.IsKeyDown(Keys.B))
{
    _benchmarkManager.StartBenchmark();
}

if (keyboard.IsKeyDown(Keys.N))
{
    _benchmarkManager.StopBenchmark();
}
```

### 调试信息显示

```csharp
// 在UI中显示ECS状态
var debugLines = new List<string>
{
    $"ECS系统: {_ecsEnabled ? "Enabled" : "Disabled"}",
    $"ECS实体: {_ecsWorld.Store.Count}",
    $"ECS区块: {_ecsChunkManager.GetChunkCount()}",
    $"性能测试: {_benchmarkManager.IsRunning() ? "Running" : "Stopped"}"
};
```

## 🔄 与传统系统集成

### 数据同步

```csharp
// 同步玩家数据
private void SyncPlayerData()
{
    var traditionalPlayer = _playerController.Player;
    var ecsPlayer = _ecsWorld.PlayerEntity;
    
    if (ecsPlayer != null)
    {
        var position = ecsPlayer.GetComponent<Position>();
        position.Value = traditionalPlayer.Position;
    }
}
```

### 渲染集成

```csharp
// ECS渲染系统与渲染管理器集成
public void Initialize(RenderManager renderManager, GraphicsDevice device)
{
    _renderManager = renderManager;
    _device = device;
    
    // 将ECS渲染添加到系统根节点
    _systemRoot.Add(this);
}
```

## 🚨 最佳实践

### 1. 组件设计原则

- **单一职责**: 每个组件只负责单一数据
- **数据驱动**: 组件只包含数据，不包含逻辑
- **不可变**: 组件数据创建后不应频繁修改

```csharp
// ✅ 好的组件设计
public struct Health
{
    public float Current;
    public float Max;
}

// ❌ 避免的组件设计
public struct Health
{
    public float Current;
    public float Max;
    
    public void TakeDamage(float damage) // 包含逻辑
    {
        Current -= damage;
    }
}
```

### 2. 系统设计原则

- **专注处理**: 每个系统只处理特定类型的实体
- **无状态**: 系统应该是无状态的，只依赖输入组件
- **性能优化**: 使用批量处理，避免单实体操作

```csharp
// ✅ 好的系统设计
public class MovementSystem : QuerySystem<Position, Velocity>
{
    protected override void OnUpdate()
    {
        foreach (var entity in Query.Entities)
        {
            var pos = entity.GetComponent<Position>();
            var vel = entity.GetComponent<Velocity>();
            pos.Value += vel.Value;
        }
    }
}
```

### 3. 内存管理

- **预分配**: 预先分配大量实体避免运行时分配
- **对象池**: 对频繁创建/销毁的实体使用对象池
- **组件复用**: 重用组件而不是创建新组件

## 🐛 常见问题

### Q: 实体创建性能慢？
**A**: 使用批量操作和对象池，避免频繁单实体创建。

### Q: 系统更新卡顿？
**A**: 优化查询范围，使用过滤条件减少处理的实体数量。

### Q: 内存占用高？
**A**: 使用组件池，及时清理无用实体，避免内存泄漏。

### Q: 渲染性能差？
**A**: 实现LOD系统，使用批量渲染，减少DrawCall。

## 🔮 未来扩展

### 计划中的功能

1. **多线程ECS**: 支持多线程系统更新
2. **ECS-Job系统**: 使用Unity Job System优化性能
3. **ECS-Burst**: 使用Burst编译器优化性能
4. **可视化编辑器**: ECS实体和组件的可视化编辑
5. **网络同步**: ECS实体的网络同步支持

### 迁移指南

将传统系统迁移到ECS的步骤：

1. **识别实体**: 确定游戏中的实体类型
2. **设计组件**: 为每个实体设计合适的组件
3. **创建系统**: 将逻辑移到对应的系统
4. **数据同步**: 处理与传统系统的数据同步
5. **性能测试**: 验证ECS性能提升

---

## 📚 相关文档

- [ECS集成完成报告](../ECS集成完成报告.md)
- [ECS性能优化总结](../ECS性能优化总结.md)
- [Friflo ECS API指南](../Friflo-ECS-API-Guide.md)
- [ECS组件设计指南](../Friflo-ECS-Components.md)

---

**文档版本**: 1.0  
**最后更新**: 2025-01-20  
**维护者**: Claude Code Assistant
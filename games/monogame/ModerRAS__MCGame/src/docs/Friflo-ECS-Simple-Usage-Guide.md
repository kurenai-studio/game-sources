# Friflo ECS 使用指南

## 概述

Friflo ECS 是一个高性能的 C# 实体组件系统框架，专为游戏开发设计。本指南基于 Friflo ECS 的接口文档，提供简单直接的使用说明。

## 核心概念

### 1. 实体 (Entity)
- 实体是组件的容器，本身不包含数据
- 使用 `EntityStore` 创建和管理实体
- 每个实体都有唯一的 ID

### 2. 组件 (Component)
- 组件是纯数据结构，不包含逻辑
- 必须实现 `IComponent` 接口
- 使用 `struct` 而非 `class` 以获得更好的性能

### 3. 系统 (System)
- 系统包含处理实体的逻辑
- 继承 `QuerySystem<T>` 来处理特定组件组合
- 使用 `SystemRoot` 管理多个系统

## 基础使用

### 1. 创建 EntityStore

```csharp
using Friflo.Engine.ECS;

// 创建实体存储
var store = new EntityStore();
```

### 2. 定义组件

```csharp
// 位置组件
public struct Position : IComponent
{
    public Vector3 Value;
}

// 速度组件
public struct Velocity : IComponent
{
    public Vector3 Value;
}

// 玩家组件
public struct Player : IComponent
{
    public string Name;
    public float Health;
}
```

### 3. 创建实体

```csharp
// 创建带有组件的实体
var entity = store.CreateEntity(
    new Position { Value = new Vector3(10, 5, 10) },
    new Velocity { Value = new Vector3(0, 0, 5) },
    new Player { Name = "Player1", Health = 100 }
);

// 创建空实体并逐个添加组件
var emptyEntity = store.CreateEntity();
emptyEntity.AddComponent(new Position { Value = new Vector3(0, 0, 0) });
emptyEntity.AddComponent(new Velocity { Value = new Vector3(1, 0, 0) });
```

### 4. 查询实体

```csharp
// 创建查询
var playerQuery = store.Query<Player, Position, Velocity>();

// 遍历查询结果
foreach (var entity in playerQuery.Entities)
{
    var player = entity.GetComponent<Player>();
    var position = entity.GetComponent<Position>();
    var velocity = entity.GetComponent<Velocity>();
    
    Console.WriteLine($"Player: {player.Name} at {position.Value}");
}

// 获取查询统计
int count = playerQuery.EntityCount;
Entity[] entities = playerQuery.Entities;
```

### 5. 更新组件

```csharp
// 直接访问组件
var position = entity.GetComponent<Position>();
position.Value = new Vector3(15, 6, 15);

// 安全访问组件
if (entity.TryGetComponent<Position>(out var safePosition))
{
    safePosition.Value = new Vector3(20, 7, 20);
}

// 添加/移除组件
entity.AddComponent(new Player { Name = "NewPlayer", Health = 50 });
entity.RemoveComponent<Velocity>();

// 检查组件是否存在
bool hasPosition = entity.HasComponent<Position>();
```

### 6. 删除实体

```csharp
// 删除单个实体
entity.Dispose();

// 批量删除实体
foreach (var entity in playerQuery.Entities)
{
    entity.Dispose();
}

// 清空所有实体
store.DeleteAllEntities();
```

## 系统开发

### 1. 创建 QuerySystem

```csharp
public class MovementSystem : QuerySystem<Position, Velocity>
{
    protected override void OnUpdate()
    {
        // 遍历所有具有 Position 和 Velocity 组件的实体
        foreach (var entity in Query.Entities)
        {
            var position = entity.GetComponent<Position>();
            var velocity = entity.GetComponent<Velocity>();
            
            // 更新位置
            position.Value += velocity.Value * 0.016f; // 假设60fps
        }
    }
}
```

### 2. 使用 SystemRoot

```csharp
// 创建系统根
var systemRoot = new SystemRoot(store);

// 添加系统
systemRoot.Add(new MovementSystem());
systemRoot.Add(new PlayerSystem());

// 更新系统
systemRoot.Update(deltaTime);

// 启用性能监控
systemRoot.SetMonitorPerf(true);

// 获取性能日志
string perfLog = systemRoot.GetPerfLog();
```

### 3. 系统间通信

```csharp
public class InputSystem : QuerySystem<Player, Input>
{
    protected override void OnUpdate()
    {
        foreach (var entity in Query.Entities)
        {
            var input = entity.GetComponent<Input>();
            // 处理输入
        }
    }
}

public class PlayerSystem : QuerySystem<Player, Position, Velocity>
{
    protected override void OnUpdate()
    {
        foreach (var entity in Query.Entities)
        {
            var player = entity.GetComponent<Player>();
            var position = entity.GetComponent<Position>();
            var velocity = entity.GetComponent<Velocity>();
            
            // 使用输入更新玩家状态
        }
    }
}
```

## 高级功能

### 1. 命令缓冲区

```csharp
// 创建命令缓冲区
var commands = store.CreateCommandBuffer();

// 批量操作
var newEntity = commands.CreateEntity(
    new Position { Value = new Vector3(0, 0, 0) }
);

commands.DestroyEntity(entityToRemove);

// 执行命令
commands.Playback();
```

### 2. 事件系统

```csharp
// 创建事件
var eventSystem = new EventSystem(store);

// 监听事件
eventSystem.Subscribe<EntityCreatedEvent>(OnEntityCreated);

// 触发事件
eventSystem.Publish(new EntityCreatedEvent { Entity = entity });
```

### 3. 标签组件

```csharp
// 定义标签
public struct PlayerTag : ITag { }

// 添加标签
entity.AddComponent<PlayerTag>();

// 查询带有标签的实体
var playerQuery = store.Query<PlayerTag, Position>();
```

## 性能优化

### 1. 缓存查询

```csharp
public class PlayerManager
{
    private readonly EntityStore _store;
    private readonly ArchetypeQuery _playerQuery;
    
    public PlayerManager(EntityStore store)
    {
        _store = store;
        _playerQuery = store.Query<Player, Position>();
    }
    
    public void UpdatePlayers()
    {
        foreach (var entity in _playerQuery.Entities)
        {
            // 处理玩家
        }
    }
}
```

### 2. 批量操作

```csharp
// 批量创建实体
var entities = new List<Entity>();
for (int i = 0; i < 1000; i++)
{
    var entity = store.CreateEntity(
        new Position { Value = new Vector3(i, 0, 0) },
        new Velocity { Value = new Vector3(0, 0, 1) }
    );
    entities.Add(entity);
}

// 批量删除
foreach (var entity in entities)
{
    entity.Dispose();
}
```

### 3. 对象池

```csharp
// 使用 ListPool 减少内存分配
var entityList = ListPool<Entity>.Get();
try
{
    foreach (var entity in query.Entities)
    {
        entityList.Add(entity);
    }
    // 使用 entityList
}
finally
{
    ListPool<Entity>.Release(entityList);
}
```

## 最佳实践

### 1. 组件设计
- 保持组件简单和单一职责
- 使用值类型（struct）而非引用类型（class）
- 避免在组件中存储大量数据

### 2. 查询优化
- 缓存频繁使用的查询
- 避免在热路径中创建新查询
- 使用 `TryGetComponent` 进行安全访问

### 3. 内存管理
- 及时删除不再需要的实体
- 使用对象池减少 GC 压力
- 避免频繁创建和销毁组件

### 4. 系统设计
- 每个系统专注于一个特定功能
- 按依赖关系排序系统更新
- 使用 SystemRoot 管理系统生命周期

## 常见问题

### 1. 实体删除失败
```csharp
// 正确的删除方式
entity.Dispose();

// 错误的删除方式
entity.Delete(); // 不存在此方法
entity.DeleteEntity(); // 不存在此方法
store.DeleteEntity(entity.Id); // 不存在此方法
```

### 2. 查询遍历失败
```csharp
// 正确的遍历方式
foreach (var entity in query.Entities)

// 错误的遍历方式
foreach (var entity in query) // 错误
foreach (var entity in query.GetEnumerator()) // 错误
```

### 3. 组件访问异常
```csharp
// 安全的组件访问
if (entity.TryGetComponent<Position>(out var position))
{
    position.Value = new Vector3(1, 2, 3);
}

// 检查实体有效性
if (entity.IsAlive)
{
    // 安全操作
}
```

## 示例项目

```csharp
using Friflo.Engine.ECS;
using Microsoft.Xna.Framework;

public class SimpleGame
{
    private readonly EntityStore _store;
    private readonly SystemRoot _systemRoot;
    
    public SimpleGame()
    {
        _store = new EntityStore();
        _systemRoot = new SystemRoot(_store);
        
        // 添加系统
        _systemRoot.Add(new MovementSystem());
        _systemRoot.Add(new InputSystem());
        
        // 创建初始实体
        CreatePlayer();
        CreateObstacles();
    }
    
    public void Update(GameTime gameTime)
    {
        _systemRoot.Update((float)gameTime.ElapsedGameTime.TotalSeconds);
    }
    
    private void CreatePlayer()
    {
        _store.CreateEntity(
            new Position { Value = new Vector3(0, 0, 0) },
            new Velocity { Value = new Vector3(0, 0, 0) },
            new Player { Name = "Player", Health = 100 }
        );
    }
    
    private void CreateObstacles()
    {
        for (int i = 0; i < 10; i++)
        {
            _store.CreateEntity(
                new Position { Value = new Vector3(i * 5, 0, 0) },
                new Obstacle { Type = ObstacleType.Box }
            );
        }
    }
}
```

## 总结

Friflo ECS 提供了一个强大而灵活的实体组件系统，适合游戏开发。通过遵循本指南中的最佳实践，您可以构建高性能、可维护的游戏系统。

关键要点：
1. 使用 `entity.Dispose()` 删除实体
2. 使用 `foreach (var entity in query.Entities)` 遍历查询
3. 使用 `store.Query<T>()` 创建查询
4. 优先使用 `TryGetComponent` 进行安全访问
5. 缓存查询结果以提高性能

有关更详细的 API 参考，请参阅 Friflo ECS 官方文档。
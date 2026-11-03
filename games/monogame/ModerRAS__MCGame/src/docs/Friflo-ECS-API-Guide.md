# Friflo ECS API 完整使用指南

## 📖 概述

本文档是MCGame项目中Friflo Engine ECS 3.4.2框架的完整API使用指南。基于实际项目代码，提供详细的API用法、最佳实践和性能优化建议。

### 🎯 文档目标
- 为开发者提供完整的Friflo ECS API参考
- 基于实际项目代码展示最佳实践
- 提供性能优化和错误处理指导
- 便于后人查询和维护

### 🛠️ 技术栈
- **ECS框架**: Friflo.Engine.ECS 3.4.2
- **游戏引擎**: MonoGame.Framework.DesktopGL 3.8.1.303
- **运行时**: .NET 9.0
- **语言**: C# 13.0

## 📋 目录

- [基础架构](#基础架构)
- [实体管理](#实体管理)
- [组件系统](#组件系统)
- [查询系统](#查询系统)
- [系统管理](#系统管理)
- [性能优化](#性能优化)
- [错误处理](#错误处理)
- [集成MonoGame](#集成monogame)
- [调试和监控](#调试和监控)
- [最佳实践](#最佳实践)
- [常见问题](#常见问题)

## 基础架构

### EntityStore - 实体存储

`EntityStore`是Friflo ECS的核心容器，负责管理所有实体和组件。

```csharp
// 创建实体存储
var store = new EntityStore();

// 获取实体数量
int entityCount = store.Count;

// 删除所有实体
store.DeleteAllEntities();
```

### SystemRoot - 系统根节点

`SystemRoot`管理所有ECS系统的生命周期。

```csharp
// 创建系统根节点
var systemRoot = new SystemRoot(store);

// 添加系统
systemRoot.Add(new PlayerInputSystem());

// 启用性能监控
systemRoot.SetMonitorPerf(true);

// 更新所有系统
systemRoot.Update(gameTime);

// 获取性能日志
string perfLog = systemRoot.GetPerfLog();

// 释放资源
systemRoot.Dispose();
```

## 实体管理

### 创建实体

```csharp
// 创建单个实体
var entity = store.CreateEntity(
    new Position(0, 64, 0),
    new Rotation(0, 0, 0),
    new Velocity(0, 0, 0),
    new PlayerComponent(),
    new Visibility(true)
);

// 获取实体ID
int entityId = entity.Id;

// 删除实体
entity.Delete();
```

### 批量创建实体

```csharp
// 批量创建实体（高性能）
var entities = new Entity[count];
for (int i = 0; i < count; i++)
{
    entities[i] = store.CreateEntity(
        new Block(blockType),
        new Position(position),
        new Visibility(true)
    );
}
```

### 使用Commands进行批量操作

```csharp
// 创建命令缓冲区
var commands = store.CreateCommandBuffer();

// 批量创建实体
for (int i = 0; i < count; i++)
{
    var entity = commands.CreateEntity();
    commands.AddComponent(entity.Id, new Block(blockType));
    commands.AddComponent(entity.Id, new Position(position));
}

// 执行命令
commands.Playback();
```

## 组件系统

### 定义组件

```csharp
// 所有组件必须实现IComponent接口
public struct Position : IComponent
{
    public Vector3 Value;
    
    public Position(Vector3 value) => Value = value;
    public Position(float x, float y, float z) => Value = new Vector3(x, y, z);
}

// 带构造函数的组件
public struct Player : IComponent
{
    public float MoveSpeed;
    public float LookSpeed;
    public bool IsGrounded;
    
    public Player(float moveSpeed = 10f, float lookSpeed = 0.1f)
    {
        MoveSpeed = moveSpeed;
        LookSpeed = lookSpeed;
        IsGrounded = false;
    }
}
```

### 组件操作

```csharp
// 添加组件
entity.AddComponent(new Position(10, 20, 30));

// 获取组件
if (entity.TryGetComponent<Position>(out var position))
{
    // 使用组件
    position.Value = new Vector3(15, 25, 35);
}

// 获取组件（直接）
var position = entity.GetComponent<Position>();

// 移除组件
entity.RemoveComponent<Position>();

// 检查组件是否存在
bool hasPosition = entity.HasComponent<Position>();
```

### 批量组件操作

```csharp
// 批量添加组件
var commands = store.CreateCommandBuffer();
for (int i = 0; i < entities.Length; i++)
{
    commands.AddComponent(entities[i].Id, new Visibility(true));
}
commands.Playback();
```

## 查询系统

### ArchetypeQuery - 原型查询

```csharp
// 创建查询
var blockQuery = store.Query<Block, Position, Visibility>();
var playerQuery = store.Query<Player, Position, Velocity>();

// 获取查询结果
int entityCount = blockQuery.EntityCount;
Entity[] entities = blockQuery.Entities;

// 遍历查询结果
foreach (var entity in blockQuery.Entities)
{
    var block = entity.GetComponent<Block>();
    var position = entity.GetComponent<Position>();
    var visibility = entity.GetComponent<Visibility>();
    
    // 处理实体
}
```

### 条件查询

```csharp
// 查询特定条件的实体
var visibleBlocks = new List<Entity>();
foreach (var entity in blockQuery.Entities)
{
    var visibility = entity.GetComponent<Visibility>();
    if (visibility.IsVisible)
    {
        visibleBlocks.Add(entity);
    }
}
```

### 查询优化

```csharp
// 缓存查询结果
private ArchetypeQuery _blockQuery;
private ArchetypeQuery _playerQuery;

// 在构造函数中初始化查询
_blockQuery = store.Query<Block, Position>();
_playerQuery = store.Query<Player, Position, Velocity>();

// 使用缓存的查询
public Entity[] GetVisibleBlocks()
{
    var result = new List<Entity>();
    foreach (var entity in _blockQuery.Entities)
    {
        var visibility = entity.GetComponent<Visibility>();
        if (visibility.IsVisible)
        {
            result.Add(entity);
        }
    }
    return result.ToArray();
}
```

## 系统管理

### QuerySystem - 查询系统

```csharp
// 继承QuerySystem并指定组件类型
public class PlayerInputSystem : QuerySystem<Input>
{
    protected override void OnUpdate()
    {
        // 使用Query属性遍历实体
        Query.ForEachEntity((ref Input input, Entity entity) =>
        {
            // 检查是否是玩家实体
            if (!entity.TryGetComponent<Player>(out var player))
                return;
            
            // 处理输入
            input.Movement = GetMovementInput();
            input.Jump = GetJumpInput();
        });
    }
    
    private Vector2 GetMovementInput()
    {
        // 实现输入逻辑
        return Vector2.Zero;
    }
    
    private bool GetJumpInput()
    {
        // 实现跳跃逻辑
        return false;
    }
}
```

### 多组件查询系统

```csharp
public class PlayerMovementSystem : QuerySystem<Position, Rotation, Velocity, Input, Player>
{
    protected override void OnUpdate()
    {
        var deltaTime = (float)Tick.DeltaTime;
        
        Query.ForEachEntity((
            ref Position position, 
            ref Rotation rotation, 
            ref Velocity velocity, 
            ref Input input, 
            ref Player player, 
            Entity entity) =>
        {
            // 更新旋转
            rotation.Value.Y += input.Look.X * player.LookSpeed;
            rotation.Value.X += input.Look.Y * player.LookSpeed;
            
            // 计算移动方向
            var yaw = rotation.Value.Y;
            var forward = new Vector3((float)Math.Sin(yaw), 0, (float)Math.Cos(yaw));
            var right = new Vector3((float)Math.Cos(yaw), 0, -(float)Math.Sin(yaw));
            
            // 应用移动
            var moveDirection = forward * input.Movement.Y + right * input.Movement.X;
            if (moveDirection != Vector3.Zero)
            {
                moveDirection.Normalize();
                velocity.Value = moveDirection * player.MoveSpeed;
            }
            
            // 更新位置
            position.Value += velocity.Value * deltaTime;
        });
    }
}
```

### 系统生命周期

```csharp
public class CustomSystem : QuerySystem<Position>
{
    // 系统初始化
    protected override void OnStart()
    {
        // 初始化系统资源
    }
    
    // 系统更新
    protected override void OnUpdate()
    {
        Query.ForEachEntity((ref Position position, Entity entity) =>
        {
            // 更新逻辑
        });
    }
    
    // 系统停止
    protected override void OnStop()
    {
        // 清理系统资源
    }
}
```

## 性能优化

### 批量操作

```csharp
// 批量创建实体（优化性能）
public Entity[] CreateBlockEntitiesBatch(BlockType[] blockTypes, Vector3[] positions)
{
    var entities = new Entity[blockTypes.Length];
    var commands = store.CreateCommandBuffer();
    
    for (int i = 0; i < blockTypes.Length; i++)
    {
        var entity = commands.CreateEntity();
        commands.AddComponent(entity.Id, new Block(blockTypes[i]));
        commands.AddComponent(entity.Id, new Position(positions[i]));
        commands.AddComponent(entity.Id, new Visibility(true));
        commands.AddComponent(entity.Id, new Collider(new BoundingBox(positions[i], positions[i] + Vector3.One)));
        
        entities[i] = entity;
    }
    
    commands.Playback();
    return entities;
}
```

### 缓存查询结果

```csharp
// 缓存常用查询
public class ECSWorld
{
    private readonly ArchetypeQuery _chunkQuery;
    private readonly ArchetypeQuery _blockQuery;
    private readonly ArchetypeQuery _playerQuery;
    
    public ECSWorld()
    {
        _store = new EntityStore();
        _chunkQuery = _store.Query<Chunk>();
        _blockQuery = _store.Query<Block>();
        _playerQuery = _store.Query<Player>();
    }
    
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
}
```

### 对象池优化

```csharp
// 使用对象池减少内存分配
public class ECSBlockManager
{
    private readonly ObjectPool<Entity> _entityPool;
    
    public ECSBlockManager(EntityStore store)
    {
        _entityPool = new ObjectPool<Entity>(() => store.CreateEntity());
    }
    
    public Entity CreateBlockEntity(BlockType blockType, Vector3 position)
    {
        var entity = _entityPool.Get();
        entity.AddComponent(new Block(blockType));
        entity.AddComponent(new Position(position));
        entity.AddComponent(new Visibility(true));
        return entity;
    }
    
    public void DestroyBlockEntity(Entity entity)
    {
        entity.RemoveAllComponents();
        _entityPool.Return(entity);
    }
}
```

## 集成MonoGame

### ECSWorld集成

```csharp
public class ECSWorld
{
    private readonly EntityStore _store;
    private readonly SystemRoot _systemRoot;
    
    public ECSWorld()
    {
        _store = new EntityStore();
        _systemRoot = new SystemRoot(_store);
        
        InitializeSystems();
        CreateDefaultPlayer();
    }
    
    private void InitializeSystems()
    {
        _systemRoot.Add(new PlayerInputSystem());
        _systemRoot.Add(new PlayerMovementSystem());
        _systemRoot.Add(new PhysicsSystem());
        _systemRoot.Add(new CameraSystem());
        _systemRoot.Add(new VisibilitySystem());
        _systemRoot.Add(new ChunkStateSystem());
    }
    
    public void Update(GameTime gameTime)
    {
        Tick.UpdateTime(gameTime);
        _systemRoot.Update(gameTime);
    }
    
    public void Destroy()
    {
        _systemRoot.Dispose();
        _store.DeleteAllEntities();
    }
}
```

### 渲染集成

```csharp
public class ECSRenderer
{
    private readonly GraphicsDevice _graphicsDevice;
    private readonly BasicEffect _basicEffect;
    
    public void RenderVisibleEntities(ArchetypeQuery blockQuery, Matrix viewMatrix, Matrix projectionMatrix)
    {
        // 设置渲染状态
        _graphicsDevice.RasterizerState = _rasterizerState;
        _graphicsDevice.DepthStencilState = _depthStencilState;
        
        // 设置相机矩阵
        _basicEffect.View = viewMatrix;
        _basicEffect.Projection = projectionMatrix;
        
        // 渲染方块
        foreach (var blockEntity in blockQuery.Entities)
        {
            var visibility = blockEntity.GetComponent<Visibility>();
            if (!visibility.IsVisible)
                continue;
                
            var position = blockEntity.GetComponent<Position>();
            var block = blockEntity.GetComponent<Block>();
            
            // 渲染方块
            RenderBlock(block.Type, position.Value);
        }
    }
}
```

### 游戏循环集成

```csharp
public class MCGame : Game
{
    private readonly ECSWorld _ecsWorld;
    private readonly ECSRenderer _ecsRenderer;
    
    protected override void Update(GameTime gameTime)
    {
        _ecsWorld.Update(gameTime);
        base.Update(gameTime);
    }
    
    protected override void Draw(GameTime gameTime)
    {
        GraphicsDevice.Clear(Color.CornflowerBlue);
        
        // 获取相机矩阵
        var viewMatrix = GetViewMatrix();
        var projectionMatrix = GetProjectionMatrix();
        
        // 渲染ECS实体
        var blockQuery = _ecsWorld.Store.Query<Block, Position, Visibility>();
        _ecsRenderer.RenderVisibleEntities(blockQuery, viewMatrix, projectionMatrix);
        
        base.Draw(gameTime);
    }
}
```

## 🔧 错误处理

### 1. 组件访问安全

```csharp
// ✅ 安全的组件访问方式
public void ProcessEntity(Entity entity)
{
    // 使用TryGetComponent进行安全访问
    if (entity.TryGetComponent<Position>(out var position))
    {
        // 安全地使用position组件
        position.Value = new Vector3(1, 2, 3);
    }
    else
    {
        // 处理组件不存在的情况
        Console.WriteLine("实体没有Position组件");
        // 可以选择添加组件
        entity.AddComponent(new Position(Vector3.Zero));
    }
}

// ❌ 不安全的直接访问（可能抛出异常）
public void ProcessEntityUnsafe(Entity entity)
{
    try
    {
        var position = entity.GetComponent<Position>();
        position.Value = new Vector3(1, 2, 3);
    }
    catch (ComponentNotFoundException ex)
    {
        Console.WriteLine($"组件访问错误: {ex.Message}");
        // 需要处理异常情况
    }
}
```

### 2. 系统异常处理

```csharp
// ✅ 带有异常处理的系统
public class RobustSystem : QuerySystem<Position, Velocity>
{
    private int _errorCount = 0;
    private const int MaxErrors = 10;
    
    protected override void OnUpdate()
    {
        try
        {
            Query.ForEachEntity((ref Position position, ref Velocity velocity, Entity entity) =>
            {
                try
                {
                    // 处理单个实体
                    ProcessEntity(entity, ref position, ref velocity);
                }
                catch (Exception ex)
                {
                    _errorCount++;
                    Console.WriteLine($"处理实体 {entity.Id} 时出错: {ex.Message}");
                    
                    // 如果错误过多，禁用系统
                    if (_errorCount >= MaxErrors)
                    {
                        Console.WriteLine("错误过多，禁用系统");
                        Enabled = false;
                    }
                }
            });
        }
        catch (Exception ex)
        {
            Console.WriteLine($"系统更新错误: {ex.Message}");
            // 可以选择继续处理其他实体或停止系统
        }
    }
    
    private void ProcessEntity(Entity entity, ref Position position, ref Velocity velocity)
    {
        // 实体处理逻辑
        if (entity.IsAlive)
        {
            // 安全的实体处理
            UpdateEntityPosition(ref position, ref velocity);
        }
    }
}
```

### 3. 实体创建错误处理

```csharp
// ✅ 带有验证的实体创建
public Entity CreateEntityWithValidation(Vector3 position, BlockType blockType)
{
    try
    {
        // 验证参数
        if (float.IsNaN(position.X) || float.IsNaN(position.Y) || float.IsNaN(position.Z))
        {
            throw new ArgumentException("位置包含NaN值");
        }
        
        if (!Enum.IsDefined(typeof(BlockType), blockType))
        {
            throw new ArgumentException($"无效的方块类型: {blockType}");
        }
        
        // 创建实体
        var entity = _store.CreateEntity(
            new Position(position),
            new Block(blockType),
            new Visibility(true)
        );
        
        // 验证实体创建成功
        if (entity.Id == 0)
        {
            throw new Exception("实体创建失败");
        }
        
        return entity;
    }
    catch (Exception ex)
    {
        Console.WriteLine($"创建实体失败: {ex.Message}");
        // 返回默认实体或抛出异常
        return default;
    }
}
```

### 4. 查询错误处理

```csharp
// ✅ 安全的查询处理
public void ProcessEntitiesSafely()
{
    try
    {
        var query = _store.Query<Position, Velocity>();
        
        if (query == null)
        {
            Console.WriteLine("查询创建失败");
            return;
        }
        
        foreach (var entity in query.Entities)
        {
            if (!entity.IsAlive)
            {
                continue; // 跳过已删除的实体
            }
            
            try
            {
                var position = entity.GetComponent<Position>();
                var velocity = entity.GetComponent<Velocity>();
                
                // 处理实体
                ProcessEntity(entity, position, velocity);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"处理实体 {entity.Id} 时出错: {ex.Message}");
                // 继续处理其他实体
            }
        }
    }
    catch (Exception ex)
    {
        Console.WriteLine($"查询处理失败: {ex.Message}");
    }
}
```

### 5. 资源清理错误处理

```csharp
// ✅ 带有资源清理的ECSWorld
public class ECSWorld : IDisposable
{
    private bool _disposed = false;
    
    public void Dispose()
    {
        Dispose(true);
        GC.SuppressFinalize(this);
    }
    
    protected virtual void Dispose(bool disposing)
    {
        if (!_disposed)
        {
            if (disposing)
            {
                try
                {
                    // 清理托管资源
                    _systemRoot?.Dispose();
                    _store?.DeleteAllEntities();
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"清理ECSWorld时出错: {ex.Message}");
                }
            }
            
            _disposed = true;
        }
    }
    
    ~ECSWorld()
    {
        Dispose(false);
    }
    
    public void Update(GameTime gameTime)
    {
        if (_disposed)
        {
            throw new ObjectDisposedException(nameof(ECSWorld));
        }
        
        try
        {
            _systemRoot.Update(gameTime);
        }
        catch (Exception ex)
        {
            Console.WriteLine($"ECSWorld更新失败: {ex.Message}");
            // 可以选择继续运行或停止
        }
    }
}
```

## 最佳实践

### 1. 组件设计原则

```csharp
// 好的组件设计：单一职责
public struct Position : IComponent
{
    public Vector3 Value;
}

public struct Velocity : IComponent
{
    public Vector3 Value;
}

// 避免的组件设计：多重职责
public struct MovementComponent : IComponent
{
    public Vector3 Position;  // 应该分离到Position组件
    public Vector3 Velocity;  // 应该分离到Velocity组件
    public float Speed;       // 应该分离到Player组件
}
```

### 2. 查询优化

```csharp
// 好的做法：缓存查询
private readonly ArchetypeQuery _playerQuery;

public PlayerMovementSystem()
{
    _playerQuery = Store.Query<Player, Position, Velocity>();
}

protected override void OnUpdate()
{
    // 使用缓存的查询
    foreach (var entity in _playerQuery.Entities)
    {
        // 处理逻辑
    }
}

// 避免：每次更新都创建新查询
protected override void OnUpdate()
{
    // 性能较差：每次都创建新查询
    var query = Store.Query<Player, Position, Velocity>();
    foreach (var entity in query.Entities)
    {
        // 处理逻辑
    }
}
```

### 3. 内存管理

```csharp
// 好的做法：重用数组和列表
private readonly List<Entity> _entityList = new List<Entity>();

public Entity[] GetVisibleEntities()
{
    _entityList.Clear();
    
    foreach (var entity in _query.Entities)
    {
        var visibility = entity.GetComponent<Visibility>();
        if (visibility.IsVisible)
        {
            _entityList.Add(entity);
        }
    }
    
    return _entityList.ToArray();
}

// 避免：频繁创建新数组
public Entity[] GetVisibleEntities()
{
    // 性能较差：每次都创建新数组
    var visibleEntities = new List<Entity>();
    // ... 填充数组
    return visibleEntities.ToArray();
}
```

## 🔍 调试和监控

### 1. 性能监控

```csharp
// ✅ 详细的性能监控
public class ECSPerformanceMonitor
{
    private readonly SystemRoot _systemRoot;
    private readonly Stopwatch _stopwatch = new Stopwatch();
    private long _lastFrameTime;
    
    public ECSPerformanceMonitor(SystemRoot systemRoot)
    {
        _systemRoot = systemRoot;
        _systemRoot.SetMonitorPerf(true);
    }
    
    public void LogPerformance()
    {
        _stopwatch.Stop();
        var frameTime = _stopwatch.ElapsedMilliseconds;
        var fps = 1000.0 / (frameTime - _lastFrameTime);
        _lastFrameTime = frameTime;
        
        Console.WriteLine("=== ECS 性能统计 ===");
        Console.WriteLine($"帧时间: {frameTime}ms");
        Console.WriteLine($"FPS: {fps:F1}");
        
        // 获取系统性能日志
        var perfLog = _systemRoot.GetPerfLog();
        Console.WriteLine($"系统性能: {perfLog}");
        
        // 获取实体统计
        var stats = GetEntityStats();
        Console.WriteLine($"总实体数: {stats.TotalEntities}");
        Console.WriteLine($"区块实体: {stats.ChunkEntities}");
        Console.WriteLine($"方块实体: {stats.BlockEntities}");
        Console.WriteLine($"玩家实体: {stats.PlayerEntities}");
        
        _stopwatch.Restart();
    }
    
    public void StartFrame()
    {
        _stopwatch.Restart();
    }
}
```

### 2. 实体检查和调试

```csharp
// ✅ 完整的实体检查工具
public class ECSEntityDebugger
{
    private readonly EntityStore _store;
    
    public ECSEntityDebugger(EntityStore store)
    {
        _store = store;
    }
    
    // 打印实体详细信息
    public void PrintEntityDetails(Entity entity)
    {
        Console.WriteLine($"=== 实体 {entity.Id} 详情 ===");
        Console.WriteLine($"是否存活: {entity.IsAlive}");
        Console.WriteLine($"组件数量: {entity.ComponentCount}");
        
        // 打印所有组件
        var componentTypes = entity.GetComponentTypes();
        foreach (var type in componentTypes)
        {
            Console.WriteLine($"  组件: {type.Name}");
            
            // 尝试打印组件值
            try
            {
                if (type == typeof(Position))
                {
                    var pos = entity.GetComponent<Position>();
                    Console.WriteLine($"    位置: {pos.Value}");
                }
                else if (type == typeof(Velocity))
                {
                    var vel = entity.GetComponent<Velocity>();
                    Console.WriteLine($"    速度: {vel.Value}");
                }
                else if (type == typeof(Block))
                {
                    var block = entity.GetComponent<Block>();
                    Console.WriteLine($"    方块类型: {block.Type}");
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"    读取组件失败: {ex.Message}");
            }
        }
    }
    
    // 检查特定类型的所有实体
    public void InspectEntitiesByType<T>() where T : IComponent
    {
        var query = _store.Query<T>();
        Console.WriteLine($"=== {typeof(T).Name} 组件实体 ===");
        Console.WriteLine($"实体数量: {query.EntityCount}");
        
        foreach (var entity in query.Entities)
        {
            try
            {
                var component = entity.GetComponent<T>();
                Console.WriteLine($"  实体 {entity.Id}: {component}");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"  实体 {entity.Id}: 读取失败 - {ex.Message}");
            }
        }
    }
    
    // 检查无效实体
    public void CheckInvalidEntities()
    {
        Console.WriteLine("=== 检查无效实体 ===");
        var invalidCount = 0;
        
        // 检查所有查询中的实体
        var allQueries = new[]
        {
            _store.Query<Position>(),
            _store.Query<Velocity>(),
            _store.Query<Block>(),
            _store.Query<Chunk>()
        };
        
        foreach (var query in allQueries)
        {
            foreach (var entity in query.Entities)
            {
                if (!entity.IsAlive)
                {
                    Console.WriteLine($"发现无效实体: {entity.Id}");
                    invalidCount++;
                }
            }
        }
        
        Console.WriteLine($"无效实体数量: {invalidCount}");
    }
}
```

### 3. 内存监控

```csharp
// ✅ 内存使用监控
public class ECSMemoryMonitor
{
    private long _initialMemory;
    
    public ECSMemoryMonitor()
    {
        // 强制垃圾回收以获取基准内存使用
        GC.Collect();
        GC.WaitForPendingFinalizers();
        _initialMemory = GC.GetTotalMemory(true);
    }
    
    public void LogMemoryUsage()
    {
        var currentMemory = GC.GetTotalMemory(false);
        var allocatedMemory = currentMemory - _initialMemory;
        
        Console.WriteLine("=== 内存使用统计 ===");
        Console.WriteLine($"初始内存: {_initialMemory} bytes");
        Console.WriteLine($"当前内存: {currentMemory} bytes");
        Console.WriteLine($"已分配内存: {allocatedMemory} bytes");
        
        // 强制垃圾回收并报告
        GC.Collect();
        GC.WaitForPendingFinalizers();
        var afterGC = GC.GetTotalMemory(true);
        Console.WriteLine($"GC后内存: {afterGC} bytes");
        
        // 检查内存泄漏
        if (allocatedMemory > 100 * 1024 * 1024) // 100MB
        {
            Console.WriteLine("⚠️  警告: 内存使用较高，可能存在内存泄漏");
        }
    }
    
    public void ResetBaseline()
    {
        GC.Collect();
        GC.WaitForPendingFinalizers();
        _initialMemory = GC.GetTotalMemory(true);
    }
}
```

### 4. 系统健康检查

```csharp
// ✅ 系统健康检查
public class ECSSystemHealthChecker
{
    private readonly SystemRoot _systemRoot;
    private readonly EntityStore _store;
    
    public ECSSystemHealthChecker(SystemRoot systemRoot, EntityStore store)
    {
        _systemRoot = systemRoot;
        _store = store;
    }
    
    public void RunHealthCheck()
    {
        Console.WriteLine("=== ECS 系统健康检查 ===");
        
        // 检查系统状态
        CheckSystemHealth();
        
        // 检查实体状态
        CheckEntityHealth();
        
        // 检查查询性能
        CheckQueryPerformance();
        
        // 检查内存使用
        CheckMemoryHealth();
    }
    
    private void CheckSystemHealth()
    {
        try
        {
            // 尝试更新系统（空更新）
            _systemRoot.Update(new GameTime());
            Console.WriteLine("✅ 系统更新正常");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"❌ 系统更新失败: {ex.Message}");
        }
    }
    
    private void CheckEntityHealth()
    {
        var totalEntities = _store.Count;
        Console.WriteLine($"总实体数: {totalEntities}");
        
        if (totalEntities > 100000)
        {
            Console.WriteLine("⚠️  警告: 实体数量过多，可能影响性能");
        }
    }
    
    private void CheckQueryPerformance()
    {
        var stopwatch = Stopwatch.StartNew();
        var query = _store.Query<Position>();
        var count = 0;
        
        foreach (var entity in query.Entities)
        {
            count++;
            if (count > 1000) break; // 限制检查数量
        }
        
        stopwatch.Stop();
        var queryTime = stopwatch.ElapsedMilliseconds;
        
        Console.WriteLine($"查询 {count} 个实体耗时: {queryTime}ms");
        
        if (queryTime > 10)
        {
            Console.WriteLine("⚠️  警告: 查询性能较差");
        }
    }
    
    private void CheckMemoryHealth()
    {
        var memoryBefore = GC.GetTotalMemory(false);
        
        // 执行一些内存密集操作
        var testEntities = new List<Entity>();
        for (int i = 0; i < 100; i++)
        {
            testEntities.Add(_store.CreateEntity(new Position(Vector3.Zero)));
        }
        
        var memoryAfter = GC.GetTotalMemory(false);
        var memoryIncrease = memoryAfter - memoryBefore;
        
        // 清理测试实体
        foreach (var entity in testEntities)
        {
            entity.Delete();
        }
        
        Console.WriteLine($"创建100个实体内存增长: {memoryIncrease} bytes");
        
        if (memoryIncrease > 50000)
        {
            Console.WriteLine("⚠️  警告: 内存增长过快");
        }
    }
}
```

### 5. 调试命令系统

```csharp
// ✅ 调试命令系统
public class ECSDebugCommands
{
    private readonly ECSWorld _ecsWorld;
    private readonly ECSPerformanceMonitor _performanceMonitor;
    private readonly ECSEntityDebugger _entityDebugger;
    private readonly ECSMemoryMonitor _memoryMonitor;
    private readonly ECSSystemHealthChecker _healthChecker;
    
    public ECSDebugCommands(ECSWorld ecsWorld)
    {
        _ecsWorld = ecsWorld;
        _performanceMonitor = new ECSPerformanceMonitor(ecsWorld.SystemRoot);
        _entityDebugger = new ECSEntityDebugger(ecsWorld.Store);
        _memoryMonitor = new ECSMemoryMonitor();
        _healthChecker = new ECSSystemHealthChecker(ecsWorld.SystemRoot, ecsWorld.Store);
    }
    
    public void ExecuteCommand(string command)
    {
        switch (command.ToLower())
        {
            case "stats":
                _performanceMonitor.LogPerformance();
                break;
                
            case "memory":
                _memoryMonitor.LogMemoryUsage();
                break;
                
            case "health":
                _healthChecker.RunHealthCheck();
                break;
                
            case "entities":
                Console.WriteLine($"总实体数: {_ecsWorld.Store.Count}");
                break;
                
            case "check":
                _entityDebugger.CheckInvalidEntities();
                break;
                
            case "clear":
                _ecsWorld.Store.DeleteAllEntities();
                Console.WriteLine("已清除所有实体");
                break;
                
            default:
                Console.WriteLine($"未知命令: {command}");
                Console.WriteLine("可用命令: stats, memory, health, entities, check, clear");
                break;
        }
    }
}
```

## 🎯 最佳实践

### 1. 组件设计原则

```csharp
// ✅ 组件应该尽量简单和专一
public struct Position : IComponent
{
    public Vector3 Value;
    // 只负责存储位置信息
}

// ❌ 避免复杂的组件
public struct PlayerController : IComponent
{
    public Vector3 Position;
    public Vector3 Velocity;
    public float Health;
    public float Mana;
    public bool IsJumping;
    public bool IsSprinting;
    // 包含太多不相关的数据
}
```

### 2. 系统设计原则

```csharp
// ✅ 系统应该专注于单一功能
public class PlayerMovementSystem : QuerySystem<Position, Velocity, Input, Player>
{
    // 只负责处理玩家移动
}

// ✅ 分离不同的功能到不同系统
public class PlayerHealthSystem : QuerySystem<Player>
{
    // 只负责处理玩家生命值
}

// ❌ 避免多功能系统
public class PlayerEverythingSystem : QuerySystem<Position, Velocity, Input, Player, Health, Mana>
{
    // 同时处理移动、生命值、法力值等
}
```

### 3. 查询优化原则

```csharp
// ✅ 使用具体的组件类型
public class SpecificSystem : QuerySystem<Position, Velocity, Player>
{
    // 明确指定需要的组件类型
}

// ❌ 避免过于宽泛的查询
public class GeneralSystem : QuerySystem<IComponent>
{
    // 查询所有组件，性能很差
}
```

### 4. 错误处理原则

```csharp
// ✅ 使用防御性编程
public class SafeSystem : QuerySystem<Position>
{
    protected override void OnUpdate()
    {
        try
        {
            Query.ForEachEntity((ref Position position, Entity entity) =>
            {
                if (entity.IsAlive)
                {
                    // 安全地处理实体
                    ProcessPosition(ref position);
                }
            });
        }
        catch (Exception ex)
        {
            // 记录错误但不崩溃
            Console.WriteLine($"系统错误: {ex.Message}");
        }
    }
}
```

## ❓ 常见问题

**Q: 如何创建自定义组件？**
A: 实现IComponent接口的struct类型

**Q: 如何优化查询性能？**
A: 使用ArchetypeQuery并缓存查询结果

**Q: 如何处理大量实体？**
A: 使用批量操作和CommandBuffer

**Q: 如何调试ECS系统？**
A: 启用性能监控和实体检查

**Q: 如何处理内存泄漏？**
A: 使用struct组件，及时删除不需要的实体

**Q: 如何处理组件缺失？**
A: 使用TryGetComponent进行安全访问

## 📚 总结

Friflo ECS提供了高性能的实体组件系统实现，特别适合游戏开发。通过合理使用查询系统、批量操作和缓存优化，可以实现高效的实体管理。在MCGame项目中，ECS系统成功管理了大量的方块、区块和玩家实体，提供了良好的性能表现。

### 关键要点

1. **使用struct组件**减少GC压力
2. **缓存查询结果**提高性能
3. **批量操作**优化实体创建
4. **错误处理**确保系统稳定性
5. **性能监控**及时发现瓶颈
6. **内存管理**避免内存泄漏

### 下一步

- 阅读详细的组件API文档
- 学习高级查询技巧
- 实践性能优化方法
- 探索扩展ECS系统

---

*本文档基于MCGame项目的实际实现，适用于Friflo ECS 3.4.2版本。*
# Friflo ECS API 详细规范

## 概述

本文档详细描述了Friflo.Engine.ECS 3.4.2框架在MCGame项目中的API规范，包括所有核心组件、系统、实体管理和查询系统的完整接口说明。

## 目录

1. [核心API](#核心api)
2. [组件API](#组件api)
3. [系统API](#系统api)
4. [实体管理API](#实体管理api)
5. [查询系统API](#查询系统api)
6. [管理API](#管理api)
7. [渲染API](#渲染api)
8. [性能API](#性能api)

## 核心API

### EntityStore

#### 概述
EntityStore是ECS系统的核心容器，负责管理所有实体和组件的存储和生命周期。

#### 命名空间
`Friflo.Engine.ECS`

#### 类定义
```csharp
public class EntityStore : IDisposable
{
    // 核心属性和方法
}
```

#### 构造函数
```csharp
public EntityStore()
{
    // 创建新的实体存储
}
```

#### 属性
| 属性名 | 类型 | 描述 |
|--------|------|------|
| Count | int | 存储中的实体总数 |
| Capacity | int | 存储容量 |
| Archetypes | Archetype[] | 所有原型数组 |

#### 方法

##### CreateEntity
```csharp
public Entity CreateEntity(params IComponent[] components)
{
    // 创建包含指定组件的新实体
}
```

**参数:**
- `components` (IComponent[]): 要添加到实体的组件数组

**返回值:**
- Entity: 新创建的实体

**示例:**
```csharp
var entity = store.CreateEntity(
    new Position(0, 64, 0),
    new Rotation(0, 0, 0),
    new Player()
);
```

##### DeleteEntity
```csharp
public void DeleteEntity(Entity entity)
{
    // 删除指定实体
}
```

**参数:**
- `entity` (Entity): 要删除的实体

##### Query<T>
```csharp
public ArchetypeQuery Query<T>() where T : IComponent
{
    // 创建包含指定组件的查询
}
```

**类型参数:**
- T: 要查询的组件类型

**返回值:**
- ArchetypeQuery: 查询对象

##### DeleteAllEntities
```csharp
public void DeleteAllEntities()
{
    // 删除所有实体
}
```

##### Dispose
```csharp
public void Dispose()
{
    // 释放资源
}
```

### SystemRoot

#### 概述
SystemRoot是所有ECS系统的容器，负责系统的执行顺序和生命周期管理。

#### 命名空间
`Friflo.Engine.ECS.Systems`

#### 类定义
```csharp
public class SystemRoot : IDisposable
{
    // 系统管理功能
}
```

#### 构造函数
```csharp
public SystemRoot(EntityStore store)
{
    // 创建系统根节点
}
```

**参数:**
- `store` (EntityStore): 关联的实体存储

#### 方法

##### Add
```csharp
public void Add(SystemBase system)
{
    // 添加系统到执行序列
}
```

**参数:**
- `system` (SystemBase): 要添加的系统

##### Update
```csharp
public void Update(GameTime gameTime)
{
    // 更新所有系统
}
```

**参数:**
- `gameTime` (GameTime): 游戏时间

##### SetMonitorPerf
```csharp
public void SetMonitorPerf(bool enabled)
{
    // 启用或禁用性能监控
}
```

**参数:**
- `enabled` (bool): 是否启用性能监控

##### GetPerfLog
```csharp
public string GetPerfLog()
{
    // 获取性能日志
}
```

**返回值:**
- string: 性能日志字符串

##### Dispose
```csharp
public void Dispose()
{
    // 释放资源
}
```

### ArchetypeQuery

#### 概述
ArchetypeQuery提供高效的实体查询功能，基于原型架构优化查询性能。

#### 命名空间
`Friflo.Engine.ECS`

#### 类定义
```csharp
public class ArchetypeQuery
{
    // 查询功能
}
```

#### 属性
| 属性名 | 类型 | 描述 |
|--------|------|------|
| Entities | Entity[] | 查询结果实体数组 |
| EntityCount | int | 实体数量 |

#### 方法

##### ForEachEntity
```csharp
public void ForEachEntity<T1, T2>(Action<ref T1, ref T2, Entity> action)
    where T1 : IComponent where T2 : IComponent
{
    // 遍历包含指定组件的实体
}
```

**类型参数:**
- T1, T2: 组件类型

**参数:**
- `action` (Action<ref T1, ref T2, Entity>): 处理每个实体的委托

**示例:**
```csharp
var query = store.Query<Position, Velocity>();
query.ForEachEntity((
    ref Position position, 
    ref Velocity velocity, 
    Entity entity) =>
{
    position.Value += velocity.Value * deltaTime;
});
```

## 组件API

### Position

#### 概述
Position组件存储实体的3D世界坐标。

#### 命名空间
`MCGame.ECS.Components`

#### 结构定义
```csharp
public struct Position : IComponent
{
    public Vector3 Value;
    
    public Position(Vector3 value) => Value = value;
    public Position(float x, float y, float z) => Value = new Vector3(x, y, z);
}
```

#### 属性
| 属性名 | 类型 | 描述 |
|--------|------|------|
| Value | Vector3 | 3D位置向量 |

#### 示例
```csharp
// 创建位置组件
var position = new Position(10, 64, 20);

// 访问位置值
var x = position.Value.X;
var y = position.Value.Y;
var z = position.Value.Z;
```

### Rotation

#### 概述
Rotation组件存储实体的旋转角度（欧拉角）。

#### 命名空间
`MCGame.ECS.Components`

#### 结构定义
```csharp
public struct Rotation : IComponent
{
    public Vector3 Value; // Yaw, Pitch, Roll
    
    public Rotation(Vector3 value) => Value = value;
    public Rotation(float yaw, float pitch, float roll) => Value = new Vector3(yaw, pitch, roll);
}
```

#### 属性
| 属性名 | 类型 | 描述 |
|--------|------|------|
| Value | Vector3 | 旋转角度（弧度） |

#### 示例
```csharp
// 创建旋转组件
var rotation = new Rotation(0, MathHelper.PiOver4, 0);

// 访问旋转值
var yaw = rotation.Value.Y;
var pitch = rotation.Value.X;
var roll = rotation.Value.Z;
```

### Block

#### 概述
Block组件表示方块实体的类型和属性。

#### 命名空间
`MCGame.ECS.Components`

#### 结构定义
```csharp
public struct Block : IComponent
{
    public BlockType Type;
    public BlockData Data;
    
    public Block(BlockType type) => (Type, Data) = (type, new BlockData(type));
}
```

#### 属性
| 属性名 | 类型 | 描述 |
|--------|------|------|
| Type | BlockType | 方块类型 |
| Data | BlockData | 方块数据 |

#### 示例
```csharp
// 创建方块组件
var block = new Block(BlockType.Grass);

// 访问方块类型
var blockType = block.Type;
```

### Chunk

#### 概述
Chunk组件表示区块的位置和状态信息。

#### 命名空间
`MCGame.ECS.Components`

#### 结构定义
```csharp
public struct Chunk : IComponent
{
    public ChunkPosition Position;
    public ChunkState State;
    public bool IsDirty;
    public bool IsLoaded;
    public bool IsMeshGenerated;
    
    public Chunk(ChunkPosition position) => Position = position;
}
```

#### 属性
| 属性名 | 类型 | 描述 |
|--------|------|------|
| Position | ChunkPosition | 区块坐标 |
| State | ChunkState | 区块状态 |
| IsDirty | bool | 是否需要重新生成网格 |
| IsLoaded | bool | 是否已加载 |
| IsMeshGenerated | bool | 是否已生成网格 |

#### 示例
```csharp
// 创建区块组件
var chunk = new Chunk(new ChunkPosition(0, 0));

// 检查区块状态
if (chunk.IsLoaded)
{
    // 处理已加载的区块
}
```

### Player

#### 概述
Player组件标记实体为玩家并存储玩家相关属性。

#### 命名空间
`MCGame.ECS.Components`

#### 结构定义
```csharp
public struct Player : IComponent
{
    public float MoveSpeed;
    public float LookSpeed;
    public float JumpSpeed;
    public bool IsGrounded;
    public bool IsFlying;
    
    public Player(float moveSpeed = 10f, float lookSpeed = 0.1f, float jumpSpeed = 8f)
    {
        MoveSpeed = moveSpeed;
        LookSpeed = lookSpeed;
        JumpSpeed = jumpSpeed;
        IsGrounded = false;
        IsFlying = false;
    }
}
```

#### 属性
| 属性名 | 类型 | 描述 |
|--------|------|------|
| MoveSpeed | float | 移动速度 |
| LookSpeed | float | 视角转动速度 |
| JumpSpeed | float | 跳跃速度 |
| IsGrounded | bool | 是否在地面上 |
| IsFlying | bool | 是否在飞行模式 |

#### 示例
```csharp
// 创建玩家组件
var player = new Player(10f, 0.1f, 8f);

// 设置飞行模式
player.IsFlying = true;
```

### Camera

#### 概述
Camera组件存储相机的投影和视图矩阵。

#### 命名空间
`MCGame.ECS.Components`

#### 结构定义
```csharp
public struct Camera : IComponent
{
    public Matrix ViewMatrix;
    public Matrix ProjectionMatrix;
    public float FieldOfView;
    public float AspectRatio;
    public float NearPlane;
    public float FarPlane;
    public bool IsDirty;
    
    public Camera(float fieldOfView = 75f, float aspectRatio = 16f/9f, float nearPlane = 0.1f, float farPlane = 1000f)
    {
        FieldOfView = fieldOfView;
        AspectRatio = aspectRatio;
        NearPlane = nearPlane;
        FarPlane = farPlane;
        IsDirty = true;
        ViewMatrix = Matrix.Identity;
        ProjectionMatrix = Matrix.Identity;
    }
}
```

#### 属性
| 属性名 | 类型 | 描述 |
|--------|------|------|
| ViewMatrix | Matrix | 视图矩阵 |
| ProjectionMatrix | Matrix | 投影矩阵 |
| FieldOfView | float | 视野角度 |
| AspectRatio | float | 宽高比 |
| NearPlane | float | 近裁剪面 |
| FarPlane | float | 远裁剪面 |
| IsDirty | bool | 是否需要更新矩阵 |

#### 示例
```csharp
// 创建相机组件
var camera = new Camera(75f, 16f/9f, 0.1f, 1000f);

// 标记需要更新
camera.IsDirty = true;
```

## 系统API

### PlayerInputSystem

#### 概述
PlayerInputSystem处理键盘和鼠标输入，更新输入组件。

#### 命名空间
`MCGame.ECS.Systems`

#### 类定义
```csharp
public class PlayerInputSystem : QuerySystem<Input>
{
    // 输入处理逻辑
}
```

#### 继承
- QuerySystem<Input>: 查询包含Input组件的实体

#### 方法

##### OnUpdate
```csharp
protected override void OnUpdate()
{
    // 更新输入状态
}
```

#### 功能特点
- **处理输入**: 键盘WASD移动，鼠标视角控制
- **输入状态**: 跳跃、冲刺、飞行模式切换
- **性能优化**: 使用QuerySystem批量处理

#### 示例
```csharp
// 系统自动处理输入
var inputSystem = new PlayerInputSystem();
systemRoot.Add(inputSystem);
```

### PlayerMovementSystem

#### 概述
PlayerMovementSystem根据输入更新玩家位置和速度。

#### 命名空间
`MCGame.ECS.Systems`

#### 类定义
```csharp
public class PlayerMovementSystem : QuerySystem<Position, Rotation, Velocity, Input, Player>
{
    // 移动处理逻辑
}
```

#### 继承
- QuerySystem<Position, Rotation, Velocity, Input, Player>: 查询包含这些组件的实体

#### 方法

##### OnUpdate
```csharp
protected override void OnUpdate()
{
    // 更新玩家移动
}
```

#### 功能特点
- **移动控制**: 基于输入向量计算移动方向
- **旋转控制**: 更新玩家视角
- **特殊移动**: 跳跃、冲刺、飞行模式

#### 示例
```csharp
// 系统自动处理移动
var movementSystem = new PlayerMovementSystem();
systemRoot.Add(movementSystem);
```

### PhysicsSystem

#### 概述
PhysicsSystem应用重力、碰撞检测和物理模拟。

#### 命名空间
`MCGame.ECS.Systems`

#### 类定义
```csharp
public class PhysicsSystem : QuerySystem<Position, Velocity>
{
    // 物理处理逻辑
}
```

#### 继承
- QuerySystem<Position, Velocity>: 查询包含位置和速度组件的实体

#### 方法

##### OnUpdate
```csharp
protected override void OnUpdate()
{
    // 应用物理效果
}
```

#### 功能特点
- **重力应用**: 向下的重力加速度
- **碰撞检测**: 地面和障碍物碰撞
- **速度衰减**: 空气阻力效果

#### 示例
```csharp
// 系统自动处理物理
var physicsSystem = new PhysicsSystem();
systemRoot.Add(physicsSystem);
```

## 实体管理API

### ECSWorld

#### 概述
ECSWorld是ECS系统的主管理器，协调所有ECS组件的工作。

#### 命名空间
`MCGame.ECS`

#### 类定义
```csharp
public class ECSWorld
{
    private readonly EntityStore _store;
    private readonly SystemRoot _systemRoot;
    private readonly ArchetypeQuery _chunkQuery;
    private readonly ArchetypeQuery _blockQuery;
    private readonly ArchetypeQuery _playerQuery;
    
    // 系统引用
    private readonly PlayerInputSystem _inputSystem;
    private readonly PlayerMovementSystem _movementSystem;
    private readonly PhysicsSystem _physicsSystem;
    private readonly CameraSystem _cameraSystem;
    private readonly VisibilitySystem _visibilitySystem;
    private readonly ChunkStateSystem _chunkSystem;
}
```

#### 构造函数
```csharp
public ECSWorld()
{
    // 初始化ECS世界
}
```

#### 属性
| 属性名 | 类型 | 描述 |
|--------|------|------|
| Store | EntityStore | 实体存储 |
| PlayerEntity | Entity | 玩家实体 |

#### 方法

##### CreateChunkEntity
```csharp
public Entity CreateChunkEntity(ChunkPosition position)
{
    // 创建区块实体
}
```

**参数:**
- `position` (ChunkPosition): 区块位置

**返回值:**
- Entity: 创建的区块实体

##### CreateBlockEntity
```csharp
public Entity CreateBlockEntity(BlockType blockType, Vector3 position)
{
    // 创建方块实体
}
```

**参数:**
- `blockType` (BlockType): 方块类型
- `position` (Vector3): 方块位置

**返回值:**
- Entity: 创建的方块实体

##### CreateBlockEntitiesBatch
```csharp
public Entity[] CreateBlockEntitiesBatch(BlockType[] blockTypes, Vector3[] positions)
{
    // 批量创建方块实体
}
```

**参数:**
- `blockTypes` (BlockType[]): 方块类型数组
- `positions` (Vector3[]): 位置数组

**返回值:**
- Entity[]: 创建的实体数组

##### Update
```csharp
public void Update(GameTime gameTime)
{
    // 更新世界
}
```

**参数:**
- `gameTime` (GameTime): 游戏时间

##### GetPerformanceStats
```csharp
public string GetPerformanceStats()
{
    // 获取性能统计
}
```

**返回值:**
- string: 性能统计字符串

#### 示例
```csharp
// 创建ECS世界
var ecsWorld = new ECSWorld();

// 创建实体
var chunk = ecsWorld.CreateChunkEntity(new ChunkPosition(0, 0));
var block = ecsWorld.CreateBlockEntity(BlockType.Grass, new Vector3(10, 64, 20));

// 更新世界
ecsWorld.Update(gameTime);
```

## 查询系统API

### ArchetypeQuery 高级用法

#### 概述
ArchetypeQuery提供了多种查询和过滤方式，可以根据不同需求选择合适的查询方法。

#### 多组件查询
```csharp
// 查询包含多个组件的实体
var query = store.Query<Position, Velocity, Player>();
query.ForEachEntity((
    ref Position position, 
    ref Velocity velocity, 
    ref Player player, 
    Entity entity) =>
{
    // 处理逻辑
});
```

#### 条件查询
```csharp
// 带条件的查询
var query = store.Query<Position, Visibility>();
query.ForEachEntity((
    ref Position position, 
    ref Visibility visibility, 
    Entity entity) =>
{
    // 只处理可见的实体
    if (visibility.IsVisible)
    {
        // 处理逻辑
    }
});
```

#### 距离查询
```csharp
// 基于距离的查询
var cameraPosition = new Vector3(0, 64, 0);
var query = store.Query<Position>();
var nearbyEntities = new List<Entity>();

query.ForEachEntity((
    ref Position position, 
    Entity entity) =>
{
    var distance = Vector3.Distance(position.Value, cameraPosition);
    if (distance < 50f) // 50单位范围内
    {
        nearbyEntities.Add(entity);
    }
});
```

## 渲染API

### ECSRenderer

#### 概述
ECSRenderer将ECS实体与MonoGame渲染系统集成，负责渲染所有可见实体。

#### 命名空间
`MCGame.ECS.Rendering`

#### 类定义
```csharp
public class ECSRenderer : IDisposable
{
    private readonly GraphicsDevice _graphicsDevice;
    private readonly BasicEffect _basicEffect;
    private readonly Dictionary<BlockType, VertexBuffer> _blockVertexBuffers;
    private readonly Dictionary<BlockType, IndexBuffer> _blockIndexBuffers;
}
```

#### 构造函数
```csharp
public ECSRenderer(GraphicsDevice graphicsDevice)
{
    // 初始化渲染器
}
```

#### 方法

##### RenderVisibleEntities
```csharp
public void RenderVisibleEntities(ArchetypeQuery blockQuery, ArchetypeQuery chunkQuery, Matrix viewMatrix, Matrix projectionMatrix)
{
    // 渲染所有可见实体
}
```

**参数:**
- `blockQuery` (ArchetypeQuery): 方块查询
- `chunkQuery` (ArchetypeQuery): 区块查询
- `viewMatrix` (Matrix): 视图矩阵
- `projectionMatrix` (Matrix): 投影矩阵

#### 示例
```csharp
// 创建渲染器
var renderer = new ECSRenderer(graphicsDevice);

// 渲染实体
renderer.RenderVisibleEntities(
    ecsWorld.Store.Query<Block>(),
    ecsWorld.Store.Query<Chunk>(),
    viewMatrix,
    projectionMatrix
);
```

## 性能API

### 性能监控

#### 系统性能监控
```csharp
// 启用性能监控
systemRoot.SetMonitorPerf(true);

// 获取性能日志
var perfLog = systemRoot.GetPerfLog();

// 解析性能数据
var lines = perfLog.Split('\n');
foreach (var line in lines)
{
    if (line.Contains("System:"))
    {
        // 分析系统性能
    }
}
```

#### 实体统计
```csharp
// 获取实体统计
var stats = ecsWorld.GetEntityStats();

// 显示统计信息
Console.WriteLine($"总实体数: {stats.TotalEntities}");
Console.WriteLine($"区块实体: {stats.ChunkEntities}");
Console.WriteLine($"方块实体: {stats.BlockEntities}");
Console.WriteLine($"玩家实体: {stats.PlayerEntities}");
```

### 性能优化建议

#### 查询优化
```csharp
// 好的做法：重用查询对象
private readonly ArchetypeQuery _blockQuery;

public void Initialize()
{
    _blockQuery = store.Query<Block>();
}

public void Update()
{
    // 使用缓存的查询
    _blockQuery.ForEachEntity(...);
}
```

#### 批量处理
```csharp
// 批量创建实体
public Entity[] CreateEntitiesBatch(int count)
{
    var entities = new Entity[count];
    for (int i = 0; i < count; i++)
    {
        entities[i] = store.CreateEntity(
            new Position(i, 0, 0),
            new Block(BlockType.Stone)
        );
    }
    return entities;
}
```

## 错误处理

### 常见错误

#### 组件缺失错误
```csharp
// 错误的处理方式
try
{
    var position = entity.GetComponent<Position>();
}
catch (ComponentNotFoundException ex)
{
    Console.WriteLine($"组件缺失: {ex.Message}");
}

// 正确的处理方式
if (entity.TryGetComponent<Position>(out var position))
{
    // 安全使用组件
}
```

#### 实体已删除错误
```csharp
// 检查实体是否有效
if (entity.IsNull)
{
    Console.WriteLine("实体已被删除");
    return;
}
```

## 最佳实践

### 组件设计
```csharp
// 好的组件设计：单一职责
public struct Position : IComponent
{
    public Vector3 Value;
}

// 避免的组件设计：职责过多
public struct PlayerData : IComponent
{
    public Vector3 Position;
    public Vector3 Rotation;
    public Vector3 Velocity;
    public float Health;
    public float Mana;
    // 太多职责
}
```

### 系统设计
```csharp
// 好的系统设计：专注单一功能
public class PlayerMovementSystem : QuerySystem<Position, Velocity, Input>
{
    protected override void OnUpdate()
    {
        // 只处理移动逻辑
    }
}

// 避免的系统设计：功能混杂
public class PlayerSystem : QuerySystem<Position, Velocity, Input, Health, Mana>
{
    protected override void OnUpdate()
    {
        // 移动、生命值、法力值混合处理
    }
}
```

### 内存管理
```csharp
// 好的做法：及时释放资源
public void Cleanup()
{
    // 删除不需要的实体
    foreach (var entity in _expiredEntities)
    {
        store.DeleteEntity(entity);
    }
    
    // 清理查询缓存
    _queryCache.Clear();
}
```

## 总结

本文档提供了Friflo ECS在MCGame项目中的完整API规范，涵盖了从基础概念到高级特性的所有方面。通过遵循这些API规范，开发者可以高效地使用ECS系统来构建复杂的游戏功能。

### 关键特性
- **高性能**: 基于原型架构的优化查询
- **类型安全**: 强类型组件系统
- **易于扩展**: 支持自定义组件和系统
- **内存友好**: 高效的内存管理
- **调试友好**: 完整的性能监控工具

### 适用场景
- **体素游戏**: 方块和区块的高效管理
- **实体管理**: 大量实体的批量处理
- **物理模拟**: 实时物理计算
- **AI系统**: 复杂的行为逻辑
- **网络同步**: 客户端-服务器状态同步

通过合理使用这些API，开发者可以构建出高性能、可维护的游戏系统。
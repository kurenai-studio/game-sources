# Friflo ECS 组件API详解

## 概述

本文档详细介绍MCGame项目中使用的所有ECS组件，包括组件定义、使用方法、性能特性和最佳实践。所有组件都基于Friflo ECS 3.4.2的`IComponent`接口实现。

## 目录

- [核心组件](#核心组件)
- [渲染组件](#渲染组件)
- [物理组件](#物理组件)
- [游戏逻辑组件](#游戏逻辑组件)
- [组件设计模式](#组件设计模式)
- [性能优化](#性能优化)
- [错误处理](#错误处理)

## 核心组件

### Position - 位置组件

```csharp
/// <summary>
/// 位置组件
/// 存储实体的3D世界坐标
/// 简化实现：使用Vector3直接存储，避免不必要的计算
/// </summary>
public struct Position : IComponent
{
    public Vector3 Value;
    
    public Position(Vector3 value) => Value = value;
    public Position(float x, float y, float z) => Value = new Vector3(x, y, z);
}
```

**使用方法：**

```csharp
// 创建位置组件
var position = new Position(10, 64, 20);

// 设置位置
position.Value = new Vector3(15, 70, 25);

// 获取位置
Vector3 pos = position.Value;

// 计算距离
float distance = Vector3.Distance(position.Value, targetPosition);
```

**性能特性：**
- 内存占用：12字节（Vector3）
- 访问速度：O(1)
- 缓存友好：连续内存布局

### Rotation - 旋转组件

```csharp
/// <summary>
/// 旋转组件
/// 存储实体的旋转角度（欧拉角）
/// 简化实现：使用欧拉角而非四元数，减少计算复杂度
/// </summary>
public struct Rotation : IComponent
{
    public Vector3 Value; // Yaw, Pitch, Roll
    
    public Rotation(Vector3 value) => Value = value;
    public Rotation(float yaw, float pitch, float roll) => Value = new Vector3(yaw, pitch, roll);
}
```

**使用方法：**

```csharp
// 创建旋转组件
var rotation = new Rotation(0, 0, 0);

// 更新旋转（第一人称视角）
rotation.Value.Y += input.Look.X * lookSpeed;  // Yaw
rotation.Value.X += input.Look.Y * lookSpeed;  // Pitch

// 限制俯仰角
rotation.Value.X = MathHelper.Clamp(rotation.Value.X, -MathHelper.PiOver2, MathHelper.PiOver2);

// 获取前方向量
var yaw = rotation.Value.Y;
var forward = new Vector3((float)Math.Sin(yaw), 0, (float)Math.Cos(yaw));
```

**性能特性：**
- 内存占用：12字节（Vector3）
- 计算复杂度：O(1)
- 适用场景：第一人称/第三人称视角

### Velocity - 速度组件

```csharp
/// <summary>
/// 速度组件
/// 存储实体的移动速度
/// 简化实现：直接存储速度向量，简化物理计算
/// </summary>
public struct Velocity : IComponent
{
    public Vector3 Value;
    
    public Velocity(Vector3 value) => Value = value;
    public Velocity(float x, float y, float z) => Value = new Vector3(x, y, z);
}
```

**使用方法：**

```csharp
// 创建速度组件
var velocity = new Velocity(0, 0, 0);

// 设置速度
velocity.Value = new Vector3(5, 0, 3);

// 应用重力
velocity.Value.Y += gravity * deltaTime;

// 应用摩擦力
velocity.Value *= 0.95f;

// 更新位置
position.Value += velocity.Value * deltaTime;
```

**性能特性：**
- 内存占用：12字节（Vector3）
- 计算复杂度：O(1)
- 适用场景：物理模拟、移动控制

## 渲染组件

### Visibility - 可见性组件

```csharp
/// <summary>
/// 可见性组件
/// 存储实体的可见性状态
/// 简化实现：简单的布尔值 + 距离计算，避免复杂视锥体剔除
/// </summary>
public struct Visibility : IComponent
{
    public bool IsVisible;
    public float Distance;
    public bool InFrustum;
    
    public Visibility(bool isVisible = true) => IsVisible = isVisible;
}
```

**使用方法：**

```csharp
// 创建可见性组件
var visibility = new Visibility(true);

// 更新可见性
visibility.IsVisible = distance < renderDistance;
visibility.Distance = distance;
visibility.InFrustum = frustum.Contains(bounds);

// 检查是否应该渲染
if (visibility.IsVisible && visibility.InFrustum)
{
    // 渲染实体
}
```

**性能特性：**
- 内存占用：9字节（bool + float + bool）
- 计算复杂度：O(1)
- 优化策略：结合距离剔除和视锥体剔除

### Mesh - 网格组件

```csharp
/// <summary>
/// 网格组件
/// 存储实体的网格渲染数据
/// 简化实现：仅存储基本网格信息，不包含复杂的网格数据
/// </summary>
public struct Mesh : IComponent
{
    public bool IsDirty;
    public int VertexCount;
    public int IndexCount;
    public BoundingBox Bounds;
    
    public Mesh(BoundingBox bounds) => Bounds = bounds;
}
```

**使用方法：**

```csharp
// 创建网格组件
var mesh = new Mesh(bounds);

// 标记需要重新生成网格
mesh.IsDirty = true;

// 更新网格数据
mesh.VertexCount = vertexArray.Length;
mesh.IndexCount = indexArray.Length;
mesh.Bounds = CalculateBounds();

// 检查是否需要更新
if (mesh.IsDirty)
{
    GenerateMesh();
    mesh.IsDirty = false;
}
```

**性能特性：**
- 内存占用：21字节（bool + int + int + BoundingBox）
- 计算复杂度：O(1)
- 优化策略：脏标记机制，避免不必要的网格更新

### Lighting - 光照组件

```csharp
/// <summary>
/// 光照组件
/// 存储实体的光照信息
/// 简化实现：使用简单的亮度值，而非复杂的光照计算
/// </summary>
public struct Lighting : IComponent
{
    public byte Brightness;
    public byte Sunlight;
    public byte Torchlight;
    public Color TintColor;
    
    public Lighting(byte brightness = 15) => Brightness = brightness;
}
```

**使用方法：**

```csharp
// 创建光照组件
var lighting = new Lighting(15);

// 设置光照强度
lighting.Brightness = 12;
lighting.Sunlight = 15;
lighting.Torchlight = 8;

// 计算最终颜色
float brightness = lighting.Brightness / 15f;
var finalColor = lighting.TintColor * brightness;

// 应用于渲染
effect.DiffuseColor = finalColor.ToVector3();
```

**性能特性：**
- 内存占用：7字节（3字节 + Color）
- 计算复杂度：O(1)
- 优化策略：使用字节存储光照值，减少内存占用

## 物理组件

### Collider - 碰撞体组件

```csharp
/// <summary>
/// 碰撞体组件
/// 存储实体的碰撞检测信息
/// 简化实现：使用AABB包围盒，而非复杂的碰撞形状
/// </summary>
public struct Collider : IComponent
{
    public BoundingBox Bounds;
    public bool IsSolid;
    public bool IsTrigger;
    
    public Collider(BoundingBox bounds, bool isSolid = true)
    {
        Bounds = bounds;
        IsSolid = isSolid;
        IsTrigger = false;
    }
}
```

**使用方法：**

```csharp
// 创建碰撞体组件
var collider = new Collider(bounds, true);

// 检查碰撞
if (collider.IsSolid && otherCollider.Bounds.Intersects(collider.Bounds))
{
    // 处理碰撞
    ResolveCollision();
}

// 射线检测
var ray = new Ray(origin, direction);
if (collider.Bounds.Intersects(ray))
{
    // 命中碰撞体
    return true;
}

// 设置为触发器
collider.IsTrigger = true;
collider.IsSolid = false;
```

**性能特性：**
- 内存占用：26字节（BoundingBox + 2字节）
- 计算复杂度：O(1) for AABB intersection
- 优化策略：AABB碰撞检测，性能优于复杂形状

### Physics - 物理组件

```csharp
/// <summary>
/// 物理组件
/// 存储实体的物理属性
/// 简化实现：基础物理属性，不支持复杂的物理模拟
/// </summary>
public struct Physics : IComponent
{
    public float Mass;
    public float Drag;
    public float Bounciness;
    public Vector3 Gravity;
    
    public Physics(float mass = 1f, float drag = 0.1f)
    {
        Mass = mass;
        Drag = drag;
        Bounciness = 0f;
        Gravity = new Vector3(0, -9.81f, 0);
    }
}
```

**使用方法：**

```csharp
// 创建物理组件
var physics = new Physics(1f, 0.1f);

// 应用重力
velocity.Value += physics.Gravity * deltaTime;

// 应用阻力
velocity.Value *= (1f - physics.Drag * deltaTime);

// 计算弹跳
if (isGrounded && velocity.Value.Y < 0)
{
    velocity.Value.Y *= -physics.Bounciness;
}

// 获取质量
float mass = physics.Mass;
```

**性能特性：**
- 内存占用：28字节（3×float + Vector3）
- 计算复杂度：O(1)
- 优化策略：简化的物理计算，适合游戏开发

## 游戏逻辑组件

### Block - 方块组件

```csharp
/// <summary>
/// 方块组件
/// 存储方块实体的类型和属性
/// 简化实现：仅存储基本方块信息，不包含复杂的方块状态
/// </summary>
public struct Block : IComponent
{
    public BlockType Type;
    public BlockData Data;
    
    public Block(BlockType type) => (Type, Data) = (type, new BlockData(type));
}
```

**使用方法：**

```csharp
// 创建方块组件
var block = new Block(BlockType.Grass);

// 获取方块类型
BlockType type = block.Type;

// 获取方块数据
BlockData data = block.Data;

// 检查方块属性
if (block.Data.IsSolid)
{
    // 实心方块
}

if (block.Data.IsTransparent)
{
    // 透明方块
}
```

**性能特性：**
- 内存占用：取决于BlockType和BlockData的大小
- 计算复杂度：O(1)
- 优化策略：使用枚举而非字符串存储方块类型

### Chunk - 区块组件

```csharp
/// <summary>
/// 区块组件
/// 存储区块的位置和状态信息
/// 简化实现：简化状态管理，专注于基本的区块功能
/// </summary>
public struct Chunk : IComponent
{
    public ChunkPosition Position;
    public ChunkState State;
    public bool IsDirty;
    public bool IsLoaded;
    public bool IsMeshGenerated;
    
    public Chunk(ChunkPosition position) => Position = position;
}

/// <summary>
/// 区块状态枚举
/// </summary>
public enum ChunkState
{
    Unloaded,
    Loading,
    Loaded,
    Generating,
    Meshing,
    Unloading
}
```

**使用方法：**

```csharp
// 创建区块组件
var chunk = new Chunk(new ChunkPosition(0, 0));

// 设置区块状态
chunk.State = ChunkState.Loading;
chunk.IsDirty = true;

// 检查区块状态
if (chunk.State == ChunkState.Loaded && chunk.IsDirty)
{
    // 需要更新区块
    UpdateChunk();
}

// 标记为已加载
chunk.IsLoaded = true;
chunk.State = ChunkState.Loaded;
```

**性能特性：**
- 内存占用：约20字节（取决于ChunkPosition）
- 计算复杂度：O(1)
- 优化策略：状态枚举，减少内存占用

### Player - 玩家组件

```csharp
/// <summary>
/// 玩家组件
/// 标记实体为玩家
/// 简化实现：包含基本的玩家属性，不支持复杂的玩家系统
/// </summary>
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

**使用方法：**

```csharp
// 创建玩家组件
var player = new Player(10f, 0.1f, 8f);

// 设置移动速度
float speed = player.MoveSpeed;
if (player.IsFlying)
{
    speed *= 2f; // 飞行模式加速
}

// 处理跳跃
if (input.Jump && player.IsGrounded && !player.IsFlying)
{
    velocity.Value.Y = player.JumpSpeed;
    player.IsGrounded = false;
}

// 切换飞行模式
if (input.Fly)
{
    player.IsFlying = !player.IsFlying;
}
```

**性能特性：**
- 内存占用：21字节（4×float + 2×bool）
- 计算复杂度：O(1)
- 优化策略：使用基本数据类型，避免复杂计算

### Camera - 相机组件

```csharp
/// <summary>
/// 相机组件
/// 存储相机的投影和视图矩阵
/// 简化实现：基础的相机功能，不支持高级相机效果
/// </summary>
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

**使用方法：**

```csharp
// 创建相机组件
var camera = new Camera(75f, 16f/9f, 0.1f, 1000f);

// 更新相机矩阵
if (camera.IsDirty)
{
    camera.ViewMatrix = Matrix.CreateLookAt(position, position + forward, up);
    camera.ProjectionMatrix = Matrix.CreatePerspectiveFieldOfView(
        MathHelper.ToRadians(camera.FieldOfView),
        camera.AspectRatio,
        camera.NearPlane,
        camera.FarPlane
    );
    camera.IsDirty = false;
}

// 应用于渲染
effect.View = camera.ViewMatrix;
effect.Projection = camera.ProjectionMatrix;
```

**性能特性：**
- 内存占用：108字节（2×Matrix + 4×float + bool）
- 计算复杂度：O(1)
- 优化策略：脏标记机制，避免不必要的矩阵计算

### Input - 输入组件

```csharp
/// <summary>
/// 输入组件
/// 存储实体的输入状态
/// 简化实现：基本的输入状态，不支持复杂的输入映射
/// </summary>
public struct Input : IComponent
{
    public Vector2 Movement;
    public Vector2 Look;
    public bool Jump;
    public bool Sprint;
    public bool Fly;
    
    public Input()
    {
        Movement = Vector2.Zero;
        Look = Vector2.Zero;
        Jump = false;
        Sprint = false;
        Fly = false;
    }
}
```

**使用方法：**

```csharp
// 创建输入组件
var input = new Input();

// 更新输入状态
input.Movement = new Vector2(
    keyboard.IsKeyDown(Keys.D) ? 1 : keyboard.IsKeyDown(Keys.A) ? -1 : 0,
    keyboard.IsKeyDown(Keys.W) ? 1 : keyboard.IsKeyDown(Keys.S) ? -1 : 0
);

input.Look = new Vector2(
    mouse.X - previousMouse.X,
    mouse.Y - previousMouse.Y
);

input.Jump = keyboard.IsKeyDown(Keys.Space);
input.Sprint = keyboard.IsKeyDown(Keys.LeftShift);
input.Fly = keyboard.IsKeyDown(Keys.F);
```

**性能特性：**
- 内存占用：22字节（2×Vector2 + 3×bool）
- 计算复杂度：O(1)
- 优化策略：使用Vector2存储方向输入，减少内存占用

### Lifetime - 生命期组件

```csharp
/// <summary>
/// 生命期组件
/// 存储实体的生命期信息
/// 简化实现：简单的生命期管理，不支持复杂的生命期逻辑
/// </summary>
public struct Lifetime : IComponent
{
    public float TimeLeft;
    public bool IsExpired;
    
    public Lifetime(float timeLeft)
    {
        TimeLeft = timeLeft;
        IsExpired = false;
    }
}
```

**使用方法：**

```csharp
// 创建生命期组件
var lifetime = new Lifetime(5f); // 5秒生命期

// 更新生命期
lifetime.TimeLeft -= deltaTime;
if (lifetime.TimeLeft <= 0)
{
    lifetime.IsExpired = true;
}

// 检查是否过期
if (lifetime.IsExpired)
{
    entity.Delete();
}
```

**性能特性：**
- 内存占用：8字节（float + bool）
- 计算复杂度：O(1)
- 优化策略：简单的递减逻辑，性能高效

## 组件设计模式

### 组件组合模式

```csharp
// 创建玩家实体（组合多个组件）
var playerEntity = store.CreateEntity(
    new Position(0, 64, 0),
    new Rotation(0, 0, 0),
    new Velocity(0, 0, 0),
    new Player(10f, 0.1f, 8f),
    new Camera(75f, 16f/9f, 0.1f, 1000f),
    new Input(),
    new Physics(1f, 0.1f),
    new Collider(playerBounds),
    new Visibility(true)
);

// 创建方块实体（简单组合）
var blockEntity = store.CreateEntity(
    new Block(BlockType.Grass),
    new Position(position),
    new Visibility(true),
    new Collider(blockBounds),
    new Lighting(15)
);
```

### 组件查询模式

```csharp
// 查询具有特定组件的实体
var playerQuery = store.Query<Player, Position, Velocity>();
var blockQuery = store.Query<Block, Position, Visibility>();

// 处理查询结果
foreach (var entity in playerQuery.Entities)
{
    var player = entity.GetComponent<Player>();
    var position = entity.GetComponent<Position>();
    var velocity = entity.GetComponent<Velocity>();
    
    // 处理玩家逻辑
}
```

### 组件标签模式

```csharp
// 使用空组件作为标签
public struct PlayerTag : IComponent { }
public struct EnemyTag : IComponent { }
public struct ProjectileTag : IComponent { }

// 添加标签
entity.AddComponent<PlayerTag>();

// 查询带有标签的实体
var players = store.Query<PlayerTag>();
```

## 性能优化

### 组件布局优化

```csharp
// 好的组件设计：紧凑的内存布局
public struct OptimizedPosition : IComponent
{
    public float X, Y, Z; // 12字节
}

// 避免的组件设计：内存浪费
public struct WastefulPosition : IComponent
{
    public Vector3 Position; // 12字节
    public int Padding1;     // 4字节浪费
    public int Padding2;     // 4字节浪费
}
```

### 批量组件操作

```csharp
// 批量添加组件（高性能）
var commands = store.CreateCommandBuffer();
for (int i = 0; i < entities.Length; i++)
{
    commands.AddComponent(entities[i].Id, new Visibility(true));
}
commands.Playback();

// 避免的：逐个添加组件
for (int i = 0; i < entities.Length; i++)
{
    entities[i].AddComponent(new Visibility(true)); // 性能较差
}
```

### 组件缓存策略

```csharp
// 缓存常用组件引用
private ComponentRef<Position> _positionRef;
private ComponentRef<Velocity> _velocityRef;

public void Initialize(Entity entity)
{
    _positionRef = entity.GetComponentRef<Position>();
    _velocityRef = entity.GetComponentRef<Velocity>();
}

public void Update()
{
    // 使用缓存的组件引用
    _positionRef.Value += _velocityRef.Value * deltaTime;
}
```

## 错误处理

### 组件不存在处理

```csharp
// 安全的组件获取
public void ProcessEntity(Entity entity)
{
    // 方法1：使用TryGetComponent
    if (entity.TryGetComponent<Position>(out var position))
    {
        // 安全处理位置
    }
    
    // 方法2：使用HasComponent检查
    if (entity.HasComponent<Velocity>())
    {
        var velocity = entity.GetComponent<Velocity>();
        // 安全处理速度
    }
    
    // 方法3：异常处理
    try
    {
        var rotation = entity.GetComponent<Rotation>();
        // 处理旋转
    }
    catch (ComponentNotFoundException)
    {
        // 处理组件不存在的情况
    }
}
```

### 组件类型验证

```csharp
// 验证组件类型
public bool ValidateEntity(Entity entity)
{
    // 检查必需组件
    if (!entity.HasComponent<Position>())
        return false;
    
    if (!entity.HasComponent<Visibility>())
        return false;
    
    // 检查组件组合
    if (entity.HasComponent<Player>() && !entity.HasComponent<Input>())
        return false;
    
    return true;
}
```

### 组件数据验证

```csharp
// 验证组件数据
public bool ValidateComponentData(Position position)
{
    // 检查位置是否在合理范围内
    if (float.IsNaN(position.Value.X) || float.IsInfinity(position.Value.X))
        return false;
    
    if (float.IsNaN(position.Value.Y) || float.IsInfinity(position.Value.Y))
        return false;
    
    if (float.IsNaN(position.Value.Z) || float.IsInfinity(position.Value.Z))
        return false;
    
    return true;
}
```

## 总结

MCGame项目中的ECS组件系统采用简洁高效的设计，每个组件都有明确的职责和优化的内存布局。通过合理使用组件组合、查询系统和批量操作，实现了高性能的实体管理。在实际应用中，这些组件成功支持了大量的方块、区块和玩家实体，为游戏提供了良好的性能表现。

**关键优化点：**
- 使用基本数据类型，避免复杂的对象引用
- 实现脏标记机制，减少不必要的计算
- 批量操作组件，提高处理效率
- 缓存查询结果，避免重复查询
- 合理的组件设计，减少内存碎片
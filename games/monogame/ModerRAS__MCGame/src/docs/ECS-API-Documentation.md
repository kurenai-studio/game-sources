# MCGame ECS系统 API文档

## 概述

MCGame的ECS（Entity Component System）系统基于Friflo ECS框架构建，为类Minecraft游戏提供高性能的实体管理和渲染系统。本系统专注于方块、区块和玩家的ECS化管理，集成了多种性能优化技术。

### 系统架构

```
ECS系统架构
├── 核心管理
│   ├── ECSWorld.cs - ECS世界管理器
│   └── EntityStore - 实体存储
├── 组件系统
│   ├── ECSComponents.cs - 所有组件定义
│   └── 组件类型 - 位置、旋转、方块、区块等
├── 系统实现
│   ├── ECSSystems.cs - 游戏逻辑系统
│   ├── RenderingSystem.cs - 渲染系统
│   └── 系统基类 - QuerySystem
├── 管理器
│   ├── ECSBlockManager.cs - 方块管理器
│   ├── ECSChunkManager.cs - 区块管理器
│   └── ECSRenderManager.cs - 渲染管理器
└── 工具类
    ├── ECSObjectPool.cs - 对象池
    ├── QueryCacheManager.cs - 查询缓存
    ├── BatchOperationOptimizer.cs - 批量操作
    └── ECSPerformanceMonitor.cs - 性能监控
```

### 核心特性

- **高性能渲染**: 基于Friflo ECS的QuerySystem实现高效实体查询
- **内存优化**: 使用对象池和16位数据存储减少内存占用
- **批量操作**: 支持批量实体创建、更新和删除
- **查询缓存**: 缓存常用查询结果，避免重复计算
- **性能监控**: 实时监控系统性能指标
- **多线程支持**: 异步区块生成和网格计算

---

## 核心类参考

### ECSWorld

ECS世界管理器，管理ECS实体、组件和系统的生命周期。

#### 构造函数

```csharp
public ECSWorld()
```

创建新的ECS世界实例，自动初始化所有子系统。

#### 主要属性

```csharp
public EntityStore Store { get; }       // 实体存储
public Entity EntityStore { get; }     // 实体存储（兼容性）
public Entity PlayerEntity { get; set; } // 玩家实体
```

#### 主要方法

##### 实体创建

```csharp
// 创建玩家实体
public void CreateDefaultPlayer()

// 创建区块实体
public Entity CreateChunkEntity(ChunkPosition position)

// 创建方块实体
public Entity CreateBlockEntity(BlockType blockType, Vector3 position)

// 批量创建方块实体（性能优化）
public Entity[] CreateBlockEntitiesBatch(BlockType[] blockTypes, Vector3[] positions)
```

**参数说明:**
- `position`: 区块或方块的位置
- `blockType`: 方块类型
- `blockTypes`: 批量创建的方块类型数组
- `positions`: 批量创建的位置数组

**返回值:**
- 单个实体或实体数组

**异常处理:**
- `ArgumentException`: 当数组长度不匹配时抛出

##### 实体查询

```csharp
// 获取区块实体
public Entity GetChunkEntity(ChunkPosition position)

// 获取方块实体
public Entity GetBlockEntity(Vector3 position)

// 获取所有可见区块
public Entity[] GetVisibleChunks()

// 获取所有可见方块
public Entity[] GetVisibleBlocks()

// 获取优化后的可见方块（使用缓存）
public Entity[] GetVisibleBlocksOptimized()

// 获取优化后的可见区块（使用缓存）
public Entity[] GetVisibleChunksOptimized()
```

**性能说明:**
- 优化版本使用查询缓存，性能更好
- 缓存版本在实体数量大时性能提升显著

##### 世界更新

```csharp
// 更新世界
public void Update(GameTime gameTime)

// 设置视锥体
public void SetViewFrustum(BoundingFrustum frustum, Vector3 cameraPosition)

// 销毁世界
public void Destroy()
```

##### 性能监控

```csharp
// 获取性能统计信息
public string GetPerformanceStats()

// 获取优化的性能统计信息
public string GetOptimizedPerformanceStats()

// 获取性能警告
public List<string> GetPerformanceWarnings()

// 重置性能统计
public void ResetPerformanceStats()

// 获取实体统计信息
public EntityStats GetEntityStats()
```

**性能指标:**
- 实体总数、区块数量、方块数量
- 系统更新时间、查询时间
- DrawCall数量、三角形数量
- 内存使用率、缓存命中率

##### 批量操作

```csharp
// 批量处理方块实体
public void ProcessBlocksBatchOptimized(Action<Entity> processAction)

// 批量处理区块实体
public void ProcessChunksBatchOptimized(Action<Entity> processAction)
```

**使用示例:**
```csharp
// 批量更新所有可见方块的光照
ecsWorld.ProcessBlocksBatchOptimized(blockEntity => {
    var lighting = blockEntity.GetComponent<Lighting>();
    lighting.Brightness = CalculateNewBrightness(blockEntity);
});
```

#### 使用示例

```csharp
// 创建ECS世界
var ecsWorld = new ECSWorld();

// 创建玩家
ecsWorld.CreateDefaultPlayer();

// 创建区块
var chunkPos = new ChunkPosition(0, 0, 0);
var chunkEntity = ecsWorld.CreateChunkEntity(chunkPos);

// 创建方块
var blockPos = new Vector3(0, 64, 0);
var blockEntity = ecsWorld.CreateBlockEntity(BlockType.Grass, blockPos);

// 更新世界
ecsWorld.Update(gameTime);

// 获取性能统计
var stats = ecsWorld.GetOptimizedPerformanceStats();
Console.WriteLine(stats);

// 清理资源
ecsWorld.Dispose();
```

---

## 组件API

### 位置组件 (Position)

存储实体的3D世界坐标。

```csharp
public struct Position : IComponent
{
    public Vector3 Value;
    
    public Position(Vector3 value)
    public Position(float x, float y, float z)
}
```

**使用示例:**
```csharp
// 设置位置
var position = entity.GetComponent<Position>();
position.Value = new Vector3(10, 64, 5);

// 获取位置
var pos = entity.GetComponent<Position>().Value;
```

### 旋转组件 (Rotation)

存储实体的旋转角度（欧拉角）。

```csharp
public struct Rotation : IComponent
{
    public Vector3 Value; // Yaw, Pitch, Roll
    
    public Rotation(Vector3 value)
    public Rotation(float yaw, float pitch, float roll)
}
```

### 速度组件 (Velocity)

存储实体的移动速度。

```csharp
public struct Velocity : IComponent
{
    public Vector3 Value;
    
    public Velocity(Vector3 value)
    public Velocity(float x, float y, float z)
}
```

### 方块组件 (Block)

存储方块实体的类型和属性。

```csharp
public struct Block : IComponent
{
    public BlockType Type;
    public BlockData Data;
    
    public Block(BlockType type)
}
```

**使用示例:**
```csharp
// 设置方块类型
var block = entity.GetComponent<Block>();
block.Type = BlockType.Stone;
block.Data = new BlockData(BlockType.Stone);
```

### 区块组件 (Chunk)

存储区块的位置和状态信息。

```csharp
public struct Chunk : IComponent
{
    public ChunkPosition Position;
    public ChunkState State;
    public bool IsDirty;
    public bool IsLoaded;
    public bool IsMeshGenerated;
    
    public Chunk(ChunkPosition position)
}
```

**区块状态枚举:**
```csharp
public enum ChunkState
{
    Unloaded,    // 未加载
    Loading,     // 加载中
    Loaded,      // 已加载
    Generating,  // 生成中
    Meshing,     // 网格生成中
    Unloading    // 卸载中
}
```

### 网格组件 (Mesh)

存储实体的网格渲染数据。

```csharp
public struct Mesh : IComponent
{
    public bool IsDirty;
    public int VertexCount;
    public int IndexCount;
    public BoundingBox Bounds;
    
    public Mesh(BoundingBox bounds)
}
```

### 玩家组件 (Player)

标记实体为玩家，存储玩家特定属性。

```csharp
public struct Player : IComponent
{
    public float MoveSpeed;
    public float LookSpeed;
    public float JumpSpeed;
    public bool IsGrounded;
    public bool IsFlying;
    
    public Player(float moveSpeed = 10f, float lookSpeed = 0.1f, float jumpSpeed = 8f)
}
```

### 相机组件 (Camera)

存储相机的投影和视图矩阵。

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
    
    public Camera(float fieldOfView = 75f, float aspectRatio = 16f/9f, 
                  float nearPlane = 0.1f, float farPlane = 1000f)
}
```

### 可见性组件 (Visibility)

存储实体的可见性状态。

```csharp
public struct Visibility : IComponent
{
    public bool IsVisible;
    public float Distance;
    public bool InFrustum;
    
    public Visibility(bool isVisible = true)
}
```

### 光照组件 (Lighting)

存储实体的光照信息。

```csharp
public struct Lighting : IComponent
{
    public byte Brightness;
    public byte Sunlight;
    public byte Torchlight;
    public Color TintColor;
    
    public Lighting(byte brightness = 15)
}
```

### 碰撞体组件 (Collider)

存储实体的碰撞检测信息。

```csharp
public struct Collider : IComponent
{
    public BoundingBox Bounds;
    public bool IsSolid;
    public bool IsTrigger;
    
    public Collider(BoundingBox bounds, bool isSolid = true)
}
```

### 输入组件 (Input)

存储实体的输入状态。

```csharp
public struct Input : IComponent
{
    public Vector2 Movement;
    public Vector2 Look;
    public bool Jump;
    public bool Sprint;
    public bool Fly;
    
    public Input()
}
```

### 生命期组件 (Lifetime)

存储实体的生命期信息。

```csharp
public struct Lifetime : IComponent
{
    public float TimeLeft;
    public bool IsExpired;
    
    public Lifetime(float timeLeft)
}
```

### 物理组件 (Physics)

存储实体的物理属性。

```csharp
public struct Physics : IComponent
{
    public float Mass;
    public float Drag;
    public float Bounciness;
    public Vector3 Gravity;
    
    public Physics(float mass = 1f, float drag = 0.1f)
}
```

---

## 系统API

### PlayerInputSystem

玩家输入处理系统，处理键盘和鼠标输入。

```csharp
public class PlayerInputSystem : QuerySystem<Input>
{
    public PlayerInputSystem()
    
    protected override void OnUpdate()
}
```

**功能:**
- 处理WASD移动输入
- 处理空格键跳跃
- 处理Shift键冲刺
- 处理F键飞行模式切换
- 处理鼠标视角控制

### PlayerMovementSystem

玩家移动系统，根据输入更新玩家位置和速度。

```csharp
public class PlayerMovementSystem : QuerySystem<Position, Rotation, Velocity, Input, Player>
{
    protected override void OnUpdate()
}
```

**功能:**
- 更新玩家旋转（视角）
- 计算移动方向
- 应用移动速度
- 处理跳跃逻辑
- 支持飞行模式

### PhysicsSystem

物理更新系统，应用重力、碰撞检测和物理模拟。

```csharp
public class PhysicsSystem : QuerySystem<Position, Velocity>
{
    protected override void OnUpdate()
}
```

**功能:**
- 应用重力
- 更新位置
- 基础碰撞检测

### CameraSystem

相机更新系统，根据位置和旋转更新相机矩阵。

```csharp
public class CameraSystem : QuerySystem<Camera>
{
    protected override void OnUpdate()
}
```

**功能:**
- 更新视图矩阵
- 更新投影矩阵
- 处理相机脏标记

### VisibilitySystem

可见性计算系统，计算实体是否在视锥体内。

```csharp
public class VisibilitySystem : QuerySystem<Visibility>
{
    public void SetViewFrustum(BoundingFrustum frustum, Vector3 cameraPosition)
    
    protected override void OnUpdate()
}
```

**功能:**
- 计算实体与相机距离
- 判断实体是否在视锥体内
- 更新可见性状态

### LifetimeSystem

生命期更新系统，更新实体的生命期，删除过期实体。

```csharp
public class LifetimeSystem : QuerySystem<Lifetime>
{
    protected override void OnUpdate()
}
```

**功能:**
- 更新生命期计时器
- 标记过期实体

### ChunkStateSystem

区块状态更新系统，更新区块的状态和标记。

```csharp
public class ChunkStateSystem : QuerySystem<Chunk>
{
    protected override void OnUpdate()
}
```

**功能:**
- 更新区块状态
- 处理区块加载/卸载逻辑

### RenderingSystem

ECS渲染系统，使用Friflo ECS的QuerySystem进行高效的实体渲染。

```csharp
public class RenderingSystem : QuerySystem<Block, Position, Visibility>
{
    public RenderingSystem(GraphicsDevice graphicsDevice)
    
    public void SetCamera(Matrix viewMatrix, Matrix projectionMatrix, Vector3 cameraPosition)
    
    public (int drawCalls, int triangles) GetRenderStats()
    
    public void Dispose()
    
    protected override void OnUpdate()
}
```

**功能:**
- 批量渲染相同类型的方块
- 按距离排序渲染
- 支持光照计算
- 性能统计

**渲染优化:**
- 使用对象池减少内存分配
- 批量渲染减少DrawCall
- 距离排序优化渲染顺序

---

## 工具类API

### ECSObjectPool

ECS对象池，优化性能：减少内存分配和GC压力。

```csharp
public class ECSObjectPool
{
    public ECSObjectPool(int initialSize = 100, int maxSize = 1000)
    
    // 获取对象池
    public ObjectPool<T> GetPool<T>() where T : class, new()
    
    // 获取对象
    public T Get<T>() where T : class, new()
    
    // 释放对象
    public void Release<T>(T obj) where T : class, new()
    
    // 清理所有池
    public void Clear()
}
```

**专用对象池:**
```csharp
// 列表池
public static class ListPool<T>
{
    public static List<T> Get()
    public static void Release(List<T> list)
}

// 数组池
public static class ArrayPool<T>
{
    public static T[] Get(int length)
    public static void Release(T[] array)
}

// 字典池
public static class DictionaryPool<TKey, TValue>
{
    public static Dictionary<TKey, TValue> Get()
    public static void Release(Dictionary<TKey, TValue> dict)
}

// 矩阵池
public static class MatrixPool
{
    public static Matrix Get()
    public static void Release(Matrix matrix)
}

// 向量池
public static class Vector3Pool
{
    public static Vector3 Get()
    public static void Release(Vector3 vector)
}
```

**使用示例:**
```csharp
var pool = new ECSObjectPool();

// 获取列表
var list = ListPool<Entity>.Get();
try {
    // 使用列表
    list.Add(entity1);
    list.Add(entity2);
}
finally {
    // 释放列表
    ListPool<Entity>.Release(list);
}
```

### ECSPerformanceMonitor

ECS性能监控器，监控ECS系统的性能指标。

```csharp
public class ECSPerformanceMonitor
{
    public ECSPerformanceMonitor(ECSObjectPool objectPool, int maxHistorySize = 1000)
    
    // 添加性能计数器
    public void AddCounter(string name, string description)
    
    // 开始帧计时
    public void BeginFrame()
    
    // 结束帧计时
    public void EndFrame()
    
    // 记录性能值
    public void RecordValue(string counterName, double value)
    
    // 记录操作耗时
    public void RecordOperationTime(string operationName, Action operation)
    
    // 获取性能统计信息
    public PerformanceStats GetStats()
    
    // 获取性能报告
    public string GetPerformanceReport()
    
    // 获取性能警告
    public List<string> GetPerformanceWarnings()
    
    // 重置统计信息
    public void Reset()
    
    public void Dispose()
}
```

**默认计数器:**
- `EntityStore.Count`: 实体总数
- `EntityStore.Creations`: 实体创建数量
- `System.UpdateTime`: 系统更新时间
- `Query.VisibleBlocks`: 可见方块数量
- `Rendering.DrawCalls`: DrawCall数量
- `Memory.PoolUsage`: 对象池使用率

**使用示例:**
```csharp
var monitor = new ECSPerformanceMonitor(objectPool);

// 开始帧
monitor.BeginFrame();

// 执行操作
monitor.RecordOperationTime("BlockCreation", () => {
    // 创建方块的操作
});

// 记录值
monitor.RecordValue("VisibleBlocks", visibleBlocks.Count);

// 结束帧
monitor.EndFrame();

// 获取报告
var report = monitor.GetPerformanceReport();
Console.WriteLine(report);
```

### QueryCacheManager

查询缓存管理器，优化性能：缓存常用查询结果，减少重复计算。

```csharp
public class QueryCacheManager
{
    public QueryCacheManager(EntityStore store, ECSObjectPool objectPool)
    
    // 标记实体存储已更改
    public void MarkChanged()
    
    // 获取或创建查询缓存
    public QueryCache<T> GetOrCreateCache<T>(string cacheKey, Func<EntityStore, T> queryFunc) where T : class
    
    // 获取可见方块实体缓存
    public QueryCache<List<Entity>> GetVisibleBlocksCache()
    
    // 获取可见区块实体缓存
    public QueryCache<List<Entity>> GetVisibleChunksCache()
    
    // 获取按类型分组的方块实体缓存
    public QueryCache<Dictionary<BlockType, List<Entity>>> GetBlocksByTypeCache()
    
    // 清理所有缓存
    public void Clear()
}
```

**使用示例:**
```csharp
var cacheManager = new QueryCacheManager(store, objectPool);

// 获取缓存
var cache = cacheManager.GetVisibleBlocksCache();

// 使用缓存数据
foreach (var entity in cache.Data) {
    // 处理实体
}

// 标记更改
cacheManager.MarkChanged();
```

### BatchOperationOptimizer

批量操作优化器，优化性能：减少单个实体操作的开销，使用批量处理。

```csharp
public class BatchOperationOptimizer
{
    public BatchOperationOptimizer(EntityStore store, ECSObjectPool objectPool, 
                                   QueryCacheManager cacheManager, int batchSize = 100)
    
    // 批量创建方块实体
    public Entity[] CreateBlocksBatch(BlockType[] blockTypes, Vector3[] positions)
    
    // 批量创建方块实体（优化版）
    public Entity[] CreateBlocksBatchOptimized(BlockType[] blockTypes, Vector3[] positions, 
                                              bool[] visibility, byte[] lighting)
    
    // 批量更新方块位置
    public void UpdateBlockPositionsBatch(Entity[] entities, Vector3[] newPositions)
    
    // 批量更新方块可见性
    public void UpdateBlockVisibilityBatch(Entity[] entities, bool[] visibility)
    
    // 批量更新方块光照
    public void UpdateBlockLightingBatch(Entity[] entities, byte[] lighting)
    
    // 批量删除实体
    public void DeleteEntitiesBatch(Entity[] entities)
    
    // 批量获取实体组件
    public T[] GetComponentsBatch<T>(Entity[] entities) where T : struct, IComponent
    
    // 批量安全获取实体组件
    public (T[] components, bool[] found) TryGetComponentsBatch<T>(Entity[] entities) where T : struct, IComponent
    
    // 批量添加组件到实体
    public void AddComponentsBatch<T>(Entity[] entities, T[] components) where T : struct, IComponent
    
    // 批量移除组件
    public void RemoveComponentsBatch<T>(Entity[] entities) where T : struct, IComponent
    
    // 按方块类型分组处理
    public void ProcessBlocksByTypeBatch(Action<BlockType, List<Entity>> processAction)
    
    // 按距离分组处理
    public void ProcessBlocksByDistanceBatch(Vector3 centerPosition, float maxDistance, 
                                           Action<Entity, float> processAction)
    
    // 批量创建区块实体
    public Entity[] CreateChunksBatch(ChunkPosition[] positions)
}
```

**使用示例:**
```csharp
var optimizer = new BatchOperationOptimizer(store, objectPool, cacheManager);

// 批量创建方块
var blockTypes = new[] { BlockType.Grass, BlockType.Stone, BlockType.Dirt };
var positions = new[] { new Vector3(0, 64, 0), new Vector3(1, 64, 0), new Vector3(2, 64, 0) };
var entities = optimizer.CreateBlocksBatch(blockTypes, positions);

// 批量更新可见性
var visibility = new[] { true, false, true };
optimizer.UpdateBlockVisibilityBatch(entities, visibility);

// 按类型处理
optimizer.ProcessBlocksByTypeBatch((blockType, blockEntities) => {
    Console.WriteLine($"Processing {blockType}: {blockEntities.Count} blocks");
});
```

---

## 管理器API

### ECSBlockManager

ECS方块管理器，使用ECS系统管理方块实体，提供高性能的方块操作。

```csharp
public class ECSBlockManager
{
    public ECSBlockManager(EntityStore store)
    
    // 获取实体存储
    public EntityStore Store { get; }
    
    // 设置方块
    public Entity SetBlock(BlockType blockType, Vector3 position)
    
    // 获取方块
    public BlockType? GetBlock(Vector3 position)
    
    // 移除方块
    public bool RemoveBlock(Vector3 position)
    
    // 批量设置方块
    public void SetBlocksBatch(BlockType[] blockTypes, Vector3[] positions)
    
    // 获取区块内的所有方块
    public Entity[] GetBlocksInChunk(ChunkPosition chunkPos)
    
    // 获取指定范围内的方块
    public Entity[] GetBlocksInRange(Vector3 center, float radius)
    
    // 射线检测
    public Entity? Raycast(Vector3 origin, Vector3 direction, float maxDistance)
    
    // 获取所有方块实体
    public Entity[] GetAllBlocks()
    
    // 获取方块数量
    public int GetBlockCount()
    
    // 获取区块数量
    public int GetChunkCount()
    
    // 清空所有方块
    public void ClearAll()
    
    // 优化存储
    public void OptimizeStorage()
    
    // 获取内存使用统计
    public MemoryStats GetMemoryStats()
}
```

**内存统计结构:**
```csharp
public struct MemoryStats
{
    public int TotalBlocks;
    public int TotalChunks;
    public int DictionaryEntries;
    public float AverageBlocksPerChunk;
}
```

**使用示例:**
```csharp
var blockManager = new ECSBlockManager(store);

// 设置方块
var entity = blockManager.SetBlock(BlockType.Grass, new Vector3(0, 64, 0));

// 获取方块
var blockType = blockManager.GetBlock(new Vector3(0, 64, 0));

// 批量设置
var types = new[] { BlockType.Grass, BlockType.Stone };
var positions = new[] { new Vector3(0, 64, 0), new Vector3(1, 64, 0) };
blockManager.SetBlocksBatch(types, positions);

// 射线检测
var hitEntity = blockManager.Raycast(cameraPosition, lookDirection, 10f);

// 获取统计
var stats = blockManager.GetMemoryStats();
```

### ECSChunkManager

ECS区块管理器，使用ECS系统管理区块实体，提供高性能的区块操作。

```csharp
public class ECSChunkManager
{
    public ECSChunkManager(EntityStore store, ECSBlockManager blockManager, int renderDistance = 10)
    
    // 创建区块
    public Entity CreateChunk(ChunkPosition position)
    
    // 获取区块
    public Entity GetChunk(ChunkPosition position)
    
    // 卸载区块
    public bool UnloadChunk(ChunkPosition position)
    
    // 更新区块加载状态
    public void UpdateChunkLoading(ChunkPosition playerChunkPos)
    
    // 获取已加载的区块
    public Entity[] GetLoadedChunks()
    
    // 获取可见区块
    public Entity[] GetVisibleChunks()
    
    // 获取需要生成网格的区块
    public Entity[] GetDirtyChunks()
    
    // 标记区块为脏
    public void MarkChunkDirty(ChunkPosition position)
    
    // 标记区块为已加载
    public void MarkChunkLoaded(ChunkPosition position)
    
    // 标记区块网格已生成
    public void MarkChunkMeshGenerated(ChunkPosition position)
    
    // 获取区块数量
    public int GetChunkCount()
    
    // 获取已加载的区块数量
    public int GetLoadedChunkCount()
    
    // 获取需要更新的区块数量
    public int GetDirtyChunkCount()
    
    // 清空所有区块
    public void ClearAll()
    
    // 获取统计信息
    public ChunkStats GetStats()
}
```

**区块统计结构:**
```csharp
public struct ChunkStats
{
    public int TotalChunks;
    public int LoadedChunks;
    public int DirtyChunks;
    public int RenderDistance;
}
```

**使用示例:**
```csharp
var chunkManager = new ECSChunkManager(store, blockManager, 10);

// 创建区块
var chunkEntity = chunkManager.CreateChunk(new ChunkPosition(0, 0, 0));

// 更新加载状态
chunkManager.UpdateChunkLoading(playerChunkPosition);

// 获取脏区块
var dirtyChunks = chunkManager.GetDirtyChunks();

// 标记区块已加载
chunkManager.MarkChunkLoaded(new ChunkPosition(0, 0, 0));

// 获取统计
var stats = chunkManager.GetStats();
```

### ECSRenderManager

ECS渲染管理器，管理ECS实体的渲染和性能统计。

```csharp
public class ECSRenderManager
{
    public ECSRenderManager(ECSWorld ecsWorld, RenderManager renderManager, 
                           GraphicsDevice graphicsDevice, BlockRegistry blockRegistry)
    
    // 初始化渲染系统
    public void Initialize(SystemRoot systemRoot)
    
    // 更新视锥体
    public void UpdateFrustum(Matrix viewMatrix, Matrix projectionMatrix, Vector3 cameraPosition)
    
    // 更新渲染系统
    public void Update(GameTime gameTime)
    
    // 渲染ECS实体
    public void Render()
    
    // 获取渲染统计信息
    public RenderStats GetStats()
    
    public void Dispose()
}
```

**渲染统计结构:**
```csharp
public struct RenderStats
{
    public int VisibleChunks { get; set; }
    public float RenderTime { get; set; }
    public int DrawCalls { get; set; }
    public int Triangles { get; set; }
}
```

**使用示例:**
```csharp
var renderManager = new ECSRenderManager(ecsWorld, renderManager, graphicsDevice, blockRegistry);

// 初始化
renderManager.Initialize(systemRoot);

// 更新视锥体
renderManager.UpdateFrustum(viewMatrix, projectionMatrix, cameraPosition);

// 渲染
renderManager.Render();

// 获取统计
var stats = renderManager.GetStats();
```

---

## 使用示例和最佳实践

### 基础使用示例

```csharp
// 1. 创建ECS世界
var ecsWorld = new ECSWorld();

// 2. 创建玩家
ecsWorld.CreateDefaultPlayer();

// 3. 创建区块和方块
var chunkPos = new ChunkPosition(0, 0, 0);
var chunkEntity = ecsWorld.CreateChunkEntity(chunkPos);

// 批量创建方块
var blockTypes = new BlockType[100];
var positions = new Vector3[100];
for (int i = 0; i < 100; i++) {
    blockTypes[i] = BlockType.Grass;
    positions[i] = new Vector3(i, 64, 0);
}
var blockEntities = ecsWorld.CreateBlockEntitiesBatch(blockTypes, positions);

// 4. 游戏循环中更新
while (gameRunning) {
    ecsWorld.Update(gameTime);
    
    // 获取性能统计
    if (frameCount % 60 == 0) {
        var stats = ecsWorld.GetOptimizedPerformanceStats();
        Console.WriteLine($"FPS: {1000.0 / stats.AverageFrameTime:F1}");
    }
}

// 5. 清理资源
ecsWorld.Dispose();
```

### 高级批量操作示例

```csharp
// 使用批量操作优化器
var optimizer = new BatchOperationOptimizer(store, objectPool, cacheManager);

// 1. 批量创建大量方块
var blockTypes = Enumerable.Repeat(BlockType.Stone, 1000).ToArray();
var positions = Enumerable.Range(0, 1000)
    .Select(i => new Vector3(i % 100, 64, i / 100))
    .ToArray();
var entities = optimizer.CreateBlocksBatch(blockTypes, positions);

// 2. 批量更新可见性（基于距离）
var cameraPos = new Vector3(50, 64, 50);
optimizer.ProcessBlocksByDistanceBatch(cameraPos, 50f, (entity, distance) => {
    var visibility = entity.GetComponent<Visibility>();
    visibility.IsVisible = distance <= 50f;
});

// 3. 按类型批量处理
optimizer.ProcessBlocksByTypeBatch((blockType, blockEntities) => {
    Console.WriteLine($"Processing {blockType}: {blockEntities.Count} blocks");
    
    // 为每种类型的方块设置不同的光照
    var brightness = blockType switch {
        BlockType.Glowstone => (byte)15,
        BlockType.Torch => (byte)14,
        _ => (byte)10
    };
    
    foreach (var entity in blockEntities) {
        var lighting = entity.GetComponent<Lighting>();
        lighting.Brightness = brightness;
    }
});
```

### 性能监控示例

```csharp
var monitor = new ECSPerformanceMonitor(objectPool);

// 游戏循环中监控性能
while (gameRunning) {
    monitor.BeginFrame();
    
    try {
        // 执行游戏逻辑
        ecsWorld.Update(gameTime);
        
        // 监控特定操作
        monitor.RecordOperationTime("BlockRendering", () => {
            // 渲染方块的操作
        });
        
        // 记录自定义指标
        monitor.RecordValue("Custom.EntitiesProcessed", entitiesProcessed);
    }
    finally {
        monitor.EndFrame();
    }
    
    // 定期输出性能报告
    if (frameCount % 300 == 0) {
        var report = monitor.GetPerformanceReport();
        var warnings = monitor.GetPerformanceWarnings();
        
        Console.WriteLine(report);
        foreach (var warning in warnings) {
            Console.WriteLine($"警告: {warning}");
        }
    }
}
```

### 查询缓存使用示例

```csharp
var cacheManager = new QueryCacheManager(store, objectPool);

// 1. 获取缓存查询结果
var visibleBlocksCache = cacheManager.GetVisibleBlocksCache();
var visibleBlocks = visibleBlocksCache.Data;

// 2. 使用缓存数据进行批量操作
foreach (var block in visibleBlocks) {
    // 处理可见方块
}

// 3. 当数据发生变化时标记缓存失效
cacheManager.MarkChanged();

// 4. 自定义缓存
var customCache = cacheManager.GetOrCreateCache("my_custom_query", store => {
    var query = store.Query<Block, Position, Visibility>();
    var result = ListPool<Entity>.Get();
    
    foreach (var entity in query.Entities) {
        var visibility = entity.GetComponent<Visibility>();
        if (visibility.IsVisible && visibility.Distance < 100f) {
            result.Add(entity);
        }
    }
    
    return result;
});
```

### 对象池使用示例

```csharp
var objectPool = new ECSObjectPool();

// 1. 使用列表池
public void ProcessEntities(IEnumerable<Entity> entities) {
    var entityList = ListPool<Entity>.Get();
    try {
        entityList.AddRange(entities);
        
        // 处理实体列表
        foreach (var entity in entityList) {
            // 处理逻辑
        }
    }
    finally {
        ListPool<Entity>.Release(entityList);
    }
}

// 2. 使用字典池
public void GroupEntitiesByType(IEnumerable<Entity> entities) {
    var groupedDict = DictionaryPool<BlockType, List<Entity>>.Get();
    try {
        foreach (var entity in entities) {
            var block = entity.GetComponent<Block>();
            if (!groupedDict.ContainsKey(block.Type)) {
                groupedDict[block.Type] = ListPool<Entity>.Get();
            }
            groupedDict[block.Type].Add(entity);
        }
        
        // 使用分组数据
        foreach (var kvp in groupedDict) {
            Console.WriteLine($"{kvp.Key}: {kvp.Value.Count} entities");
        }
    }
    finally {
        foreach (var list in groupedDict.Values) {
            ListPool<Entity>.Release(list);
        }
        DictionaryPool<BlockType, List<Entity>>.Release(groupedDict);
    }
}
```

### 系统集成示例

```csharp
// 1. 创建完整的ECS系统
var ecsWorld = new ECSWorld();
var blockManager = new ECSBlockManager(ecsWorld.Store);
var chunkManager = new ECSChunkManager(ecsWorld.Store, blockManager);
var renderManager = new ECSRenderManager(ecsWorld, renderManager, graphicsDevice, blockRegistry);

// 2. 初始化渲染系统
renderManager.Initialize(ecsWorld.SystemRoot);

// 3. 游戏循环
while (gameRunning) {
    // 更新输入
    var inputState = GetInputState();
    
    // 更新区块加载
    var playerChunkPos = GetPlayerChunkPosition();
    chunkManager.UpdateChunkLoading(playerChunkPos);
    
    // 更新ECS世界
    ecsWorld.Update(gameTime);
    
    // 更新渲染
    var viewMatrix = camera.ViewMatrix;
    var projectionMatrix = camera.ProjectionMatrix;
    var cameraPosition = camera.Position;
    
    renderManager.UpdateFrustum(viewMatrix, projectionMatrix, cameraPosition);
    renderManager.Update(gameTime);
    
    // 渲染
    graphicsDevice.Clear(Color.CornflowerBlue);
    renderManager.Render();
    
    // 输出性能信息
    if (frameCount % 60 == 0) {
        var ecsStats = ecsWorld.GetOptimizedPerformanceStats();
        var renderStats = renderManager.GetStats();
        
        Debug.WriteLine($"FPS: {1000.0 / ecsStats.AverageFrameTime:F1}");
        Debug.WriteLine($"DrawCalls: {renderStats.DrawCalls}");
        Debug.WriteLine($"Triangles: {renderStats.Triangles}");
    }
    
    frameCount++;
}

// 4. 清理资源
renderManager.Dispose();
ecsWorld.Dispose();
```

---

## 性能优化指南

### 1. 批量操作优化

**推荐做法:**
```csharp
// 使用批量创建
var entities = ecsWorld.CreateBlockEntitiesBatch(blockTypes, positions);

// 使用批量更新
optimizer.UpdateBlockVisibilityBatch(entities, visibilityArray);

// 使用批量处理
optimizer.ProcessBlocksByTypeBatch((blockType, entities) => {
    // 批量处理每种类型
});
```

**避免做法:**
```csharp
// 避免逐个创建
foreach (var pos in positions) {
    ecsWorld.CreateBlockEntity(BlockType.Grass, pos); // 性能较差
}
```

### 2. 查询缓存优化

**推荐做法:**
```csharp
// 使用缓存查询
var cache = cacheManager.GetVisibleBlocksCache();
var visibleBlocks = cache.Data;

// 只在数据变化时标记失效
if (dataChanged) {
    cacheManager.MarkChanged();
}
```

### 3. 对象池使用

**推荐做法:**
```csharp
// 使用对象池
var list = ListPool<Entity>.Get();
try {
    // 使用列表
    list.AddRange(entities);
}
finally {
    ListPool<Entity>.Release(list);
}
```

### 4. 性能监控

**关键指标监控:**
- FPS (目标: >= 60)
- 系统更新时间 (目标: < 2ms)
- DrawCall数量 (目标: < 1000)
- 实体数量 (目标: < 10000)

### 5. 内存管理

**推荐做法:**
```csharp
// 定期优化存储
blockManager.OptimizeStorage();

// 使用适当的批量大小
var optimizer = new BatchOperationOptimizer(store, objectPool, cacheManager, batchSize: 100);

// 及时释放不再需要的资源
using (var renderManager = new ECSRenderManager(...)) {
    // 使用渲染管理器
}
```

---

## 故障排除

### 常见问题

#### 1. 实体删除失败

**问题:** 尝试删除实体时失败
**原因:** Friflo ECS的删除API可能需要特殊处理
**解决方案:**
```csharp
// 目前使用可见性标记替代删除
var visibility = entity.GetComponent<Visibility>();
visibility.IsVisible = false;
```

#### 2. 性能下降

**问题:** FPS降低，系统响应变慢
**原因:** 实体数量过多或查询效率低
**解决方案:**
```csharp
// 检查实体数量
var stats = ecsWorld.GetEntityStats();
Console.WriteLine($"实体总数: {stats.TotalEntities}");

// 使用批量操作
optimizer.ProcessBlocksBatchOptimized(ProcessSingleBlock);

// 启用查询缓存
var cache = cacheManager.GetVisibleBlocksCache();
```

#### 3. 内存泄漏

**问题:** 内存使用持续增长
**原因:** 对象池未正确释放
**解决方案:**
```csharp
// 确保正确使用对象池
var list = ListPool<Entity>.Get();
try {
    // 使用列表
}
finally {
    ListPool<Entity>.Release(list);
}

// 定期清理
objectPool.Clear();
cacheManager.Clear();
```

#### 4. 渲染问题

**问题:** 方块渲染不正确或性能差
**原因:** 渲染系统配置问题
**解决方案:**
```csharp
// 检查渲染统计
var renderStats = renderManager.GetStats();
Console.WriteLine($"DrawCalls: {renderStats.DrawCalls}");

// 确保正确设置相机
renderManager.UpdateFrustum(viewMatrix, projectionMatrix, cameraPosition);
```

### 调试技巧

#### 1. 启用性能监控

```csharp
var monitor = new ECSPerformanceMonitor(objectPool);

// 在游戏循环中记录性能
monitor.BeginFrame();
// 执行游戏逻辑
monitor.EndFrame();

// 定期输出报告
Console.WriteLine(monitor.GetPerformanceReport());
```

#### 2. 检查查询缓存

```csharp
// 检查缓存命中率
var cache = cacheManager.GetVisibleBlocksCache();
Console.WriteLine($"缓存版本: {cache.Version}");
Console.WriteLine($"缓存实体数量: {cache.Data.Count}");
```

#### 3. 监控对象池使用

```csharp
var pool = objectPool.GetPool<List<Entity>>();
Console.WriteLine($"池中对象数量: {pool.Count}");
Console.WriteLine($"已创建对象总数: {pool.CreatedCount}");
```

---

## 版本历史

### v1.0.0 (当前版本)
- 初始ECS系统实现
- 基于Friflo ECS框架
- 集成性能优化组件
- 支持方块、区块、玩家管理
- 完整的渲染系统集成

### 计划功能
- [ ] 多线程区块生成
- [ ] 更复杂的物理系统
- [ ] 网络同步支持
- [ ] 更高级的渲染效果
- [ ] 资源管理系统集成

---

## 贡献指南

### 代码规范
- 遵循C#命名规范
- 使用中文注释
- 实现IDisposable接口的资源管理
- 使用对象池优化内存分配

### 测试要求
- 编写单元测试
- 性能基准测试
- 内存泄漏检测

### 文档维护
- 更新API文档
- 添加使用示例
- 记录性能优化技巧

---

## 许可证

本ECS系统是MCGame项目的一部分，遵循项目的开源许可证。

---

*最后更新: 2025-08-20*
*版本: 1.0.0*
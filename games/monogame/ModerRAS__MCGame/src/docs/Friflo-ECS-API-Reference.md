# Friflo ECS API 完整参考文档

## 📖 概述

Friflo ECS 3.4.2 是一个高性能的实体组件系统框架，专为游戏开发设计。本文档提供了完整的 API 参考，基于 MCGame 项目的实际实现和测试验证。

### 🎯 文档结构

- **核心架构**: EntityStore、SystemRoot 等基础组件
- **实体管理**: 创建、删除、查询实体
- **组件系统**: 定义、操作、管理组件
- **查询系统**: ArchetypeQuery、QuerySystem
- **性能优化**: 批量操作、缓存策略
- **集成指南**: 与 MonoGame 集成
- **调试工具**: 性能监控、错误处理

## 🏗️ 核心架构

### EntityStore - 实体存储

`EntityStore` 是 Friflo ECS 的核心容器，管理所有实体和组件。

```csharp
namespace Friflo.Engine.ECS
{
    public class EntityStore
    {
        // 构造函数
        public EntityStore();
        
        // 基本属性
        public int Count { get; }                    // 实体总数
        public int Capacity { get; }                 // 实体容量
        
        // 实体管理
        public Entity CreateEntity();                // 创建空实体
        public Entity CreateEntity(params IComponent[] components); // 创建带组件的实体
        public void DeleteAllEntities();             // 删除所有实体
        
        // 查询创建
        public ArchetypeQuery<T> Query<T>();         // 创建单组件查询
        public ArchetypeQuery<T1, T2> Query<T1, T2>(); // 创建双组件查询
        public ArchetypeQuery<T1, T2, T3> Query<T1, T2, T3>(); // 创建三组件查询
        
        // 命令缓冲区
        public CommandBuffer CreateCommandBuffer();  // 创建命令缓冲区
    }
}
```

#### 使用示例

```csharp
// 创建实体存储
var store = new EntityStore();

// 创建带组件的实体
var entity = store.CreateEntity(
    new Position(0, 64, 0),
    new Velocity(0, 0, 0),
    new Player()
);

// 获取实体数量
int entityCount = store.Count;

// 创建查询
var playerQuery = store.Query<Player, Position, Velocity>();

// 清空所有实体
store.DeleteAllEntities();
```

### SystemRoot - 系统根节点

`SystemRoot` 管理 ECS 系统的生命周期和执行顺序。

```csharp
namespace Friflo.Engine.ECS.Systems
{
    public class SystemRoot : IDisposable
    {
        // 构造函数
        public SystemRoot(EntityStore store);
        
        // 系统管理
        public void Add(SystemBase system);           // 添加系统
        public void Remove(SystemBase system);        // 移除系统
        
        // 执行控制
        public void Update(UpdateTick tick);         // 更新所有系统
        public void SetMonitorPerf(bool enabled);     // 启用/禁用性能监控
        public string GetPerfLog();                   // 获取性能日志
        
        // 资源管理
        public void Dispose();                        // 释放资源
    }
}
```

#### 使用示例

```csharp
// 创建系统根节点
var systemRoot = new SystemRoot(store);

// 添加系统
systemRoot.Add(new PlayerInputSystem());
systemRoot.Add(new PlayerMovementSystem());
systemRoot.Add(new PhysicsSystem());

// 启用性能监控
systemRoot.SetMonitorPerf(true);

// 更新系统
systemRoot.Update(new UpdateTick());

// 获取性能日志
string perfLog = systemRoot.GetPerfLog();
Console.WriteLine(perfLog);
```

## 🎭 实体管理

### Entity - 实体类

`Entity` 代表 ECS 中的一个实体，包含组件和状态信息。

```csharp
namespace Friflo.Engine.ECS
{
    public struct Entity
    {
        // 基本属性
        public int Id { get; }                       // 实体ID
        public bool IsAlive { get; }                 // 实体是否存活
        public int ComponentCount { get; }           // 组件数量
        public Archetype Archetype { get; }          // 实体原型
        
        // 组件操作
        public T GetComponent<T>() where T : IComponent;           // 获取组件
        public bool TryGetComponent<T>(out T component) where T : IComponent; // 安全获取组件
        public void AddComponent<T>(T component) where T : IComponent;        // 添加组件
        public void RemoveComponent<T>() where T : IComponent;                 // 移除组件
        public bool HasComponent<T>() where T : IComponent;                   // 检查组件是否存在
        
        // 批量组件操作
        public void AddComponents(params IComponent[] components);     // 添加多个组件
        public void RemoveAllComponents();                            // 移除所有组件
        
        // 实体操作
        public void Dispose();                                         // 删除实体
        
        // 组件类型查询
        public ComponentTypes GetComponentTypes();                     // 获取所有组件类型
    }
}
```

#### 使用示例

```csharp
// 创建实体
var entity = store.CreateEntity(
    new Position(0, 64, 0),
    new Velocity(0, 0, 0)
);

// 安全获取组件
if (entity.TryGetComponent<Position>(out var position))
{
    position.Value = new Vector3(10, 20, 30);
}

// 直接获取组件（需要确保组件存在）
var velocity = entity.GetComponent<Velocity>();
velocity.Value = new Vector3(1, 0, 0);

// 添加组件
entity.AddComponent(new Player());

// 检查组件是否存在
bool hasPlayer = entity.HasComponent<Player>();

// 移除组件
entity.RemoveComponent<Player>();

// 删除实体
entity.Dispose();
```

### 批量实体操作

```csharp
// 批量创建实体
public Entity[] CreateEntitiesBatch(EntityStore store, int count)
{
    var entities = new Entity[count];
    for (int i = 0; i < count; i++)
    {
        entities[i] = store.CreateEntity(
            new Position(i, 64, i),
            new Block(BlockType.Grass),
            new Visibility(true)
        );
    }
    return entities;
}

// 批量删除实体
public void DeleteEntitiesBatch(Entity[] entities)
{
    foreach (var entity in entities)
    {
        if (entity.IsAlive)
        {
            entity.Dispose();
        }
    }
}
```

## 🔧 组件系统

### IComponent 接口

所有组件必须实现 `IComponent` 接口。

```csharp
namespace Friflo.Engine.ECS
{
    public interface IComponent { }
}
```

### 组件定义示例

```csharp
// 位置组件
public struct Position : IComponent
{
    public Vector3 Value;
    
    public Position(Vector3 value) => Value = value;
    public Position(float x, float y, float z) => Value = new Vector3(x, y, z);
}

// 速度组件
public struct Velocity : IComponent
{
    public Vector3 Value;
    
    public Velocity(Vector3 value) => Value = value;
    public Velocity(float x, float y, float z) => Value = new Vector3(x, y, z);
}

// 玩家组件
public struct Player : IComponent
{
    public float MoveSpeed;
    public float LookSpeed;
    public bool IsGrounded;
    public bool IsFlying;
    
    public Player(float moveSpeed = 10f, float lookSpeed = 0.1f)
    {
        MoveSpeed = moveSpeed;
        LookSpeed = lookSpeed;
        IsGrounded = false;
        IsFlying = false;
    }
}

// 方块组件
public struct Block : IComponent
{
    public BlockType Type;
    public BlockData Data;
    
    public Block(BlockType type) => (Type, Data) = (type, new BlockData(type));
}

// 可见性组件
public struct Visibility : IComponent
{
    public bool IsVisible;
    public float Distance;
    public bool InFrustum;
    
    public Visibility(bool isVisible = true) => IsVisible = isVisible;
}
```

### 组件操作最佳实践

```csharp
// ✅ 安全的组件访问
public void ProcessEntity(Entity entity)
{
    // 使用 TryGetComponent 进行安全访问
    if (entity.TryGetComponent<Position>(out var position))
    {
        // 安全地使用组件
        position.Value += new Vector3(0, 1, 0);
    }
    
    // 检查组件是否存在
    if (entity.HasComponent<Velocity>())
    {
        var velocity = entity.GetComponent<Velocity>();
        // 处理速度组件
    }
}

// ❌ 不安全的直接访问
public void ProcessEntityUnsafe(Entity entity)
{
    try
    {
        var position = entity.GetComponent<Position>();
        position.Value += new Vector3(0, 1, 0);
    }
    catch (Exception ex)
    {
        Console.WriteLine($"组件访问失败: {ex.Message}");
    }
}
```

## 🔍 查询系统

### ArchetypeQuery - 原型查询

`ArchetypeQuery` 用于查询具有特定组件组合的实体。

```csharp
namespace Friflo.Engine.ECS
{
    public class ArchetypeQuery
    {
        // 基本属性
        public int EntityCount { get; }               // 匹配的实体数量
        public Entity[] Entities { get; }             // 实体数组
        
        // 遍历方法
        public void ForEachEntity<T>(Action<T, Entity> action) where T : IComponent;
        public void ForEachEntity<T1, T2>(Action<T1, T2, Entity> action) 
            where T1 : IComponent where T2 : IComponent;
        public void ForEachEntity<T1, T2, T3>(Action<T1, T2, T3, Entity> action) 
            where T1 : IComponent where T2 : IComponent where T3 : IComponent;
    }
}
```

#### 查询创建和使用

```csharp
// 创建单组件查询
var positionQuery = store.Query<Position>();

// 创建多组件查询
var playerQuery = store.Query<Player, Position, Velocity>();
var blockQuery = store.Query<Block, Position, Visibility>();

// 使用查询
public Entity[] GetVisibleBlocks(ArchetypeQuery blockQuery)
{
    var visibleBlocks = new List<Entity>();
    
    foreach (var entity in blockQuery.Entities)
    {
        var visibility = entity.GetComponent<Visibility>();
        if (visibility.IsVisible)
        {
            visibleBlocks.Add(entity);
        }
    }
    
    return visibleBlocks.ToArray();
}

// 使用 ForEachEntity 方法
playerQuery.ForEachEntity((ref Player player, ref Position position, ref Velocity velocity, Entity entity) =>
{
    // 处理玩家实体
    if (player.IsGrounded && velocity.Value.Y < 0)
    {
        velocity.Value.Y = 0;
    }
});
```

### QuerySystem - 查询系统

`QuerySystem` 是处理具有特定组件的实体的系统基类。

```csharp
namespace Friflo.Engine.ECS.Systems
{
    public abstract class QuerySystem<T> : SystemBase where T : IComponent
    {
        protected ArchetypeQuery Query { get; }        // 查询属性
        
        protected abstract void OnUpdate();            // 更新方法
        
        // 生命周期方法
        protected virtual void OnStart() { }           // 系统启动
        protected virtual void OnStop() { }            // 系统停止
    }
    
    public abstract class QuerySystem<T1, T2> : SystemBase 
        where T1 : IComponent where T2 : IComponent
    {
        protected ArchetypeQuery Query { get; }
        protected abstract void OnUpdate();
    }
    
    public abstract class QuerySystem<T1, T2, T3> : SystemBase 
        where T1 : IComponent where T2 : IComponent where T3 : IComponent
    {
        protected ArchetypeQuery Query { get; }
        protected abstract void OnUpdate();
    }
}
```

#### QuerySystem 实现示例

```csharp
// 玩家输入系统
public class PlayerInputSystem : QuerySystem<Input>
{
    private KeyboardState _currentKeyboard;
    private KeyboardState _previousKeyboard;
    private MouseState _currentMouse;
    private MouseState _previousMouse;

    protected override void OnUpdate()
    {
        var currentKeyboard = Keyboard.GetState();
        var currentMouse = Mouse.GetState();

        foreach (var entity in Query.Entities)
        {
            var input = entity.GetComponent<Input>();
            
            // 处理移动输入
            input.Movement = Vector2.Zero;
            if (currentKeyboard.IsKeyDown(Keys.W)) input.Movement.Y += 1;
            if (currentKeyboard.IsKeyDown(Keys.S)) input.Movement.Y -= 1;
            if (currentKeyboard.IsKeyDown(Keys.A)) input.Movement.X -= 1;
            if (currentKeyboard.IsKeyDown(Keys.D)) input.Movement.X += 1;

            // 处理跳跃输入
            input.Jump = currentKeyboard.IsKeyDown(Keys.Space) && 
                         _previousKeyboard.IsKeyUp(Keys.Space);

            // 处理特殊动作输入
            input.Sprint = currentKeyboard.IsKeyDown(Keys.LeftShift);
            input.Fly = currentKeyboard.IsKeyDown(Keys.F) && 
                        _previousKeyboard.IsKeyUp(Keys.F);
        }

        _previousKeyboard = _currentKeyboard;
        _previousMouse = _currentMouse;
        _currentKeyboard = currentKeyboard;
        _currentMouse = currentMouse;
    }
}

// 玩家移动系统
public class PlayerMovementSystem : QuerySystem<Position, Rotation, Velocity, Input, Player>
{
    protected override void OnUpdate()
    {
        var deltaTime = (float)Tick.DeltaTime;
        
        foreach (var entity in Query.Entities)
        {
            var position = entity.GetComponent<Position>();
            var rotation = entity.GetComponent<Rotation>();
            var velocity = entity.GetComponent<Velocity>();
            var input = entity.GetComponent<Input>();
            var player = entity.GetComponent<Player>();
            
            // 更新旋转
            rotation.Value.Y += input.Look.X * player.LookSpeed;
            rotation.Value.X += input.Look.Y * player.LookSpeed;
            rotation.Value.X = MathHelper.Clamp(rotation.Value.X, -MathHelper.PiOver2, MathHelper.PiOver2);

            // 计算移动方向
            var yaw = rotation.Value.Y;
            var forward = new Vector3((float)Math.Sin(yaw), 0, (float)Math.Cos(yaw));
            var right = new Vector3((float)Math.Cos(yaw), 0, -(float)Math.Sin(yaw));

            // 计算移动速度
            var moveSpeed = player.MoveSpeed;
            if (input.Sprint) moveSpeed *= 1.5f;
            if (player.IsFlying) moveSpeed *= 2f;

            // 应用移动输入
            var moveDirection = forward * input.Movement.Y + right * input.Movement.X;
            if (moveDirection != Vector3.Zero)
            {
                moveDirection.Normalize();
                velocity.Value = moveDirection * moveSpeed;
            }
            else
            {
                velocity.Value *= 0.9f; // 减速
            }

            // 处理跳跃
            if (input.Jump && player.IsGrounded && !player.IsFlying)
            {
                velocity.Value.Y = player.JumpSpeed;
                player.IsGrounded = false;
            }

            // 处理飞行模式
            if (player.IsFlying)
            {
                if (input.Jump) velocity.Value.Y = moveSpeed;
                if (Keyboard.GetState().IsKeyDown(Keys.LeftControl)) velocity.Value.Y = -moveSpeed;
            }
        }
    }
}
```

## 🚀 性能优化

### 查询缓存

```csharp
// ✅ 缓存查询结果
public class ECSWorld
{
    private readonly EntityStore _store;
    private readonly ArchetypeQuery _playerQuery;
    private readonly ArchetypeQuery _blockQuery;
    private readonly ArchetypeQuery _chunkQuery;
    
    public ECSWorld()
    {
        _store = new EntityStore();
        
        // 在构造函数中初始化查询
        _playerQuery = _store.Query<Player, Position, Velocity>();
        _blockQuery = _store.Query<Block, Position, Visibility>();
        _chunkQuery = _store.Query<Chunk, Position>();
    }
    
    public Entity[] GetVisibleBlocks()
    {
        var visibleBlocks = new List<Entity>();
        
        // 使用缓存的查询
        foreach (var entity in _blockQuery.Entities)
        {
            var visibility = entity.GetComponent<Visibility>();
            if (visibility.IsVisible)
            {
                visibleBlocks.Add(entity);
            }
        }
        
        return visibleBlocks.ToArray();
    }
}
```

### 批量操作

```csharp
// ✅ 批量创建实体
public Entity[] CreateBlockEntitiesBatch(EntityStore store, BlockType[] blockTypes, Vector3[] positions)
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

// ✅ 批量组件操作
public void UpdateVisibilityBatch(Entity[] entities, bool[] visibility)
{
    var commands = store.CreateCommandBuffer();
    
    for (int i = 0; i < entities.Length; i++)
    {
        if (entities[i].IsAlive)
        {
            commands.AddComponent(entities[i].Id, new Visibility(visibility[i]));
        }
    }
    
    commands.Playback();
}
```

### 对象池优化

```csharp
// ✅ 使用对象池减少内存分配
public class ECSObjectPool
{
    private readonly Dictionary<Type, object> _pools = new Dictionary<Type, object>();
    
    public ObjectPool<T> GetPool<T>() where T : class
    {
        if (!_pools.TryGetValue(typeof(T), out var poolObj))
        {
            var pool = new ObjectPool<T>(() => Activator.CreateInstance<T>());
            _pools[typeof(T)] = pool;
            return pool;
        }
        
        return (ObjectPool<T>)poolObj;
    }
    
    public void Clear()
    {
        foreach (var pool in _pools.Values)
        {
            if (pool is IDisposable disposable)
            {
                disposable.Dispose();
            }
        }
        _pools.Clear();
    }
}

// 专用列表池
public static class ListPool<T>
{
    private static readonly ObjectPool<List<T>> _pool = 
        new ObjectPool<List<T>>(() => new List<T>(), list => list.Clear());
    
    public static List<T> Get() => _pool.Get();
    public static void Release(List<T> list) => _pool.Release(list);
}
```

## 🎮 与 MonoGame 集成

### ECSWorld 集成

```csharp
public class ECSWorld : IDisposable
{
    private readonly EntityStore _store;
    private readonly SystemRoot _systemRoot;
    private readonly ArchetypeQuery _playerQuery;
    private readonly ArchetypeQuery _blockQuery;
    private readonly ArchetypeQuery _chunkQuery;
    
    // 系统引用
    private PlayerInputSystem _inputSystem;
    private PlayerMovementSystem _movementSystem;
    private PhysicsSystem _physicsSystem;
    private CameraSystem _cameraSystem;
    private VisibilitySystem _visibilitySystem;
    private ChunkStateSystem _chunkSystem;
    
    public Entity PlayerEntity { get; set; }
    
    public ECSWorld()
    {
        _store = new EntityStore();
        _systemRoot = new SystemRoot(_store);
        
        // 初始化查询
        _playerQuery = _store.Query<Player>();
        _blockQuery = _store.Query<Block>();
        _chunkQuery = _store.Query<Chunk>();
        
        // 初始化系统
        InitializeSystems();
        
        // 创建默认玩家
        CreateDefaultPlayer();
    }
    
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
        
        // 启用性能监控
        _systemRoot.SetMonitorPerf(true);
    }
    
    private void CreateDefaultPlayer()
    {
        PlayerEntity = _store.CreateEntity(
            new Position(0, 64, 0),
            new Rotation(0, 0, 0),
            new Velocity(0, 0, 0),
            new Player(),
            new Camera(75f, 16f/9f, 0.1f, 1000f),
            new Input(),
            new Physics(1f, 0.1f),
            new Collider(new BoundingBox(new Vector3(-0.3f, 0, -0.3f), new Vector3(0.3f, 1.8f, 0.3f))),
            new Visibility(true)
        );
    }
    
    public void Update(GameTime gameTime)
    {
        Tick.UpdateTime(gameTime);
        _systemRoot.Update(new UpdateTick());
    }
    
    public void SetViewFrustum(BoundingFrustum frustum, Vector3 cameraPosition)
    {
        _visibilitySystem.SetViewFrustum(frustum, cameraPosition);
    }
    
    public void Dispose()
    {
        _systemRoot?.Dispose();
        _store?.DeleteAllEntities();
    }
}
```

### 渲染系统集成

```csharp
public class ECSRenderer
{
    private readonly GraphicsDevice _graphicsDevice;
    private readonly BasicEffect _basicEffect;
    private readonly RasterizerState _rasterizerState;
    private readonly DepthStencilState _depthStencilState;
    
    public ECSRenderer(GraphicsDevice graphicsDevice)
    {
        _graphicsDevice = graphicsDevice;
        
        // 初始化基础效果
        _basicEffect = new BasicEffect(graphicsDevice)
        {
            TextureEnabled = false,
            VertexColorEnabled = true,
            LightingEnabled = false
        };
        
        // 初始化渲染状态
        _rasterizerState = new RasterizerState
        {
            CullMode = CullMode.CullClockwiseFace,
            FillMode = FillMode.Solid,
            ScissorTestEnable = false
        };
        
        _depthStencilState = new DepthStencilState
        {
            DepthBufferEnable = true,
            DepthBufferWriteEnable = true,
            DepthBufferFunction = CompareFunction.LessEqual
        };
    }
    
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
    
    private void RenderBlock(BlockType blockType, Vector3 position)
    {
        var worldMatrix = Matrix.CreateTranslation(position);
        _basicEffect.World = worldMatrix;
        
        // 设置方块颜色
        var color = GetBlockColor(blockType);
        _basicEffect.DiffuseColor = new Vector3(color.R / 255f, color.G / 255f, color.B / 255f);
        
        // 渲染立方体
        foreach (var pass in _basicEffect.CurrentTechnique.Passes)
        {
            pass.Apply();
            // 这里应该渲染实际的方块网格
        }
    }
    
    private Color GetBlockColor(BlockType blockType)
    {
        return blockType switch
        {
            BlockType.Grass => new Color(34, 139, 34),
            BlockType.Stone => new Color(128, 128, 128),
            BlockType.Dirt => new Color(139, 69, 19),
            BlockType.Wood => new Color(139, 90, 43),
            BlockType.Leaves => new Color(0, 100, 0),
            _ => new Color(128, 128, 128)
        };
    }
    
    public void Dispose()
    {
        _basicEffect?.Dispose();
        _rasterizerState?.Dispose();
        _depthStencilState?.Dispose();
    }
}
```

### 游戏主循环集成

```csharp
public class MCGame : Game
{
    private readonly ECSWorld _ecsWorld;
    private readonly ECSRenderer _ecsRenderer;
    
    public MCGame()
    {
        _ecsWorld = new ECSWorld();
        _ecsRenderer = new ECSRenderer(GraphicsDevice);
        
        // 初始化一些方块实体
        InitializeWorld();
    }
    
    private void InitializeWorld()
    {
        // 创建一些测试方块
        for (int x = 0; x < 10; x++)
        {
            for (int z = 0; z < 10; z++)
            {
                var position = new Vector3(x, 64, z);
                var blockType = (x + z) % 2 == 0 ? BlockType.Grass : BlockType.Stone;
                
                _ecsWorld.Store.CreateEntity(
                    new Block(blockType),
                    new Position(position),
                    new Visibility(true)
                );
            }
        }
    }
    
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
        
        // 设置视锥体
        var cameraPosition = GetCameraPosition();
        var frustum = new BoundingFrustum(viewMatrix * projectionMatrix);
        _ecsWorld.SetViewFrustum(frustum, cameraPosition);
        
        // 渲染ECS实体
        var blockQuery = _ecsWorld.Store.Query<Block, Position, Visibility>();
        _ecsRenderer.RenderVisibleEntities(blockQuery, viewMatrix, projectionMatrix);
        
        base.Draw(gameTime);
    }
    
    private Matrix GetViewMatrix()
    {
        // 从玩家实体获取相机矩阵
        if (_ecsWorld.PlayerEntity.TryGetComponent<Position>(out var position) &&
            _ecsWorld.PlayerEntity.TryGetComponent<Rotation>(out var rotation))
        {
            return Matrix.CreateLookAt(
                position.Value,
                position.Value + Vector3.Transform(Vector3.Forward, Matrix.CreateRotationY(rotation.Value.Y)),
                Vector3.Up
            );
        }
        
        return Matrix.CreateLookAt(new Vector3(0, 65, -10), new Vector3(0, 65, 0), Vector3.Up);
    }
    
    private Matrix GetProjectionMatrix()
    {
        return Matrix.CreatePerspectiveFieldOfView(
            MathHelper.ToRadians(75f),
            GraphicsDevice.Viewport.AspectRatio,
            0.1f,
            1000f
        );
    }
    
    private Vector3 GetCameraPosition()
    {
        if (_ecsWorld.PlayerEntity.TryGetComponent<Position>(out var position))
        {
            return position.Value;
        }
        
        return new Vector3(0, 65, -10);
    }
    
    protected override void Dispose(bool disposing)
    {
        if (disposing)
        {
            _ecsWorld?.Dispose();
            _ecsRenderer?.Dispose();
        }
        
        base.Dispose(disposing);
    }
}
```

## 🔧 错误处理

### 组件访问安全

```csharp
// ✅ 安全的组件访问
public class SafeComponentAccess
{
    public void ProcessEntity(Entity entity)
    {
        // 使用 TryGetComponent 进行安全访问
        if (entity.TryGetComponent<Position>(out var position))
        {
            // 安全地使用组件
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
    
    public void ProcessEntityWithValidation(Entity entity)
    {
        // 检查实体是否存活
        if (!entity.IsAlive)
        {
            Console.WriteLine("实体已删除");
            return;
        }
        
        // 检查组件是否存在
        if (!entity.HasComponent<Position>())
        {
            Console.WriteLine("实体没有Position组件");
            return;
        }
        
        // 现在可以安全地访问组件
        var position = entity.GetComponent<Position>();
        position.Value = new Vector3(1, 2, 3);
    }
}
```

### 系统异常处理

```csharp
// ✅ 健壮的系统实现
public class RobustSystem : QuerySystem<Position, Velocity>
{
    private int _errorCount = 0;
    private const int MaxErrors = 10;
    
    protected override void OnUpdate()
    {
        try
        {
            foreach (var entity in Query.Entities)
            {
                try
                {
                    if (!entity.IsAlive)
                        continue;
                        
                    var position = entity.GetComponent<Position>();
                    var velocity = entity.GetComponent<Velocity>();
                    
                    // 处理实体
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
                        break;
                    }
                }
            }
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
        position.Value += velocity.Value * (float)Tick.DeltaTime;
    }
}
```

### 资源清理

```csharp
// ✅ 完整的资源清理
public class ECSWorld : IDisposable
{
    private bool _disposed = false;
    private readonly SystemRoot _systemRoot;
    private readonly EntityStore _store;
    
    public ECSWorld()
    {
        _store = new EntityStore();
        _systemRoot = new SystemRoot(_store);
    }
    
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
            _systemRoot.Update(new UpdateTick());
        }
        catch (Exception ex)
        {
            Console.WriteLine($"ECSWorld更新失败: {ex.Message}");
            // 可以选择继续运行或停止
        }
    }
}
```

## 🐛 调试工具

### 性能监控

```csharp
// ✅ 详细的性能监控
public class ECSPerformanceMonitor
{
    private readonly SystemRoot _systemRoot;
    private readonly Stopwatch _stopwatch = new Stopwatch();
    private long _lastFrameTime;
    private long _frameCount;
    private double _totalFrameTime;
    
    public ECSPerformanceMonitor(SystemRoot systemRoot)
    {
        _systemRoot = systemRoot;
        _systemRoot.SetMonitorPerf(true);
    }
    
    public void StartFrame()
    {
        _stopwatch.Restart();
    }
    
    public void EndFrame()
    {
        _stopwatch.Stop();
        var frameTime = _stopwatch.ElapsedMilliseconds;
        
        _frameCount++;
        _totalFrameTime += frameTime;
        
        var fps = 1000.0 / (frameTime - _lastFrameTime);
        _lastFrameTime = frameTime;
        
        if (_frameCount % 60 == 0) // 每60帧输出一次
        {
            LogPerformance();
        }
    }
    
    public void LogPerformance()
    {
        var avgFrameTime = _totalFrameTime / _frameCount;
        var avgFPS = 1000.0 / avgFrameTime;
        
        Console.WriteLine("=== ECS 性能统计 ===");
        Console.WriteLine($"平均帧时间: {avgFrameTime:F2}ms");
        Console.WriteLine($"平均FPS: {avgFPS:F1}");
        Console.WriteLine($"总帧数: {_frameCount}");
        
        // 获取系统性能日志
        var perfLog = _systemRoot.GetPerfLog();
        Console.WriteLine($"系统性能: {perfLog}");
        
        // 获取实体统计
        var stats = GetEntityStats();
        Console.WriteLine($"总实体数: {stats.TotalEntities}");
        Console.WriteLine($"区块实体: {stats.ChunkEntities}");
        Console.WriteLine($"方块实体: {stats.BlockEntities}");
        Console.WriteLine($"玩家实体: {stats.PlayerEntities}");
    }
    
    private EntityStats GetEntityStats()
    {
        return new EntityStats
        {
            TotalEntities = _systemRoot.Store.Count,
            ChunkEntities = _systemRoot.Store.Query<Chunk>().EntityCount,
            BlockEntities = _systemRoot.Store.Query<Block>().EntityCount,
            PlayerEntities = _systemRoot.Store.Query<Player>().EntityCount
        };
    }
    
    public void Reset()
    {
        _frameCount = 0;
        _totalFrameTime = 0;
        _lastFrameTime = 0;
    }
    
    public struct EntityStats
    {
        public int TotalEntities;
        public int ChunkEntities;
        public int BlockEntities;
        public int PlayerEntities;
    }
}
```

### 实体调试器

```csharp
// ✅ 实体调试工具
public class ECSEntityDebugger
{
    private readonly EntityStore _store;
    
    public ECSEntityDebugger(EntityStore store)
    {
        _store = store;
    }
    
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

### 调试命令系统

```csharp
// ✅ 调试命令系统
public class ECSDebugCommands
{
    private readonly ECSWorld _ecsWorld;
    private readonly ECSPerformanceMonitor _performanceMonitor;
    private readonly ECSEntityDebugger _entityDebugger;
    
    public ECSDebugCommands(ECSWorld ecsWorld)
    {
        _ecsWorld = ecsWorld;
        _performanceMonitor = new ECSPerformanceMonitor(ecsWorld.SystemRoot);
        _entityDebugger = new ECSEntityDebugger(ecsWorld.Store);
    }
    
    public void ExecuteCommand(string command)
    {
        switch (command.ToLower())
        {
            case "stats":
            case "stat":
                _performanceMonitor.LogPerformance();
                break;
                
            case "entities":
            case "ents":
                Console.WriteLine($"总实体数: {_ecsWorld.Store.Count}");
                break;
                
            case "players":
                var playerQuery = _ecsWorld.Store.Query<Player>();
                Console.WriteLine($"玩家实体数: {playerQuery.EntityCount}");
                foreach (var player in playerQuery.Entities)
                {
                    _entityDebugger.PrintEntityDetails(player);
                }
                break;
                
            case "blocks":
                var blockQuery = _ecsWorld.Store.Query<Block>();
                Console.WriteLine($"方块实体数: {blockQuery.EntityCount}");
                break;
                
            case "chunks":
                var chunkQuery = _ecsWorld.Store.Query<Chunk>();
                Console.WriteLine($"区块实体数: {chunkQuery.EntityCount}");
                break;
                
            case "check":
                _entityDebugger.CheckInvalidEntities();
                break;
                
            case "clear":
                _ecsWorld.Store.DeleteAllEntities();
                Console.WriteLine("已清除所有实体");
                break;
                
            case "help":
                PrintHelp();
                break;
                
            default:
                Console.WriteLine($"未知命令: {command}");
                PrintHelp();
                break;
        }
    }
    
    private void PrintHelp()
    {
        Console.WriteLine("可用命令:");
        Console.WriteLine("  stats/stat   - 显示性能统计");
        Console.WriteLine("  entities/ents - 显示实体总数");
        Console.WriteLine("  players      - 显示玩家实体详情");
        Console.WriteLine("  blocks       - 显示方块实体数");
        Console.WriteLine("  chunks       - 显示区块实体数");
        Console.WriteLine("  check        - 检查无效实体");
        Console.WriteLine("  clear        - 清除所有实体");
        Console.WriteLine("  help         - 显示帮助");
    }
}
```

## 🎯 最佳实践

### 组件设计原则

```csharp
// ✅ 好的组件设计：单一职责
public struct Position : IComponent
{
    public Vector3 Value;
    // 只负责存储位置信息
}

public struct Velocity : IComponent
{
    public Vector3 Value;
    // 只负责存储速度信息
}

public struct Player : IComponent
{
    public float MoveSpeed;
    public float LookSpeed;
    public bool IsGrounded;
    // 只负责玩家特定属性
}

// ❌ 避免的组件设计：多重职责
public struct MovementComponent : IComponent
{
    public Vector3 Position;  // 应该分离到Position组件
    public Vector3 Velocity;  // 应该分离到Velocity组件
    public float Speed;       // 应该分离到Player组件
}
```

### 系统设计原则

```csharp
// ✅ 系统应该专注于单一功能
public class PlayerMovementSystem : QuerySystem<Position, Velocity, Input, Player>
{
    // 只负责处理玩家移动
}

public class PlayerInputSystem : QuerySystem<Input, Player>
{
    // 只负责处理玩家输入
}

public class PhysicsSystem : QuerySystem<Position, Velocity, Physics>
{
    // 只负责处理物理模拟
}

// ❌ 避免多功能系统
public class PlayerEverythingSystem : QuerySystem<Position, Velocity, Input, Player, Health, Mana>
{
    // 同时处理移动、输入、生命值、法力值等
}
```

### 查询优化原则

```csharp
// ✅ 使用具体的组件类型
public class SpecificSystem : QuerySystem<Position, Velocity, Player>
{
    // 明确指定需要的组件类型
}

// ✅ 缓存查询结果
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

// ❌ 避免过于宽泛的查询
public class GeneralSystem : QuerySystem<IComponent>
{
    // 查询所有组件，性能很差
}

// ❌ 避免每次更新都创建新查询
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

### 内存管理原则

```csharp
// ✅ 重用数组和列表
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

// ❌ 避免频繁创建新数组
public Entity[] GetVisibleEntities()
{
    // 性能较差：每次都创建新数组
    var visibleEntities = new List<Entity>();
    // ... 填充数组
    return visibleEntities.ToArray();
}
```

## ❓ 常见问题

### Q: 如何创建自定义组件？

A: 实现 `IComponent` 接口的 `struct` 类型：

```csharp
public struct CustomComponent : IComponent
{
    public string Name;
    public int Value;
    public bool IsActive;
    
    public CustomComponent(string name, int value, bool isActive)
    {
        Name = name;
        Value = value;
        IsActive = isActive;
    }
}
```

### Q: 如何优化查询性能？

A: 使用 `ArchetypeQuery` 并缓存查询结果：

```csharp
// 在构造函数中初始化查询
private readonly ArchetypeQuery _playerQuery;

public MyClass(EntityStore store)
{
    _playerQuery = store.Query<Player, Position, Velocity>();
}

// 使用缓存的查询
foreach (var entity in _playerQuery.Entities)
{
    // 处理逻辑
}
```

### Q: 如何处理大量实体？

A: 使用批量操作和 `CommandBuffer`：

```csharp
// 批量创建实体
var commands = store.CreateCommandBuffer();
for (int i = 0; i < count; i++)
{
    var entity = commands.CreateEntity();
    commands.AddComponent(entity.Id, new Position(i, 0, i));
}
commands.Playback();
```

### Q: 如何调试ECS系统？

A: 启用性能监控和实体检查：

```csharp
// 启用性能监控
systemRoot.SetMonitorPerf(true);

// 获取性能日志
string perfLog = systemRoot.GetPerfLog();

// 使用调试工具
var debugger = new ECSEntityDebugger(store);
debugger.PrintEntityDetails(entity);
```

### Q: 如何处理组件缺失？

A: 使用 `TryGetComponent` 进行安全访问：

```csharp
// 安全的组件访问
if (entity.TryGetComponent<Position>(out var position))
{
    // 使用组件
}
else
{
    // 处理组件不存在的情况
}
```

### Q: 如何处理内存泄漏？

A: 使用 `struct` 组件，及时删除不需要的实体：

```csharp
// 使用 struct 组件减少 GC 压力
public struct Position : IComponent
{
    public Vector3 Value;
}

// 及时删除不需要的实体
entity.Dispose();
```

## 📚 总结

Friflo ECS 3.4.2 提供了高性能的实体组件系统实现，特别适合游戏开发。通过合理使用查询系统、批量操作和缓存优化，可以实现高效的实体管理。

### 关键要点

1. **使用 struct 组件**减少 GC 压力
2. **缓存查询结果**提高性能
3. **批量操作**优化实体创建
4. **错误处理**确保系统稳定性
5. **性能监控**及时发现瓶颈
6. **内存管理**避免内存泄漏

### 性能建议

- 对于大量实体，使用批量操作和 `CommandBuffer`
- 缓存常用的查询结果
- 使用对象池减少内存分配
- 定期监控性能指标
- 及时删除不需要的实体

### 扩展建议

- 实现自定义的 `SystemBase` 子类
- 使用 `ForEachEntity` 方法进行批量处理
- 实现组件间的依赖关系管理
- 添加序列化/反序列化支持

---

*本文档基于 MCGame 项目的实际实现，适用于 Friflo ECS 3.4.2 版本。*
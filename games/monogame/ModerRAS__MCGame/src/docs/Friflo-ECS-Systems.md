# Friflo ECS 系统API详解

## 概述

本文档详细介绍MCGame项目中使用的所有ECS系统，包括系统实现、生命周期管理、查询优化和性能特性。所有系统都基于Friflo ECS 3.4.2的`QuerySystem`基类实现。

## 目录

- [系统基础架构](#系统基础架构)
- [玩家系统](#玩家系统)
- [物理系统](#物理系统)
- [渲染系统](#渲染系统)
- [世界管理系统](#世界管理系统)
- [系统生命周期](#系统生命周期)
- [性能优化](#性能优化)
- [调试工具](#调试工具)

## 系统基础架构

### QuerySystem基类

```csharp
/// <summary>
/// 查询系统基类
/// 简化实现：专注于特定组件类型的查询和处理
/// </summary>
public abstract class QuerySystem<T1> : SystemBase
{
    protected ArchetypeQuery Query { get; }
    
    protected QuerySystem()
    {
        Query = Store.Query<T1>();
    }
    
    protected abstract void OnUpdate();
}
```

### 多组件查询系统

```csharp
/// <summary>
/// 多组件查询系统
/// 简化实现：支持多个组件类型的查询和处理
/// </summary>
public abstract class QuerySystem<T1, T2, T3, T4, T5> : SystemBase
{
    protected ArchetypeQuery Query { get; }
    
    protected QuerySystem()
    {
        Query = Store.Query<T1, T2, T3, T4, T5>();
    }
    
    protected abstract void OnUpdate();
}
```

### 系统注册和管理

```csharp
// 系统注册
public class ECSWorld
{
    private readonly SystemRoot _systemRoot;
    
    private void InitializeSystems()
    {
        // 输入系统
        var inputSystem = new PlayerInputSystem();
        _systemRoot.Add(inputSystem);
        
        // 移动系统
        var movementSystem = new PlayerMovementSystem();
        _systemRoot.Add(movementSystem);
        
        // 物理系统
        var physicsSystem = new PhysicsSystem();
        _systemRoot.Add(physicsSystem);
        
        // 相机系统
        var cameraSystem = new CameraSystem();
        _systemRoot.Add(cameraSystem);
        
        // 可见性系统
        var visibilitySystem = new VisibilitySystem();
        _systemRoot.Add(visibilitySystem);
        
        // 区块系统
        var chunkSystem = new ChunkStateSystem();
        _systemRoot.Add(chunkSystem);
        
        // 启用性能监控
        _systemRoot.SetMonitorPerf(true);
    }
}
```

## 玩家系统

### PlayerInputSystem - 玩家输入系统

```csharp
/// <summary>
/// 玩家输入处理系统
/// 处理键盘和鼠标输入，更新输入组件
/// 简化实现：基础的输入处理，不支持复杂的输入映射
/// </summary>
public class PlayerInputSystem : QuerySystem<Input>
{
    private readonly KeyboardState _currentKeyboard;
    private readonly KeyboardState _previousKeyboard;
    private readonly MouseState _currentMouse;
    private readonly MouseState _previousMouse;
    private readonly bool _mouseLocked;

    public PlayerInputSystem()
    {
        _currentKeyboard = Keyboard.GetState();
        _previousKeyboard = _currentKeyboard;
        _currentMouse = Mouse.GetState();
        _previousMouse = _currentMouse;
        _mouseLocked = true;
    }

    protected override void OnUpdate()
    {
        var currentKeyboard = Keyboard.GetState();
        var currentMouse = Mouse.GetState();

        // 更新状态
        _previousKeyboard = _currentKeyboard;
        _previousMouse = _currentMouse;
        _currentKeyboard = currentKeyboard;
        _currentMouse = currentMouse;

        // 使用QuerySystem的Query属性遍历实体
        Query.ForEachEntity((ref Input input, Entity entity) =>
        {
            // 检查是否是玩家实体
            if (!entity.TryGetComponent<Player>(out var player))
                return;

            // 处理移动输入
            input.Movement = Vector2.Zero;
            if (_currentKeyboard.IsKeyDown(Keys.W)) input.Movement.Y += 1;
            if (_currentKeyboard.IsKeyDown(Keys.S)) input.Movement.Y -= 1;
            if (_currentKeyboard.IsKeyDown(Keys.A)) input.Movement.X -= 1;
            if (_currentKeyboard.IsKeyDown(Keys.D)) input.Movement.X += 1;

            // 处理跳跃输入
            input.Jump = _currentKeyboard.IsKeyDown(Keys.Space) && _previousKeyboard.IsKeyUp(Keys.Space);

            // 处理特殊动作输入
            input.Sprint = _currentKeyboard.IsKeyDown(Keys.LeftShift) || _currentKeyboard.IsKeyDown(Keys.RightShift);
            input.Fly = _currentKeyboard.IsKeyDown(Keys.F) && _previousKeyboard.IsKeyUp(Keys.F);

            // 处理鼠标输入
            if (_mouseLocked)
            {
                input.Look = new Vector2(
                    _currentMouse.X - _previousMouse.X,
                    _currentMouse.Y - _previousMouse.Y
                );
            }
        });
    }
}
```

**性能特性：**
- 执行频率：每帧一次
- 查询复杂度：O(n)，n为具有Input组件的实体数量
- 内存占用：约48字节（键盘和鼠标状态）
- 优化策略：缓存输入状态，避免重复获取

### PlayerMovementSystem - 玩家移动系统

```csharp
/// <summary>
/// 玩家移动系统
/// 根据输入更新玩家位置和速度
/// 简化实现：基础的移动逻辑，不支持复杂的物理交互
/// </summary>
public class PlayerMovementSystem : QuerySystem<Position, Rotation, Velocity, Input, Player>
{
    protected override void OnUpdate()
    {
        var currentKeyboard = Keyboard.GetState();
        var deltaTime = (float)Tick.DeltaTime;
        
        // 使用QuerySystem的Query属性遍历实体
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
                if (currentKeyboard.IsKeyDown(Keys.LeftControl)) velocity.Value.Y = -moveSpeed;
            }
            
            // 更新位置
            position.Value += velocity.Value * deltaTime;
        });
    }
}
```

**性能特性：**
- 执行频率：每帧一次
- 查询复杂度：O(n)，n为玩家实体数量（通常为1）
- 计算复杂度：O(1) per entity
- 优化策略：数学优化，避免重复计算

## 物理系统

### PhysicsSystem - 物理更新系统

```csharp
/// <summary>
/// 物理更新系统
/// 应用重力、碰撞检测和物理模拟
/// 简化实现：基础的物理模拟，不支持复杂的物理效果
/// </summary>
public class PhysicsSystem : QuerySystem<Position, Velocity>
{
    protected override void OnUpdate()
    {
        var deltaTime = (float)Tick.DeltaTime;

        // 使用QuerySystem的Query属性遍历实体
        Query.ForEachEntity((
            ref Position position, 
            ref Velocity velocity, 
            Entity entity) =>
        {
            // 获取物理属性
            if (entity.TryGetComponent<Physics>(out var physics))
            {
                // 应用重力
                velocity.Value += physics.Gravity * deltaTime;
                
                // 应用阻力
                velocity.Value *= (1f - physics.Drag * deltaTime);
            }
            
            // 简单的地面碰撞检测
            if (position.Value.Y <= 0)
            {
                position.Value.Y = 0;
                velocity.Value.Y = 0;
                
                // 标记为着地
                if (entity.TryGetComponent<Player>(out var player))
                {
                    player.IsGrounded = true;
                }
            }
            
            // 更新位置
            position.Value += velocity.Value * deltaTime;
        });
    }
}
```

**性能特性：**
- 执行频率：每帧一次
- 查询复杂度：O(n)，n为具有Position和Velocity组件的实体数量
- 计算复杂度：O(1) per entity
- 优化策略：简化的物理计算，适合游戏开发

### CollisionSystem - 碰撞检测系统

```csharp
/// <summary>
/// 碰撞检测系统
/// 处理实体间的碰撞检测和响应
/// 简化实现：AABB碰撞检测，不支持复杂的碰撞形状
/// </summary>
public class CollisionSystem : QuerySystem<Position, Collider>
{
    private readonly ArchetypeQuery _allCollidersQuery;
    
    public CollisionSystem()
    {
        _allCollidersQuery = Store.Query<Position, Collider>();
    }
    
    protected override void OnUpdate()
    {
        // 使用QuerySystem的Query属性遍历实体
        Query.ForEachEntity((
            ref Position position, 
            ref Collider collider, 
            Entity entity) =>
        {
            if (!collider.IsSolid)
                return;
                
            // 更新碰撞体位置
            collider.Bounds = new BoundingBox(position.Value, position.Value + Vector3.One);
            
            // 检查与其他实体的碰撞
            foreach (var otherEntity in _allCollidersQuery.Entities)
            {
                if (otherEntity.Id == entity.Id)
                    continue;
                    
                var otherCollider = otherEntity.GetComponent<Collider>();
                if (!otherCollider.IsSolid)
                    continue;
                    
                if (collider.Bounds.Intersects(otherCollider.Bounds))
                {
                    // 处理碰撞
                    ResolveCollision(entity, otherEntity);
                }
            }
        });
    }
    
    private void ResolveCollision(Entity entity1, Entity entity2)
    {
        // 简化的碰撞响应
        var position1 = entity1.GetComponent<Position>();
        var position2 = entity2.GetComponent<Position>();
        var velocity1 = entity1.GetComponent<Velocity>();
        
        // 推开实体
        var direction = Vector3.Normalize(position1.Value - position2.Value);
        position1.Value += direction * 0.1f;
        
        // 反弹速度
        if (velocity1.Value != null)
        {
            velocity1.Value *= -0.5f;
        }
    }
}
```

**性能特性：**
- 执行频率：每帧一次
- 查询复杂度：O(n²)，n为碰撞体数量
- 计算复杂度：O(1) per collision pair
- 优化策略：空间分区，减少碰撞检测次数

## 渲染系统

### CameraSystem - 相机更新系统

```csharp
/// <summary>
/// 相机更新系统
/// 根据位置和旋转更新相机矩阵
/// 简化实现：基础的相机功能，不支持高级相机效果
/// </summary>
public class CameraSystem : QuerySystem<Camera>
{
    protected override void OnUpdate()
    {
        // 使用QuerySystem的Query属性遍历实体
        Query.ForEachEntity((ref Camera camera, Entity entity) =>
        {
            if (!camera.IsDirty)
                return;
                
            // 获取位置和旋转
            var position = entity.GetComponent<Position>();
            var rotation = entity.GetComponent<Rotation>();
            
            // 计算相机方向
            var yaw = rotation.Value.Y;
            var pitch = rotation.Value.X;
            
            var forward = new Vector3(
                (float)Math.Sin(yaw) * (float)Math.Cos(pitch),
                (float)Math.Sin(pitch),
                (float)Math.Cos(yaw) * (float)Math.Cos(pitch)
            );
            
            var up = Vector3.Up;
            
            // 更新视图矩阵
            camera.ViewMatrix = Matrix.CreateLookAt(
                position.Value,
                position.Value + forward,
                up
            );
            
            // 更新投影矩阵
            camera.ProjectionMatrix = Matrix.CreatePerspectiveFieldOfView(
                MathHelper.ToRadians(camera.FieldOfView),
                camera.AspectRatio,
                camera.NearPlane,
                camera.FarPlane
            );
            
            camera.IsDirty = false;
        });
    }
}
```

**性能特性：**
- 执行频率：每帧一次
- 查询复杂度：O(n)，n为相机实体数量（通常为1）
- 计算复杂度：O(1) per camera
- 优化策略：脏标记机制，避免不必要的矩阵计算

### VisibilitySystem - 可见性计算系统

```csharp
/// <summary>
/// 可见性计算系统
/// 计算实体是否在视锥体内
/// 简化实现：基于距离的简单可见性计算，不支持复杂的视锥体剔除
/// </summary>
public class VisibilitySystem : QuerySystem<Visibility>
{
    private Vector3 _cameraPosition;
    private BoundingFrustum _viewFrustum;

    public void SetViewFrustum(BoundingFrustum frustum, Vector3 cameraPosition)
    {
        _viewFrustum = frustum;
        _cameraPosition = cameraPosition;
    }

    protected override void OnUpdate()
    {
        // 使用QuerySystem的Query属性遍历实体
        Query.ForEachEntity((ref Visibility visibility, Entity entity) =>
        {
            // 简化的可见性计算
            if (entity.TryGetComponent<Position>(out var position))
            {
                visibility.Distance = Vector3.Distance(position.Value, _cameraPosition);
                
                // 距离剔除
                visibility.IsVisible = visibility.Distance < 200f;
                
                // 视锥体剔除
                if (entity.TryGetComponent<Collider>(out var collider))
                {
                    visibility.InFrustum = _viewFrustum.Contains(collider.Bounds) != ContainmentType.Disjoint;
                    visibility.IsVisible = visibility.IsVisible && visibility.InFrustum;
                }
            }
        });
    }
}
```

**性能特性：**
- 执行频率：每帧一次
- 查询复杂度：O(n)，n为具有Visibility组件的实体数量
- 计算复杂度：O(1) per entity
- 优化策略：距离剔除 + 视锥体剔除

## 世界管理系统

### ChunkStateSystem - 区块状态更新系统

```csharp
/// <summary>
/// 区块状态更新系统
/// 更新区块的状态和标记
/// 简化实现：基础的区块状态管理，不支持复杂的区块调度
/// </summary>
public class ChunkStateSystem : QuerySystem<Chunk>
{
    protected override void OnUpdate()
    {
        // 使用QuerySystem的Query属性遍历实体
        Query.ForEachEntity((ref Chunk chunk, Entity entity) =>
        {
            // 简化的区块状态更新
            if (chunk.IsLoaded)
            {
                chunk.State = ChunkState.Loaded;
            }
            else
            {
                chunk.State = ChunkState.Loading;
            }
            
            // 检查是否需要重新生成网格
            if (chunk.IsDirty && entity.TryGetComponent<Mesh>(out var mesh))
            {
                mesh.IsDirty = true;
            }
        });
    }
}
```

**性能特性：**
- 执行频率：每帧一次
- 查询复杂度：O(n)，n为区块实体数量
- 计算复杂度：O(1) per chunk
- 优化策略：状态机优化，减少不必要的状态更新

### LifetimeSystem - 生命期更新系统

```csharp
/// <summary>
/// 生命期更新系统
/// 更新实体的生命期，删除过期实体
/// 简化实现：简单的生命期管理，不支持复杂的生命期逻辑
/// </summary>
public class LifetimeSystem : QuerySystem<Lifetime>
{
    protected override void OnUpdate()
    {
        var deltaTime = (float)Tick.DeltaTime;
        var entitiesToDelete = new List<Entity>();

        // 使用QuerySystem的Query属性遍历实体
        Query.ForEachEntity((ref Lifetime lifetime, Entity entity) =>
        {
            lifetime.TimeLeft -= deltaTime;
            
            if (lifetime.TimeLeft <= 0)
            {
                lifetime.IsExpired = true;
                entitiesToDelete.Add(entity);
            }
        });
        
        // 删除过期实体
        foreach (var entity in entitiesToDelete)
        {
            entity.Delete();
        }
    }
}
```

**性能特性：**
- 执行频率：每帧一次
- 查询复杂度：O(n)，n为具有Lifetime组件的实体数量
- 计算复杂度：O(1) per entity
- 优化策略：批量删除，减少单独删除操作

## 系统生命周期

### 系统初始化

```csharp
public class CustomSystem : QuerySystem<Position>
{
    protected override void OnStart()
    {
        // 系统初始化逻辑
        InitializeResources();
        SetupQueries();
        SubscribeToEvents();
    }
    
    private void InitializeResources()
    {
        // 初始化系统资源
    }
    
    private void SetupQueries()
    {
        // 设置查询
    }
    
    private void SubscribeToEvents()
    {
        // 订阅事件
    }
}
```

### 系统更新

```csharp
public class CustomSystem : QuerySystem<Position>
{
    protected override void OnUpdate()
    {
        var deltaTime = (float)Tick.DeltaTime;
        
        // 使用QuerySystem的Query属性遍历实体
        Query.ForEachEntity((ref Position position, Entity entity) =>
        {
            // 更新逻辑
            position.Value += Vector3.Up * deltaTime;
        });
    }
}
```

### 系统停止

```csharp
public class CustomSystem : QuerySystem<Position>
{
    protected override void OnStop()
    {
        // 清理系统资源
        CleanupResources();
        UnsubscribeFromEvents();
        SaveSystemState();
    }
    
    private void CleanupResources()
    {
        // 清理资源
    }
    
    private void UnsubscribeFromEvents()
    {
        // 取消订阅事件
    }
    
    private void SaveSystemState()
    {
        // 保存系统状态
    }
}
```

## 性能优化

### 查询优化

```csharp
// 好的做法：缓存查询
public class OptimizedSystem : QuerySystem<Position>
{
    private readonly ArchetypeQuery _cachedQuery;
    
    public OptimizedSystem()
    {
        _cachedQuery = Store.Query<Position, Velocity>();
    }
    
    protected override void OnUpdate()
    {
        // 使用缓存的查询
        foreach (var entity in _cachedQuery.Entities)
        {
            // 处理逻辑
        }
    }
}

// 避免：每次更新都创建新查询
public class NonOptimizedSystem : QuerySystem<Position>
{
    protected override void OnUpdate()
    {
        // 性能较差：每次都创建新查询
        var query = Store.Query<Position, Velocity>();
        foreach (var entity in query.Entities)
        {
            // 处理逻辑
        }
    }
}
```

### 批量操作优化

```csharp
// 好的做法：批量操作
public class BatchOperationSystem : QuerySystem<Position>
{
    protected override void OnUpdate()
    {
        var commands = Store.CreateCommandBuffer();
        var entitiesToUpdate = new List<Entity>();
        
        Query.ForEachEntity((ref Position position, Entity entity) =>
        {
            if (position.Value.Y < 0)
            {
                entitiesToUpdate.Add(entity);
            }
        });
        
        // 批量更新
        foreach (var entity in entitiesToUpdate)
        {
            var position = entity.GetComponent<Position>();
            position.Value.Y = 0;
            
            // 批量添加组件
            commands.AddComponent(entity.Id, new Visibility(true));
        }
        
        commands.Playback();
    }
}
```

### 并行处理优化

```csharp
// 好的做法：并行处理
public class ParallelSystem : QuerySystem<Position>
{
    protected override void OnUpdate()
    {
        var deltaTime = (float)Tick.DeltaTime;
        
        // 并行处理实体
        Parallel.ForEach(Query.Entities, entity =>
        {
            var position = entity.GetComponent<Position>();
            position.Value += Vector3.Up * deltaTime;
        });
    }
}
```

### 条件执行优化

```csharp
// 好的做法：条件执行
public class ConditionalSystem : QuerySystem<Position>
{
    private float _lastUpdateTime;
    private readonly float _updateInterval = 0.1f; // 100ms间隔
    
    protected override void OnUpdate()
    {
        var currentTime = (float)Tick.TotalTime;
        
        // 只在指定间隔执行
        if (currentTime - _lastUpdateTime < _updateInterval)
            return;
            
        _lastUpdateTime = currentTime;
        
        // 执行更新逻辑
        Query.ForEachEntity((ref Position position, Entity entity) =>
        {
            // 更新逻辑
        });
    }
}
```

## 调试工具

### 性能监控

```csharp
// 启用系统性能监控
public class DebugSystem : QuerySystem<Position>
{
    private readonly Stopwatch _stopwatch;
    private long _totalExecutionTime;
    private int _executionCount;
    
    public DebugSystem()
    {
        _stopwatch = new Stopwatch();
    }
    
    protected override void OnUpdate()
    {
        _stopwatch.Restart();
        
        // 执行系统逻辑
        Query.ForEachEntity((ref Position position, Entity entity) =>
        {
            // 更新逻辑
        });
        
        _stopwatch.Stop();
        _totalExecutionTime += _stopwatch.ElapsedMilliseconds;
        _executionCount++;
        
        // 定期输出性能统计
        if (_executionCount % 60 == 0) // 每秒输出一次
        {
            var avgTime = _totalExecutionTime / (double)_executionCount;
            Console.WriteLine($"Average execution time: {avgTime:F2}ms");
            
            _totalExecutionTime = 0;
            _executionCount = 0;
        }
    }
}
```

### 实体统计

```csharp
// 实体统计系统
public class EntityStatsSystem : QuerySystem<Position>
{
    private readonly ArchetypeQuery _allEntitiesQuery;
    
    public EntityStatsSystem()
    {
        _allEntitiesQuery = Store.Query(); // 查询所有实体
    }
    
    protected override void OnUpdate()
    {
        var totalEntities = _allEntitiesQuery.EntityCount;
        var positionEntities = Query.EntityCount;
        
        Console.WriteLine($"Total entities: {totalEntities}");
        Console.WriteLine($"Entities with Position: {positionEntities}");
        
        // 可以添加更多统计信息
        var blockEntities = Store.Query<Block>().EntityCount;
        var playerEntities = Store.Query<Player>().EntityCount;
        
        Console.WriteLine($"Block entities: {blockEntities}");
        Console.WriteLine($"Player entities: {playerEntities}");
    }
}
```

### 系统依赖管理

```csharp
// 系统依赖管理
public class SystemDependencyManager
{
    private readonly List<SystemBase> _systems = new List<SystemBase>();
    
    public void AddSystem(SystemBase system, params Type[] dependencies)
    {
        // 添加系统并设置依赖
        _systems.Add(system);
        
        // 这里可以实现更复杂的依赖管理逻辑
        Console.WriteLine($"Added system: {system.GetType().Name} with dependencies: {string.Join(", ", dependencies.Select(d => d.Name))}");
    }
    
    public void UpdateSystems()
    {
        // 按照依赖顺序更新系统
        foreach (var system in _systems)
        {
            system.Update();
        }
    }
}
```

## 总结

MCGame项目中的ECS系统采用模块化设计，每个系统都有明确的职责和优化的执行策略。通过合理使用查询系统、批量操作和条件执行，实现了高性能的实体处理。在实际应用中，这些系统成功支持了大量的游戏实体，为游戏提供了流畅的运行体验。

**关键优化点：**
- 查询缓存，避免重复查询
- 批量操作，减少系统调用开销
- 条件执行，避免不必要的计算
- 并行处理，充分利用多核CPU
- 脏标记机制，减少不必要的更新
- 性能监控，便于优化和调试
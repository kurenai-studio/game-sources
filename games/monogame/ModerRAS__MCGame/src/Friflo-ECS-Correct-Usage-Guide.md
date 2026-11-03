# Friflo ECS 3.4.2 正确API使用指南

## 📋 问题分析

根据项目代码分析，发现了以下主要API使用问题：

### 1. 实体删除方法问题
- ❌ 错误方法：`entity.Delete()`、`entity.DeleteEntity()`、`store.DeleteEntity(entity.Id)`
- ✅ 正确方法：`entity.Dispose()`

### 2. 查询遍历问题
- ❌ 错误方法：`query.GetEnumerator()`、`foreach (var entity in query)`
- ✅ 正确方法：`foreach (var entity in query.Entities)`

### 3. 查询构建问题
- ❌ 错误方法：`new ArchetypeQuery<T>()`
- ✅ 正确方法：`store.Query<T>()`

## 🎯 正确的API使用方式

### 1. 实体管理

#### 创建实体
```csharp
// ✅ 正确的实体创建方式
var entity = _store.CreateEntity(
    new Block(blockType),
    new Position(position),
    new Visibility(true)
);

// ✅ 空实体创建
var emptyEntity = _store.CreateEntity();

// ✅ 逐个添加组件
emptyEntity.AddComponent(new Block(blockType));
emptyEntity.AddComponent(new Position(position));
```

#### 删除实体
```csharp
// ✅ 正确的实体删除方式
entity.Dispose();

// ✅ 批量删除实体
foreach (var entity in entities)
{
    entity.Dispose();
}

// ✅ 清空所有实体
_store.DeleteAllEntities();
```

### 2. 查询系统

#### 创建查询
```csharp
// ✅ 正确的查询创建方式
var blockQuery = _store.Query<Block, Position, Visibility>();
var playerQuery = _store.Query<Player, Position, Velocity>();

// ✅ 单组件查询
var positionQuery = _store.Query<Position>();

// ✅ 缓存查询（推荐）
private readonly ArchetypeQuery _blockQuery;

public MyClass(EntityStore store)
{
    _blockQuery = store.Query<Block, Position>();
}
```

#### 遍历查询结果
```csharp
// ✅ 正确的遍历方式
foreach (var entity in query.Entities)
{
    var block = entity.GetComponent<Block>();
    var position = entity.GetComponent<Position>();
    var visibility = entity.GetComponent<Visibility>();
    
    // 处理实体
}

// ✅ 获取查询统计
int entityCount = query.EntityCount;
Entity[] entities = query.Entities;

// ✅ 在QuerySystem中使用
protected override void OnUpdate()
{
    foreach (var entity in Query.Entities)
    {
        var component = entity.GetComponent<TComponent>();
        // 处理逻辑
    }
}
```

### 3. 组件操作

#### 安全的组件访问
```csharp
// ✅ 安全的组件访问
if (entity.TryGetComponent<Position>(out var position))
{
    position.Value = new Vector3(1, 2, 3);
}

// ✅ 直接访问（确定组件存在时）
var position = entity.GetComponent<Position>();

// ✅ 添加组件
entity.AddComponent(new Block(blockType));

// ✅ 移除组件
entity.RemoveComponent<Block>();

// ✅ 检查组件是否存在
bool hasPosition = entity.HasComponent<Position>();
```

### 4. 系统管理

#### QuerySystem使用
```csharp
// ✅ 正确的QuerySystem实现
public class PlayerMovementSystem : QuerySystem<Position, Velocity, Input, Player>
{
    protected override void OnUpdate()
    {
        // 使用Query属性遍历实体
        foreach (var entity in Query.Entities)
        {
            var position = entity.GetComponent<Position>();
            var velocity = entity.GetComponent<Velocity>();
            var input = entity.GetComponent<Input>();
            var player = entity.GetComponent<Player>();
            
            // 处理逻辑
        }
    }
}
```

#### SystemRoot管理
```csharp
// ✅ 正确的SystemRoot使用
var systemRoot = new SystemRoot(store);
systemRoot.Add(new PlayerInputSystem());
systemRoot.Add(new PlayerMovementSystem());

// 启用性能监控
systemRoot.SetMonitorPerf(true);

// 更新系统
systemRoot.Update(gameTime);

// 获取性能日志
string perfLog = systemRoot.GetPerfLog();
```

## 🔧 实际项目示例

### 1. ECSBlockManager正确实现
```csharp
public class ECSBlockManager
{
    private readonly EntityStore _store;
    private readonly ArchetypeQuery _blockQuery;
    private readonly Dictionary<Vector3, Entity> _blockEntities;

    public ECSBlockManager(EntityStore store)
    {
        _store = store;
        _blockQuery = _store.Query<Block, Position>();
        _blockEntities = new Dictionary<Vector3, Entity>();
    }

    public Entity SetBlock(BlockType blockType, Vector3 position)
    {
        // 检查是否已存在方块
        if (_blockEntities.TryGetValue(position, out var existingEntity))
        {
            // 更新现有方块
            var blockComponent = existingEntity.GetComponent<Block>();
            blockComponent.Type = blockType;
            return existingEntity;
        }

        // 创建新的方块实体
        var newEntity = _store.CreateEntity(
            new Block(blockType),
            new Position(position),
            new Visibility(true)
        );

        _blockEntities[position] = newEntity;
        return newEntity;
    }

    public bool RemoveBlock(Vector3 position)
    {
        if (_blockEntities.TryGetValue(position, out var entity))
        {
            _blockEntities.Remove(position);
            entity.Dispose(); // 正确的删除方式
            return true;
        }
        return false;
    }

    public void ClearAll()
    {
        foreach (var block in _blockQuery.Entities)
        {
            block.Dispose(); // 正确的删除方式
        }
        _blockEntities.Clear();
    }
}
```

### 2. 正确的查询遍历示例
```csharp
public class ChunkManager
{
    private readonly EntityStore _store;
    private readonly ArchetypeQuery _chunkQuery;

    public ChunkManager(EntityStore store)
    {
        _store = store;
        _chunkQuery = _store.Query<Chunk, Position>();
    }

    public Entity[] GetVisibleChunks()
    {
        var visibleChunks = new List<Entity>();
        
        // 正确的遍历方式
        foreach (var entity in _chunkQuery.Entities)
        {
            var chunk = entity.GetComponent<Chunk>();
            var visibility = entity.GetComponent<Visibility>();
            
            if (visibility.IsVisible)
            {
                visibleChunks.Add(entity);
            }
        }
        
        return visibleChunks.ToArray();
    }
}
```

### 3. 正确的系统实现示例
```csharp
public class VisibilitySystem : QuerySystem<Visibility>
{
    private Vector3 _cameraPosition;

    public void SetCameraPosition(Vector3 position)
    {
        _cameraPosition = position;
    }

    protected override void OnUpdate()
    {
        // 正确的遍历方式
        foreach (var entity in Query.Entities)
        {
            var visibility = entity.GetComponent<Visibility>();
            
            if (entity.TryGetComponent<Position>(out var position))
            {
                var distance = Vector3.Distance(position.Value, _cameraPosition);
                visibility.IsVisible = distance < 200f;
                visibility.Distance = distance;
            }
        }
    }
}
```

## ⚠️ 重要注意事项

### 1. 避免的常见错误
```csharp
// ❌ 错误的删除方式
entity.Delete();
entity.DeleteEntity();
store.DeleteEntity(entity.Id);

// ❌ 错误的查询遍历
foreach (var entity in query) // 错误
foreach (var entity in query.GetEnumerator()) // 错误

// ❌ 错误的查询创建
var query = new ArchetypeQuery<Block>(); // 错误
```

### 2. 性能优化建议
```csharp
// ✅ 缓存查询
private readonly ArchetypeQuery _cachedQuery;

// ✅ 重用集合
private readonly List<Entity> _entityList = new List<Entity>();

// ✅ 批量操作
var commands = _store.CreateCommandBuffer();
// 批量创建/删除
commands.Playback();
```

### 3. 错误处理
```csharp
// ✅ 安全的组件访问
if (entity.TryGetComponent<Position>(out var position))
{
    // 安全使用
}

// ✅ 检查实体有效性
if (entity.IsAlive)
{
    // 安全操作
}
```

## 📚 总结

### 关键要点
1. **实体删除**：使用 `entity.Dispose()` 而非 `entity.Delete()`
2. **查询遍历**：使用 `foreach (var entity in query.Entities)` 
3. **查询创建**：使用 `store.Query<T>()` 而非构造函数
4. **组件访问**：优先使用 `TryGetComponent` 进行安全访问
5. **性能优化**：缓存查询结果，重用集合对象

### 下一步行动
1. 更新所有使用错误API的代码
2. 重新编译项目验证修复
3. 运行测试确保功能正常
4. 进行性能测试验证优化效果

---

*本指南基于MCGame项目的实际实现和测试结果，适用于Friflo ECS 3.4.2版本。*
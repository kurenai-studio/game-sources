# Friflo ECS 实际代码示例

## 概述

本文档提供MCGame项目中Friflo ECS 3.4.2的完整实际代码示例，涵盖从基础实体管理到高级系统实现的各个方面。所有示例都基于项目实际代码，可直接用于开发参考。

## 目录

- [基础示例](#基础示例)
- [组件示例](#组件示例)
- [系统示例](#系统示例)
- [查询示例](#查询示例)
- [管理器示例](#管理器示例)
- [渲染示例](#渲染示例)
- [性能优化示例](#性能优化示例)
- [完整游戏循环示例](#完整游戏循环示例)

## 基础示例

### 1. 创建ECS世界

```csharp
/// <summary>
/// 创建ECS世界的完整示例
/// 简化实现：专注于核心功能，不包含复杂的初始化逻辑
/// </summary>
public class ECSWorldExample
{
    private readonly EntityStore _store;
    private readonly SystemRoot _systemRoot;
    private readonly ArchetypeQuery _playerQuery;
    private readonly ArchetypeQuery _blockQuery;
    private readonly ArchetypeQuery _chunkQuery;
    
    public Entity PlayerEntity { get; private set; }
    
    public ECSWorldExample()
    {
        // 创建实体存储
        _store = new EntityStore();
        
        // 创建系统根节点
        _systemRoot = new SystemRoot(_store);
        
        // 初始化系统
        InitializeSystems();
        
        // 创建查询
        _playerQuery = _store.Query<Player, Position, Velocity>();
        _blockQuery = _store.Query<Block, Position, Visibility>();
        _chunkQuery = _store.Query<Chunk, Position>();
        
        // 创建默认玩家
        CreateDefaultPlayer();
    }
    
    private void InitializeSystems()
    {
        // 输入系统
        _systemRoot.Add(new PlayerInputSystem());
        
        // 移动系统
        _systemRoot.Add(new PlayerMovementSystem());
        
        // 物理系统
        _systemRoot.Add(new PhysicsSystem());
        
        // 相机系统
        _systemRoot.Add(new CameraSystem());
        
        // 可见性系统
        _systemRoot.Add(new VisibilitySystem());
        
        // 区块系统
        _systemRoot.Add(new ChunkStateSystem());
        
        // 启用性能监控
        _systemRoot.SetMonitorPerf(true);
    }
    
    private void CreateDefaultPlayer()
    {
        PlayerEntity = _store.CreateEntity(
            new Position(0, 64, 0),
            new Rotation(0, 0, 0),
            new Velocity(0, 0, 0),
            new Player(10f, 0.1f, 8f),
            new Camera(75f, 16f/9f, 0.1f, 1000f),
            new Input(),
            new Physics(1f, 0.1f),
            new Collider(new BoundingBox(new Vector3(-0.3f, 0, -0.3f), new Vector3(0.3f, 1.8f, 0.3f))),
            new Visibility(true)
        );
    }
    
    public void Update(GameTime gameTime)
    {
        // 更新Tick时间
        Tick.UpdateTime(gameTime);
        
        // 更新所有系统
        _systemRoot.Update(gameTime);
    }
    
    public void Destroy()
    {
        _systemRoot.Dispose();
        _store.DeleteAllEntities();
    }
}
```

### 2. 基础实体操作

```csharp
/// <summary>
/// 基础实体操作示例
/// 简化实现：展示基本的实体CRUD操作
/// </summary>
public class EntityOperationsExample
{
    private readonly EntityStore _store;
    
    public EntityOperationsExample()
    {
        _store = new EntityStore();
    }
    
    /// <summary>
    /// 创建方块实体
    /// </summary>
    public Entity CreateBlockEntity(BlockType blockType, Vector3 position)
    {
        return _store.CreateEntity(
            new Block(blockType),
            new Position(position),
            new Visibility(true),
            new Collider(new BoundingBox(position, position + Vector3.One)),
            new Lighting(15)
        );
    }
    
    /// <summary>
    /// 创建玩家实体
    /// </summary>
    public Entity CreatePlayerEntity(Vector3 position)
    {
        return _store.CreateEntity(
            new Position(position),
            new Rotation(0, 0, 0),
            new Velocity(0, 0, 0),
            new Player(10f, 0.1f, 8f),
            new Camera(75f, 16f/9f, 0.1f, 1000f),
            new Input(),
            new Physics(1f, 0.1f),
            new Collider(new BoundingBox(new Vector3(-0.3f, 0, -0.3f), new Vector3(0.3f, 1.8f, 0.3f))),
            new Visibility(true)
        );
    }
    
    /// <summary>
    /// 创建区块实体
    /// </summary>
    public Entity CreateChunkEntity(ChunkPosition position)
    {
        var worldPos = position.ToWorldPosition(16);
        var bounds = new BoundingBox(worldPos, worldPos + new Vector3(16, 256, 16));
        
        return _store.CreateEntity(
            new Chunk(position),
            new Position(worldPos),
            new Mesh(bounds),
            new Visibility(true),
            new Collider(bounds, false)
        );
    }
    
    /// <summary>
    /// 批量创建实体
    /// </summary>
    public Entity[] CreateEntitiesBatch(int count)
    {
        var entities = new Entity[count];
        var commands = _store.CreateCommandBuffer();
        var random = new Random();
        
        for (int i = 0; i < count; i++)
        {
            var position = new Vector3(
                random.Next(-100, 100),
                random.Next(0, 256),
                random.Next(-100, 100)
            );
            
            var blockType = (BlockType)random.Next(0, 16);
            
            var entity = commands.CreateEntity();
            commands.AddComponent(entity.Id, new Block(blockType));
            commands.AddComponent(entity.Id, new Position(position));
            commands.AddComponent(entity.Id, new Visibility(true));
            commands.AddComponent(entity.Id, new Collider(new BoundingBox(position, position + Vector3.One)));
            commands.AddComponent(entity.Id, new Lighting(15));
            
            entities[i] = entity;
        }
        
        commands.Playback();
        return entities;
    }
    
    /// <summary>
    /// 删除实体
    /// </summary>
    public void DeleteEntity(Entity entity)
    {
        entity.Delete();
    }
    
    /// <summary>
    /// 批量删除实体
    /// </summary>
    public void DeleteEntitiesBatch(Entity[] entities)
    {
        var commands = _store.CreateCommandBuffer();
        
        foreach (var entity in entities)
        {
            commands.DeleteEntity(entity.Id);
        }
        
        commands.Playback();
    }
    
    /// <summary>
    /// 获取实体统计信息
    /// </summary>
    public EntityStats GetEntityStats()
    {
        return new EntityStats
        {
            TotalEntities = _store.Count,
            BlockEntities = _store.Query<Block>().EntityCount,
            PlayerEntities = _store.Query<Player>().EntityCount,
            ChunkEntities = _store.Query<Chunk>().EntityCount
        };
    }
    
    public struct EntityStats
    {
        public int TotalEntities;
        public int BlockEntities;
        public int PlayerEntities;
        public int ChunkEntities;
    }
}
```

## 组件示例

### 1. 自定义组件定义

```csharp
/// <summary>
/// 自定义组件定义示例
/// 简化实现：展示各种组件类型的定义方式
/// </summary>
namespace MCGame.ECS.Components.Examples
{
    /// <summary>
    /// 生命值组件
    /// </summary>
    public struct Health : IComponent
    {
        public float Current;
        public float Maximum;
        public float RegenerationRate;
        
        public Health(float maximum = 100f, float regenerationRate = 1f)
        {
            Current = maximum;
            Maximum = maximum;
            RegenerationRate = regenerationRate;
        }
        
        public void TakeDamage(float damage)
        {
            Current = Math.Max(0, Current - damage);
        }
        
        public void Heal(float amount)
        {
            Current = Math.Min(Maximum, Current + amount);
        }
        
        public void Regenerate(float deltaTime)
        {
            Heal(RegenerationRate * deltaTime);
        }
        
        public float HealthPercentage => Current / Maximum;
    }
    
    /// <summary>
    /// 经验值组件
    /// </summary>
    public struct Experience : IComponent
    {
        public int Current;
        public int ToNextLevel;
        public int Level;
        public float ExperienceMultiplier;
        
        public Experience(int startingLevel = 1)
        {
            Current = 0;
            Level = startingLevel;
            ToNextLevel = CalculateRequiredExperience(startingLevel);
            ExperienceMultiplier = 1f;
        }
        
        public void AddExperience(int amount)
        {
            Current += (int)(amount * ExperienceMultiplier);
            
            while (Current >= ToNextLevel)
            {
                LevelUp();
            }
        }
        
        private void LevelUp()
        {
            Current -= ToNextLevel;
            Level++;
            ToNextLevel = CalculateRequiredExperience(Level);
        }
        
        private static int CalculateRequiredExperience(int level)
        {
            return level * 100; // 简单的经验公式
        }
        
        public float ExperiencePercentage => (float)Current / ToNextLevel;
    }
    
    /// <summary>
    /// AI状态组件
    /// </summary>
    public struct AIState : IComponent
    {
        public AIStateType CurrentState;
        public float StateTimer;
        public Entity TargetEntity;
        public Vector3 TargetPosition;
        public float DetectionRange;
        public float AttackRange;
        public float MoveSpeed;
        
        public AIState(AIStateType initialState = AIStateType.Idle)
        {
            CurrentState = initialState;
            StateTimer = 0f;
            TargetEntity = default;
            TargetPosition = Vector3.Zero;
            DetectionRange = 20f;
            AttackRange = 2f;
            MoveSpeed = 3f;
        }
        
        public void UpdateState(float deltaTime)
        {
            StateTimer += deltaTime;
        }
        
        public void ChangeState(AIStateType newState)
        {
            CurrentState = newState;
            StateTimer = 0f;
        }
        
        public bool HasTarget => TargetEntity.Id != 0;
    }
    
    /// <summary>
    /// AI状态类型
    /// </summary>
    public enum AIStateType
    {
        Idle,
        Patrol,
        Chase,
        Attack,
        Flee,
        Dead
    }
    
    /// <summary>
    /// 动画组件
    /// </summary>
    public struct Animation : IComponent
    {
        public string CurrentAnimation;
        public float AnimationTime;
        public float AnimationSpeed;
        public bool IsLooping;
        public bool IsPlaying;
        
        public Animation(string initialAnimation = "idle")
        {
            CurrentAnimation = initialAnimation;
            AnimationTime = 0f;
            AnimationSpeed = 1f;
            IsLooping = true;
            IsPlaying = true;
        }
        
        public void PlayAnimation(string animationName, bool loop = true)
        {
            CurrentAnimation = animationName;
            AnimationTime = 0f;
            IsLooping = loop;
            IsPlaying = true;
        }
        
        public void StopAnimation()
        {
            IsPlaying = false;
        }
        
        public void Update(float deltaTime)
        {
            if (IsPlaying)
            {
                AnimationTime += deltaTime * AnimationSpeed;
            }
        }
    }
    
    /// <summary>
    /// 声音组件
    /// </summary>
    public struct Sound : IComponent
    {
        public string CurrentSound;
        public float Volume;
        public float Pitch;
        public bool IsLooping;
        public bool IsPlaying;
        public float[] SoundQueue;
        public int CurrentSoundIndex;
        
        public Sound()
        {
            CurrentSound = "";
            Volume = 1f;
            Pitch = 1f;
            IsLooping = false;
            IsPlaying = false;
            SoundQueue = Array.Empty<string>();
            CurrentSoundIndex = 0;
        }
        
        public void PlaySound(string soundName, bool loop = false)
        {
            CurrentSound = soundName;
            IsLooping = loop;
            IsPlaying = true;
        }
        
        public void StopSound()
        {
            IsPlaying = false;
        }
        
        public void QueueSound(string soundName)
        {
            Array.Resize(ref SoundQueue, SoundQueue.Length + 1);
            SoundQueue[^1] = soundName;
        }
        
        public void PlayNextSound()
        {
            if (CurrentSoundIndex < SoundQueue.Length)
            {
                PlaySound(SoundQueue[CurrentSoundIndex]);
                CurrentSoundIndex++;
            }
        }
    }
}
```

### 2. 组件操作示例

```csharp
/// <summary>
/// 组件操作示例
/// 简化实现：展示各种组件操作方法
/// </summary>
public class ComponentOperationsExample
{
    private readonly EntityStore _store;
    
    public ComponentOperationsExample()
    {
        _store = new EntityStore();
    }
    
    /// <summary>
    /// 添加组件示例
    /// </summary>
    public void AddComponentsExample()
    {
        var entity = _store.CreateEntity();
        
        // 添加单个组件
        entity.AddComponent(new Position(0, 0, 0));
        
        // 添加多个组件
        entity.AddComponent(new Velocity(1, 0, 0));
        entity.AddComponent(new Visibility(true));
        entity.AddComponent(new Health(100f));
        
        // 批量添加组件
        var commands = _store.CreateCommandBuffer();
        commands.AddComponent(entity.Id, new Experience(1));
        commands.AddComponent(entity.Id, new AIState());
        commands.AddComponent(entity.Id, new Animation());
        commands.Playback();
    }
    
    /// <summary>
    /// 获取组件示例
    /// </summary>
    public void GetComponentExample(Entity entity)
    {
        // 安全获取组件
        if (entity.TryGetComponent<Position>(out var position))
        {
            Console.WriteLine($"Position: {position.Value}");
        }
        
        // 直接获取组件（可能抛出异常）
        try
        {
            var velocity = entity.GetComponent<Velocity>();
            Console.WriteLine($"Velocity: {velocity.Value}");
        }
        catch (ComponentNotFoundException)
        {
            Console.WriteLine("Velocity component not found");
        }
        
        // 获取多个组件
        if (entity.TryGetComponent<Health>(out var health) &&
            entity.TryGetComponent<Experience>(out var experience))
        {
            Console.WriteLine($"Health: {health.Current}/{health.Maximum}");
            Console.WriteLine($"Experience: Level {experience.Level}");
        }
    }
    
    /// <summary>
    /// 更新组件示例
    /// </summary>
    public void UpdateComponentExample(Entity entity, float deltaTime)
    {
        // 更新位置
        if (entity.TryGetComponent<Position>(out var position))
        {
            position.Value += new Vector3(1, 0, 0) * deltaTime;
        }
        
        // 更新生命值
        if (entity.TryGetComponent<Health>(out var health))
        {
            health.Regenerate(deltaTime);
        }
        
        // 更新AI状态
        if (entity.TryGetComponent<AIState>(out var aiState))
        {
            aiState.UpdateState(deltaTime);
        }
        
        // 更新动画
        if (entity.TryGetComponent<Animation>(out var animation))
        {
            animation.Update(deltaTime);
        }
    }
    
    /// <summary>
    /// 移除组件示例
    /// </summary>
    public void RemoveComponentsExample(Entity entity)
    {
        // 移除单个组件
        entity.RemoveComponent<Sound>();
        
        // 批量移除组件
        var commands = _store.CreateCommandBuffer();
        commands.RemoveComponent<Animation>(entity.Id);
        commands.RemoveComponent<AIState>(entity.Id);
        commands.Playback();
        
        // 移除所有组件（保留实体）
        entity.RemoveAllComponents();
    }
    
    /// <summary>
    /// 组件验证示例
    /// </summary>
    public bool ValidateEntityComponents(Entity entity)
    {
        // 检查必需组件
        if (!entity.HasComponent<Position>())
            return false;
        
        if (!entity.HasComponent<Visibility>())
            return false;
        
        // 检查组件数据有效性
        if (entity.TryGetComponent<Health>(out var health))
        {
            if (health.Current < 0 || health.Maximum <= 0)
                return false;
        }
        
        if (entity.TryGetComponent<Position>(out var position))
        {
            if (float.IsNaN(position.Value.X) || float.IsInfinity(position.Value.X))
                return false;
        }
        
        return true;
    }
    
    /// <summary>
    /// 组件查询示例
    /// </summary>
    public Entity[] FindEntitiesByComponents()
    {
        // 查询具有特定组件的实体
        var playerQuery = _store.Query<Player, Position, Velocity>();
        var blockQuery = _store.Query<Block, Position, Visibility>();
        var healthQuery = _store.Query<Health>();
        
        // 复杂查询
        var playerWithHealth = _store.Query<Player, Health>();
        var visibleBlocks = _store.Query<Block, Position, Visibility>();
        
        // 处理查询结果
        var result = new List<Entity>();
        
        foreach (var entity in playerWithHealth.Entities)
        {
            var health = entity.GetComponent<Health>();
            if (health.Current > 50) // 只选择健康值大于50的玩家
            {
                result.Add(entity);
            }
        }
        
        return result.ToArray();
    }
}
```

## 系统示例

### 1. 自定义系统实现

```csharp
/// <summary>
/// 自定义系统实现示例
/// 简化实现：展示各种系统类型的实现方式
/// </summary>
namespace MCGame.ECS.Systems.Examples
{
    /// <summary>
    /// 生命值更新系统
    /// </summary>
    public class HealthSystem : QuerySystem<Health>
    {
        protected override void OnUpdate()
        {
            var deltaTime = (float)Tick.DeltaTime;
            
            Query.ForEachEntity((ref Health health, Entity entity) =>
            {
                // 生命值再生
                health.Regenerate(deltaTime);
                
                // 检查是否死亡
                if (health.Current <= 0)
                {
                    HandleDeath(entity);
                }
            });
        }
        
        private void HandleDeath(Entity entity)
        {
            // 添加死亡状态
            if (!entity.HasComponent<DeathState>())
            {
                entity.AddComponent(new DeathState());
            }
            
            // 停止动画
            if (entity.TryGetComponent<Animation>(out var animation))
            {
                animation.PlayAnimation("death", false);
            }
            
            // 播放死亡声音
            if (entity.TryGetComponent<Sound>(out var sound))
            {
                sound.PlaySound("death");
            }
        }
    }
    
    /// <summary>
    /// 经验值系统
    /// </summary>
    public class ExperienceSystem : QuerySystem<Experience>
    {
        protected override void OnUpdate()
        {
            Query.ForEachEntity((ref Experience experience, Entity entity) =>
            {
                // 检查升级
                if (experience.Current >= experience.ToNextLevel)
                {
                    HandleLevelUp(entity, experience);
                }
            });
        }
        
        private void HandleLevelUp(Entity entity, Experience experience)
        {
            // 升级逻辑
            experience.LevelUp();
            
            // 增加生命值
            if (entity.TryGetComponent<Health>(out var health))
            {
                health.Maximum += 10;
                health.Current = health.Maximum;
            }
            
            // 播放升级音效
            if (entity.TryGetComponent<Sound>(out var sound))
            {
                sound.PlaySound("levelup");
            }
            
            // 显示升级特效
            if (entity.TryGetComponent<Animation>(out var animation))
            {
                animation.PlayAnimation("levelup", false);
            }
        }
    }
    
    /// <summary>
    /// AI系统
    /// </summary>
    public class AISystem : QuerySystem<AIState, Position, Velocity>
    {
        private readonly ArchetypeQuery _playerQuery;
        
        public AISystem()
        {
            _playerQuery = Store.Query<Player, Position>();
        }
        
        protected override void OnUpdate()
        {
            var deltaTime = (float)Tick.DeltaTime;
            var playerPosition = GetPlayerPosition();
            
            Query.ForEachEntity((
                ref AIState aiState, 
                ref Position position, 
                ref Velocity velocity, 
                Entity entity) =>
            {
                aiState.UpdateState(deltaTime);
                
                switch (aiState.CurrentState)
                {
                    case AIStateType.Idle:
                        UpdateIdleState(entity, aiState, position, playerPosition);
                        break;
                    case AIStateType.Patrol:
                        UpdatePatrolState(entity, aiState, position, velocity, deltaTime);
                        break;
                    case AIStateType.Chase:
                        UpdateChaseState(entity, aiState, position, velocity, playerPosition, deltaTime);
                        break;
                    case AIStateType.Attack:
                        UpdateAttackState(entity, aiState, position, playerPosition, deltaTime);
                        break;
                    case AIStateType.Flee:
                        UpdateFleeState(entity, aiState, position, velocity, playerPosition, deltaTime);
                        break;
                }
            });
        }
        
        private Vector3 GetPlayerPosition()
        {
            foreach (var player in _playerQuery.Entities)
            {
                return player.GetComponent<Position>().Value;
            }
            return Vector3.Zero;
        }
        
        private void UpdateIdleState(Entity entity, AIState aiState, Position position, Vector3 playerPosition)
        {
            var distanceToPlayer = Vector3.Distance(position.Value, playerPosition);
            
            if (distanceToPlayer <= aiState.DetectionRange)
            {
                aiState.ChangeState(AIStateType.Chase);
                aiState.TargetPosition = playerPosition;
            }
        }
        
        private void UpdatePatrolState(Entity entity, AIState aiState, Position position, Velocity velocity, float deltaTime)
        {
            // 巡逻逻辑
            if (aiState.StateTimer > 3f)
            {
                // 随机选择新的巡逻点
                var random = new Random();
                aiState.TargetPosition = position.Value + new Vector3(
                    random.Next(-10, 10),
                    0,
                    random.Next(-10, 10)
                );
                aiState.StateTimer = 0f;
            }
            
            // 移动到目标位置
            MoveTowardsTarget(position, velocity, aiState.TargetPosition, aiState.MoveSpeed, deltaTime);
        }
        
        private void UpdateChaseState(Entity entity, AIState aiState, Position position, Velocity velocity, Vector3 playerPosition, float deltaTime)
        {
            var distanceToPlayer = Vector3.Distance(position.Value, playerPosition);
            
            if (distanceToPlayer <= aiState.AttackRange)
            {
                aiState.ChangeState(AIStateType.Attack);
            }
            else if (distanceToPlayer > aiState.DetectionRange * 1.5f)
            {
                aiState.ChangeState(AIStateType.Idle);
            }
            else
            {
                MoveTowardsTarget(position, velocity, playerPosition, aiState.MoveSpeed * 1.5f, deltaTime);
            }
        }
        
        private void UpdateAttackState(Entity entity, AIState aiState, Position position, Vector3 playerPosition, float deltaTime)
        {
            var distanceToPlayer = Vector3.Distance(position.Value, playerPosition);
            
            if (distanceToPlayer > aiState.AttackRange)
            {
                aiState.ChangeState(AIStateType.Chase);
            }
            else if (aiState.StateTimer > 1f)
            {
                // 执行攻击
                PerformAttack(entity, playerPosition);
                aiState.StateTimer = 0f;
            }
        }
        
        private void UpdateFleeState(Entity entity, AIState aiState, Position position, Velocity velocity, Vector3 playerPosition, float deltaTime)
        {
            var distanceToPlayer = Vector3.Distance(position.Value, playerPosition);
            
            if (distanceToPlayer > aiState.DetectionRange * 2f)
            {
                aiState.ChangeState(AIStateType.Idle);
            }
            else
            {
                // 远离玩家
                var fleeDirection = Vector3.Normalize(position.Value - playerPosition);
                velocity.Value = fleeDirection * aiState.MoveSpeed * 2f;
            }
        }
        
        private void MoveTowardsTarget(Position position, Velocity velocity, Vector3 target, float speed, float deltaTime)
        {
            var direction = Vector3.Normalize(target - position.Value);
            velocity.Value = direction * speed;
        }
        
        private void PerformAttack(Entity entity, Vector3 targetPosition)
        {
            // 攻击逻辑
            if (entity.TryGetComponent<Animation>(out var animation))
            {
                animation.PlayAnimation("attack", false);
            }
            
            if (entity.TryGetComponent<Sound>(out var sound))
            {
                sound.PlaySound("attack");
            }
        }
    }
    
    /// <summary>
    /// 动画系统
    /// </summary>
    public class AnimationSystem : QuerySystem<Animation, Velocity>
    {
        protected override void OnUpdate()
        {
            var deltaTime = (float)Tick.DeltaTime;
            
            Query.ForEachEntity((
                ref Animation animation, 
                ref Velocity velocity, 
                Entity entity) =>
            {
                animation.Update(deltaTime);
                
                // 根据速度更新动画状态
                if (velocity.Value.LengthSquared() > 0.1f)
                {
                    if (animation.CurrentAnimation != "walk" && animation.CurrentAnimation != "run")
                    {
                        animation.PlayAnimation("walk");
                    }
                }
                else
                {
                    if (animation.CurrentAnimation != "idle")
                    {
                        animation.PlayAnimation("idle");
                    }
                }
            });
        }
    }
    
    /// <summary>
    /// 声音系统
    /// </summary>
    public class SoundSystem : QuerySystem<Sound>
    {
        protected override void OnUpdate()
        {
            Query.ForEachEntity((ref Sound sound, Entity entity) =>
            {
                if (sound.IsPlaying)
                {
                    // 处理声音播放逻辑
                    // 这里可以集成实际的音频系统
                    
                    if (!sound.IsLooping && sound.SoundQueue.Length > 0)
                    {
                        sound.PlayNextSound();
                    }
                }
            });
        }
    }
    
    /// <summary>
    /// 死亡状态组件
    /// </summary>
    public struct DeathState : IComponent
    {
        public float DeathTimer;
        public bool ShouldRespawn;
        public float RespawnTime;
        
        public DeathState(bool shouldRespawn = false, float respawnTime = 5f)
        {
            DeathTimer = 0f;
            ShouldRespawn = shouldRespawn;
            RespawnTime = respawnTime;
        }
    }
}
```

### 2. 系统组合示例

```csharp
/// <summary>
/// 系统组合示例
/// 简化实现：展示如何组合多个系统实现复杂功能
/// </summary>
public class SystemCombinationExample
{
    private readonly EntityStore _store;
    private readonly SystemRoot _systemRoot;
    
    public SystemCombinationExample()
    {
        _store = new EntityStore();
        _systemRoot = new SystemRoot(_store);
        
        InitializeGameSystems();
    }
    
    private void InitializeGameSystems()
    {
        // 基础系统
        _systemRoot.Add(new PlayerInputSystem());
        _systemRoot.Add(new PlayerMovementSystem());
        _systemRoot.Add(new PhysicsSystem());
        _systemRoot.Add(new CameraSystem());
        
        // 游戏逻辑系统
        _systemRoot.Add(new HealthSystem());
        _systemRoot.Add(new ExperienceSystem());
        _systemRoot.Add(new AISystem());
        _systemRoot.Add(new AnimationSystem());
        _systemRoot.Add(new SoundSystem());
        
        // 渲染系统
        _systemRoot.Add(new VisibilitySystem());
        _systemRoot.Add(new ChunkStateSystem());
        
        // 启用性能监控
        _systemRoot.SetMonitorPerf(true);
    }
    
    /// <summary>
    /// 创建敌人实体
    /// </summary>
    public Entity CreateEnemyEntity(Vector3 position)
    {
        return _store.CreateEntity(
            new Position(position),
            new Velocity(0, 0, 0),
            new Health(100f, 2f),
            new Experience(1),
            new AIState(AIStateType.Idle),
            new Animation("idle"),
            new Sound(),
            new Visibility(true),
            new Collider(new BoundingBox(position, position + new Vector3(1, 2, 1)))
        );
    }
    
    /// <summary>
    /// 创建可交互的NPC实体
    /// </summary>
    public Entity CreateNPCEntity(Vector3 position, string npcName)
    {
        return _store.CreateEntity(
            new Position(position),
            new Velocity(0, 0, 0),
            new Health(50f, 1f),
            new Experience(1),
            new AIState(AIStateType.Idle),
            new Animation("idle"),
            new Sound(),
            new NPCComponent(npcName),
            new Visibility(true),
            new Collider(new BoundingBox(position, position + new Vector3(1, 2, 1)))
        );
    }
    
    /// <summary>
    /// NPC组件
    /// </summary>
    public struct NPCComponent : IComponent
    {
        public string Name;
        public string[] Dialogues;
        public int CurrentDialogueIndex;
        public bool IsInteracting;
        
        public NPCComponent(string name)
        {
            Name = name;
            Dialogues = new[] { "Hello!", "How are you?", "Nice weather today!" };
            CurrentDialogueIndex = 0;
            IsInteracting = false;
        }
        
        public string GetCurrentDialogue()
        {
            if (Dialogues.Length == 0)
                return "...";
            
            var dialogue = Dialogues[CurrentDialogueIndex];
            CurrentDialogueIndex = (CurrentDialogueIndex + 1) % Dialogues.Length;
            return dialogue;
        }
    }
    
    /// <summary>
    /// 交互系统
    /// </summary>
    public class InteractionSystem : QuerySystem<NPCComponent, Position>
    {
        private readonly ArchetypeQuery _playerQuery;
        
        public InteractionSystem()
        {
            _playerQuery = Store.Query<Player, Position>();
        }
        
        protected override void OnUpdate()
        {
            var playerPosition = GetPlayerPosition();
            
            Query.ForEachEntity((
                ref NPCComponent npc, 
                ref Position position, 
                Entity entity) =>
            {
                var distance = Vector3.Distance(position.Value, playerPosition);
                var interactionRange = 3f;
                
                // 检查玩家是否在交互范围内
                if (distance <= interactionRange)
                {
                    if (!npc.IsInteracting)
                    {
                        StartInteraction(entity, npc);
                    }
                }
                else
                {
                    if (npc.IsInteracting)
                    {
                        StopInteraction(entity, npc);
                    }
                }
            });
        }
        
        private Vector3 GetPlayerPosition()
        {
            foreach (var player in _playerQuery.Entities)
            {
                return player.GetComponent<Position>().Value;
            }
            return Vector3.Zero;
        }
        
        private void StartInteraction(Entity entity, NPCComponent npc)
        {
            npc.IsInteracting = true;
            
            // 播放交互动画
            if (entity.TryGetComponent<Animation>(out var animation))
            {
                animation.PlayAnimation("wave", false);
            }
            
            // 显示交互提示
            Console.WriteLine($"Press E to interact with {npc.Name}");
        }
        
        private void StopInteraction(Entity entity, NPCComponent npc)
        {
            npc.IsInteracting = false;
            
            // 恢复默认动画
            if (entity.TryGetComponent<Animation>(out var animation))
            {
                animation.PlayAnimation("idle");
            }
        }
    }
    
    public void Update(GameTime gameTime)
    {
        Tick.UpdateTime(gameTime);
        _systemRoot.Update(gameTime);
    }
}
```

## 查询示例

### 1. 高级查询模式

```csharp
/// <summary>
/// 高级查询模式示例
/// 简化实现：展示各种复杂的查询模式
/// </summary>
public class AdvancedQueryExamples
{
    private readonly EntityStore _store;
    private readonly QueryCache _queryCache;
    
    public AdvancedQueryExamples()
    {
        _store = new EntityStore();
        _queryCache = new QueryCache(_store);
    }
    
    /// <summary>
    /// 查询缓存实现
    /// </summary>
    public class QueryCache
    {
        private readonly EntityStore _store;
        private readonly Dictionary<string, ArchetypeQuery> _queryCache = new Dictionary<string, ArchetypeQuery>();
        
        public QueryCache(EntityStore store)
        {
            _store = store;
        }
        
        public ArchetypeQuery GetQuery<T1>() where T1 : struct, IComponent
        {
            var key = $"{typeof(T1).Name}";
            return GetOrCreateQuery(key, () => _store.Query<T1>());
        }
        
        public ArchetypeQuery GetQuery<T1, T2>() 
            where T1 : struct, IComponent 
            where T2 : struct, IComponent
        {
            var key = $"{typeof(T1).Name}_{typeof(T2).Name}";
            return GetOrCreateQuery(key, () => _store.Query<T1, T2>());
        }
        
        public ArchetypeQuery GetQuery<T1, T2, T3>() 
            where T1 : struct, IComponent 
            where T2 : struct, IComponent
            where T3 : struct, IComponent
        {
            var key = $"{typeof(T1).Name}_{typeof(T2).Name}_{typeof(T3).Name}";
            return GetOrCreateQuery(key, () => _store.Query<T1, T2, T3>());
        }
        
        private ArchetypeQuery GetOrCreateQuery(string key, Func<ArchetypeQuery> queryFactory)
        {
            if (!_queryCache.TryGetValue(key, out var query))
            {
                query = queryFactory();
                _queryCache[key] = query;
            }
            return query;
        }
    }
    
    /// <summary>
    /// 条件查询示例
    /// </summary>
    public Entity[] FindEntitiesByCondition<T>(Func<Entity, bool> condition) where T : struct, IComponent
    {
        var query = _queryCache.GetQuery<T>();
        var result = new List<Entity>();
        
        foreach (var entity in query.Entities)
        {
            if (condition(entity))
            {
                result.Add(entity);
            }
        }
        
        return result.ToArray();
    }
    
    /// <summary>
    /// 范围查询示例
    /// </summary>
    public Entity[] FindEntitiesInRange<T>(Vector3 center, float radius) where T : struct, IComponent
    {
        var query = _queryCache.GetQuery<T, Position>();
        var result = new List<Entity>();
        var radiusSquared = radius * radius;
        
        foreach (var entity in query.Entities)
        {
            var position = entity.GetComponent<Position>();
            var distanceSquared = Vector3.DistanceSquared(position.Value, center);
            
            if (distanceSquared <= radiusSquared)
            {
                result.Add(entity);
            }
        }
        
        return result.ToArray();
    }
    
    /// <summary>
    /// 可见性查询示例
    /// </summary>
    public Entity[] FindVisibleEntities<T>(BoundingFrustum frustum, Vector3 cameraPosition, float maxDistance) where T : struct, IComponent
    {
        var query = _queryCache.GetQuery<T, Position, Visibility>();
        var result = new List<Entity>();
        
        foreach (var entity in query.Entities)
        {
            var position = entity.GetComponent<Position>();
            var visibility = entity.GetComponent<Visibility>();
            
            var distance = Vector3.Distance(position.Value, cameraPosition);
            var isVisible = visibility.IsVisible && distance <= maxDistance;
            
            if (isVisible)
            {
                // 检查视锥体
                if (entity.TryGetComponent<Collider>(out var collider))
                {
                    if (frustum.Contains(collider.Bounds) != ContainmentType.Disjoint)
                    {
                        result.Add(entity);
                    }
                }
                else
                {
                    result.Add(entity);
                }
            }
        }
        
        return result.ToArray();
    }
    
    /// <summary>
    /// 状态查询示例
    /// </summary>
    public Entity[] FindEntitiesByState<TState>(TState state) where TState : struct, IComponent
    {
        var query = _queryCache.GetQuery<TState>();
        var result = new List<Entity>();
        
        foreach (var entity in query.Entities)
        {
            var stateComponent = entity.GetComponent<TState>();
            
            // 使用反射比较状态值
            if (EqualityComparer<TState>.Default.Equals(stateComponent, state))
            {
                result.Add(entity);
            }
        }
        
        return result.ToArray();
    }
    
    /// <summary>
    /// 分组查询示例
    /// </summary>
    public Dictionary<BlockType, List<Entity>> GroupEntitiesByBlockType()
    {
        var query = _queryCache.GetQuery<Block>();
        var groups = new Dictionary<BlockType, List<Entity>>();
        
        foreach (var entity in query.Entities)
        {
            var block = entity.GetComponent<Block>();
            
            if (!groups.TryGetValue(block.Type, out var entityList))
            {
                entityList = new List<Entity>();
                groups[block.Type] = entityList;
            }
            
            entityList.Add(entity);
        }
        
        return groups;
    }
    
    /// <summary>
    /// 排序查询示例
    /// </summary>
    public Entity[] FindEntitiesSortedByDistance<T>(Vector3 center) where T : struct, IComponent
    {
        var query = _queryCache.GetQuery<T, Position>();
        var entities = new List<EntityWithDistance>();
        
        foreach (var entity in query.Entities)
        {
            var position = entity.GetComponent<Position>();
            var distance = Vector3.Distance(position.Value, center);
            
            entities.Add(new EntityWithDistance(entity, distance));
        }
        
        // 按距离排序
        entities.Sort((a, b) => a.Distance.CompareTo(b.Distance));
        
        return entities.Select(e => e.Entity).ToArray();
    }
    
    private struct EntityWithDistance
    {
        public Entity Entity;
        public float Distance;
        
        public EntityWithDistance(Entity entity, float distance)
        {
            Entity = entity;
            Distance = distance;
        }
    }
    
    /// <summary>
    /// 复合查询示例
    /// </summary>
    public Entity[] FindEntitiesByMultipleConditions(
        Vector3 center, 
        float radius, 
        BlockType blockType, 
        bool isVisible = true)
    {
        var query = _queryCache.GetQuery<Block, Position, Visibility>();
        var result = new List<Entity>();
        var radiusSquared = radius * radius;
        
        foreach (var entity in query.Entities)
        {
            var block = entity.GetComponent<Block>();
            var position = entity.GetComponent<Position>();
            var visibility = entity.GetComponent<Visibility>();
            
            // 检查所有条件
            var distanceSquared = Vector3.DistanceSquared(position.Value, center);
            var matchesBlockType = block.Type == blockType;
            var matchesVisibility = visibility.IsVisible == isVisible;
            var matchesDistance = distanceSquared <= radiusSquared;
            
            if (matchesBlockType && matchesVisibility && matchesDistance)
            {
                result.Add(entity);
            }
        }
        
        return result.ToArray();
    }
    
    /// <summary>
    /// 分页查询示例
    /// </summary>
    public Entity[] FindEntitiesPaginated<T>(int pageIndex, int pageSize) where T : struct, IComponent
    {
        var query = _queryCache.GetQuery<T>();
        var allEntities = query.Entities.ToArray();
        
        var startIndex = pageIndex * pageSize;
        var endIndex = Math.Min(startIndex + pageSize, allEntities.Length);
        
        if (startIndex >= allEntities.Length)
        {
            return Array.Empty<Entity>();
        }
        
        var result = new Entity[endIndex - startIndex];
        Array.Copy(allEntities, startIndex, result, 0, result.Length);
        
        return result;
    }
    
    /// <summary>
    /// 统计查询示例
    /// </summary>
    public QueryStatistics GetQueryStatistics<T>() where T : struct, IComponent
    {
        var query = _queryCache.GetQuery<T>();
        var statistics = new QueryStatistics();
        
        foreach (var entity in query.Entities)
        {
            statistics.TotalCount++;
            
            // 统计组件数据
            if (typeof(T) == typeof(Block))
            {
                var block = entity.GetComponent<Block>();
                statistics.BlockTypeCounts[block.Type]++;
            }
            else if (typeof(T) == typeof(Health))
            {
                var health = entity.GetComponent<Health>();
                if (health.Current <= 0)
                {
                    statistics.DeadCount++;
                }
                else if (health.Current < health.Maximum * 0.3f)
                {
                    statistics.LowHealthCount++;
                }
            }
        }
        
        return statistics;
    }
    
    public class QueryStatistics
    {
        public int TotalCount;
        public int DeadCount;
        public int LowHealthCount;
        public Dictionary<BlockType, int> BlockTypeCounts = new Dictionary<BlockType, int>();
    }
}
```

### 2. 查询优化示例

```csharp
/// <summary>
/// 查询优化示例
/// 简化实现：展示各种查询优化技术
/// </summary>
public class QueryOptimizationExamples
{
    private readonly EntityStore _store;
    private readonly Dictionary<string, CachedQuery> _cachedQueries = new Dictionary<string, CachedQuery>();
    
    public QueryOptimizationExamples()
    {
        _store = new EntityStore();
    }
    
    /// <summary>
    /// 缓存查询结果
    /// </summary>
    public class CachedQuery
    {
        private readonly ArchetypeQuery _query;
        private Entity[] _cachedResults;
        private float _lastUpdateTime;
        private readonly float _updateInterval;
        private readonly Func<Entity, bool> _filter;
        
        public CachedQuery(ArchetypeQuery query, float updateInterval = 0.1f, Func<Entity, bool> filter = null)
        {
            _query = query;
            _updateInterval = updateInterval;
            _filter = filter;
            _cachedResults = Array.Empty<Entity>();
        }
        
        public Entity[] GetResults(float currentTime)
        {
            if (currentTime - _lastUpdateTime >= _updateInterval)
            {
                UpdateCache();
                _lastUpdateTime = currentTime;
            }
            
            return _cachedResults;
        }
        
        private void UpdateCache()
        {
            if (_filter == null)
            {
                _cachedResults = _query.Entities.ToArray();
            }
            else
            {
                var filtered = new List<Entity>();
                foreach (var entity in _query.Entities)
                {
                    if (_filter(entity))
                    {
                        filtered.Add(entity);
                    }
                }
                _cachedResults = filtered.ToArray();
            }
        }
    }
    
    /// <summary>
    /// 创建优化的查询
    /// </summary>
    public CachedQuery CreateOptimizedQuery<T>(float updateInterval = 0.1f, Func<Entity, bool> filter = null) where T : struct, IComponent
    {
        var query = _store.Query<T>();
        return new CachedQuery(query, updateInterval, filter);
    }
    
    /// <summary>
    /// 空间分区查询优化
    /// </summary>
    public class SpatialQueryOptimizer
    {
        private readonly Dictionary<Vector2Int, List<Entity>> _spatialGrid = new Dictionary<Vector2Int, List<Entity>>();
        private readonly int _cellSize;
        
        public SpatialQueryOptimizer(int cellSize = 16)
        {
            _cellSize = cellSize;
        }
        
        public void AddEntity(Entity entity)
        {
            if (!entity.TryGetComponent<Position>(out var position))
                return;
                
            var cell = GetCellPosition(position.Value);
            
            if (!_spatialGrid.TryGetValue(cell, out var entities))
            {
                entities = new List<Entity>();
                _spatialGrid[cell] = entities;
            }
            
            entities.Add(entity);
        }
        
        public void RemoveEntity(Entity entity)
        {
            if (!entity.TryGetComponent<Position>(out var position))
                return;
                
            var cell = GetCellPosition(position.Value);
            
            if (_spatialGrid.TryGetValue(cell, out var entities))
            {
                entities.Remove(entity);
            }
        }
        
        public Entity[] FindEntitiesInRange(Vector3 center, float radius)
        {
            var result = new List<Entity>();
            var radiusSquared = radius * radius;
            var cellRadius = (int)Math.Ceiling(radius / _cellSize);
            var centerCell = GetCellPosition(center);
            
            // 检查周围的格子
            for (int x = -cellRadius; x <= cellRadius; x++)
            {
                for (int z = -cellRadius; z <= cellRadius; z++)
                {
                    var cell = new Vector2Int(centerCell.X + x, centerCell.Y + z);
                    
                    if (_spatialGrid.TryGetValue(cell, out var entities))
                    {
                        foreach (var entity in entities)
                        {
                            var position = entity.GetComponent<Position>();
                            var distanceSquared = Vector3.DistanceSquared(position.Value, center);
                            
                            if (distanceSquared <= radiusSquared)
                            {
                                result.Add(entity);
                            }
                        }
                    }
                }
            }
            
            return result.ToArray();
        }
        
        private Vector2Int GetCellPosition(Vector3 position)
        {
            return new Vector2Int(
                (int)Math.Floor(position.X / _cellSize),
                (int)Math.Floor(position.Z / _cellSize)
            );
        }
        
        private struct Vector2Int
        {
            public int X;
            public int Y;
            
            public Vector2Int(int x, int y)
            {
                X = x;
                Y = y;
            }
        }
    }
    
    /// <summary>
    /// 查询批处理优化
    /// </summary>
    public class QueryBatchProcessor
    {
        private readonly EntityStore _store;
        private readonly int _batchSize;
        
        public QueryBatchProcessor(EntityStore store, int batchSize = 100)
        {
            _store = store;
            _batchSize = batchSize;
        }
        
        public void ProcessEntitiesInBatches<T>(Action<Entity[]> processAction) where T : struct, IComponent
        {
            var query = _store.Query<T>();
            var allEntities = query.Entities.ToArray();
            
            for (int i = 0; i < allEntities.Length; i += _batchSize)
            {
                var batchSize = Math.Min(_batchSize, allEntities.Length - i);
                var batch = new Entity[batchSize];
                Array.Copy(allEntities, i, batch, 0, batchSize);
                
                processAction(batch);
            }
        }
        
        public void ProcessEntitiesInBatchesParallel<T>(Action<Entity[]> processAction) where T : struct, IComponent
        {
            var query = _store.Query<T>();
            var allEntities = query.Entities.ToArray();
            
            var batches = new List<Entity[]>();
            for (int i = 0; i < allEntities.Length; i += _batchSize)
            {
                var batchSize = Math.Min(_batchSize, allEntities.Length - i);
                var batch = new Entity[batchSize];
                Array.Copy(allEntities, i, batch, 0, batchSize);
                batches.Add(batch);
            }
            
            Parallel.ForEach(batches, batch =>
            {
                processAction(batch);
            });
        }
    }
    
    /// <summary>
    /// 查询性能监控
    /// </summary>
    public class QueryPerformanceMonitor
    {
        private readonly Dictionary<string, QueryPerformanceStats> _stats = new Dictionary<string, QueryPerformanceStats>();
        
        public void RecordQuery(string queryName, double executionTime, int resultCount)
        {
            if (!_stats.TryGetValue(queryName, out var stat))
            {
                stat = new QueryPerformanceStats();
                _stats[queryName] = stat;
            }
            
            stat.RecordExecution(executionTime, resultCount);
        }
        
        public void PrintReport()
        {
            Console.WriteLine("=== Query Performance Report ===");
            
            foreach (var kvp in _stats)
            {
                var stats = kvp.Value;
                Console.WriteLine($"{kvp.Key}:");
                Console.WriteLine($"  Average Time: {stats.AverageTime:F2}ms");
                Console.WriteLine($"  Min Time: {stats.MinTime:F2}ms");
                Console.WriteLine($"  Max Time: {stats.MaxTime:F2}ms");
                Console.WriteLine($"  Average Results: {stats.AverageResults:F1}");
                Console.WriteLine($"  Total Executions: {stats.ExecutionCount}");
                Console.WriteLine();
            }
        }
        
        public class QueryPerformanceStats
        {
            public double TotalTime;
            public double MinTime = double.MaxValue;
            public double MaxTime = double.MinValue;
            public int ExecutionCount;
            public int TotalResults;
            
            public double AverageTime => ExecutionCount > 0 ? TotalTime / ExecutionCount : 0;
            public double AverageResults => ExecutionCount > 0 ? (double)TotalResults / ExecutionCount : 0;
            
            public void RecordExecution(double executionTime, int resultCount)
            {
                TotalTime += executionTime;
                MinTime = Math.Min(MinTime, executionTime);
                MaxTime = Math.Max(MaxTime, executionTime);
                ExecutionCount++;
                TotalResults += resultCount;
            }
        }
    }
}
```

## 完整游戏循环示例

```csharp
/// <summary>
/// 完整游戏循环示例
/// 简化实现：展示ECS在完整游戏循环中的应用
/// </summary>
public class ECSCGameLoop : Game
{
    private readonly ECSWorld _ecsWorld;
    private readonly ECSRenderer _ecsRenderer;
    private readonly GraphicsDeviceManager _graphics;
    private readonly PerformanceMonitor _performanceMonitor;
    
    public ECSCGameLoop()
    {
        _graphics = new GraphicsDeviceManager(this);
        Content.RootDirectory = "Content";
        IsMouseVisible = false;
        
        // 初始化ECS系统
        _ecsWorld = new ECSWorld();
        _ecsRenderer = new ECSRenderer(GraphicsDevice);
        _performanceMonitor = new PerformanceMonitor();
        
        // 设置窗口参数
        Window.AllowUserResizing = true;
        Window.Title = "MCGame with ECS";
    }
    
    protected override void Initialize()
    {
        // 初始化游戏世界
        InitializeGameWorld();
        
        base.Initialize();
    }
    
    private void InitializeGameWorld()
    {
        // 创建初始地形
        CreateInitialTerrain();
        
        // 创建一些测试实体
        CreateTestEntities();
        
        // 设置初始相机位置
        var playerPosition = _ecsWorld.PlayerEntity.GetComponent<Position>();
        playerPosition.Value = new Vector3(0, 64, 0);
    }
    
    private void CreateInitialTerrain()
    {
        // 创建地面
        for (int x = -20; x <= 20; x++)
        {
            for (int z = -20; z <= 20; z++)
            {
                _ecsWorld.Store.CreateEntity(
                    new Block(BlockType.Grass),
                    new Position(x, 0, z),
                    new Visibility(true),
                    new Collider(new BoundingBox(new Vector3(x, 0, z), new Vector3(x + 1, 1, z + 1))),
                    new Lighting(15)
                );
            }
        }
        
        // 创建一些山脉
        for (int i = 0; i < 50; i++)
        {
            var x = Random.Shared.Next(-15, 15);
            var z = Random.Shared.Next(-15, 15);
            var height = Random.Shared.Next(1, 5);
            
            for (int y = 1; y <= height; y++)
            {
                _ecsWorld.Store.CreateEntity(
                    new Block(BlockType.Stone),
                    new Position(x, y, z),
                    new Visibility(true),
                    new Collider(new BoundingBox(new Vector3(x, y, z), new Vector3(x + 1, y + 1, z + 1))),
                    new Lighting(15)
                );
            }
        }
    }
    
    private void CreateTestEntities()
    {
        // 创建一些树木
        for (int i = 0; i < 10; i++)
        {
            var x = Random.Shared.Next(-15, 15);
            var z = Random.Shared.Next(-15, 15);
            
            // 树干
            for (int y = 1; y <= 4; y++)
            {
                _ecsWorld.Store.CreateEntity(
                    new Block(BlockType.Wood),
                    new Position(x, y, z),
                    new Visibility(true),
                    new Collider(new BoundingBox(new Vector3(x, y, z), new Vector3(x + 1, y + 1, z + 1))),
                    new Lighting(15)
                );
            }
            
            // 树叶
            for (int lx = -2; lx <= 2; lx++)
            {
                for (int lz = -2; lz <= 2; lz++)
                {
                    for (int ly = 5; ly <= 7; ly++)
                    {
                        if (Math.Abs(lx) + Math.Abs(lz) <= 2)
                        {
                            _ecsWorld.Store.CreateEntity(
                                new Block(BlockType.Leaves),
                                new Position(x + lx, ly, z + lz),
                                new Visibility(true),
                                new Collider(new BoundingBox(new Vector3(x + lx, ly, z + lz), new Vector3(x + lx + 1, ly + 1, z + lz + 1))),
                                new Lighting(15)
                            );
                        }
                    }
                }
            }
        }
        
        // 创建一些矿石
        for (int i = 0; i < 20; i++)
        {
            var x = Random.Shared.Next(-10, 10);
            var y = Random.Shared.Next(1, 10);
            var z = Random.Shared.Next(-10, 10);
            
            var blockType = Random.Shared.Next(0, 100) switch
            {
                < 30 => BlockType.Coal,
                < 50 => BlockType.Iron,
                < 70 => BlockType.Gold,
                < 90 => BlockType.Diamond,
                _ => BlockType.Stone
            };
            
            _ecsWorld.Store.CreateEntity(
                new Block(blockType),
                new Position(x, y, z),
                new Visibility(true),
                new Collider(new BoundingBox(new Vector3(x, y, z), new Vector3(x + 1, y + 1, z + 1))),
                new Lighting(15)
            );
        }
    }
    
    protected override void LoadContent()
    {
        // 加载游戏内容
        _ecsRenderer.LoadContent(Content);
    }
    
    protected override void Update(GameTime gameTime)
    {
        // 开始帧性能监控
        _performanceMonitor.StartFrame();
        
        // 处理输入
        if (GamePad.GetState(PlayerIndex.One).Buttons.Back == ButtonState.Pressed || 
            Keyboard.GetState().IsKeyDown(Keys.Escape))
        {
            Exit();
        }
        
        // 处理特殊按键
        HandleSpecialKeys();
        
        // 更新ECS世界
        _performanceMonitor.BeginTimer("ECSUpdate");
        _ecsWorld.Update(gameTime);
        _performanceMonitor.EndTimer("ECSUpdate");
        
        // 更新相机
        UpdateCamera();
        
        // 结束帧性能监控
        _performanceMonitor.EndFrame();
        
        base.Update(gameTime);
    }
    
    private void HandleSpecialKeys()
    {
        var keyboard = Keyboard.GetState();
        
        // F3 - 切换调试模式
        if (keyboard.IsKeyDown(Keys.F3))
        {
            ToggleDebugMode();
        }
        
        // F11 - 切换全屏
        if (keyboard.IsKeyDown(Keys.F11))
        {
            ToggleFullscreen();
        }
        
        // +/- - 调整渲染距离
        if (keyboard.IsKeyDown(Keys.OemPlus))
        {
            IncreaseRenderDistance();
        }
        
        if (keyboard.IsKeyDown(Keys.OemMinus))
        {
            DecreaseRenderDistance();
        }
        
        // R - 重新生成世界
        if (keyboard.IsKeyDown(Keys.R))
        {
            RegenerateWorld();
        }
    }
    
    private void UpdateCamera()
    {
        var playerEntity = _ecsWorld.PlayerEntity;
        var position = playerEntity.GetComponent<Position>();
        var rotation = playerEntity.GetComponent<Rotation>();
        var camera = playerEntity.GetComponent<Camera>();
        
        // 计算相机方向
        var yaw = rotation.Value.Y;
        var pitch = rotation.Value.X;
        
        var forward = new Vector3(
            (float)Math.Sin(yaw) * (float)Math.Cos(pitch),
            (float)Math.Sin(pitch),
            (float)Math.Cos(yaw) * (float)Math.Cos(pitch)
        );
        
        var up = Vector3.Up;
        
        // 更新相机矩阵
        camera.ViewMatrix = Matrix.CreateLookAt(
            position.Value,
            position.Value + forward,
            up
        );
        
        // 标记相机为脏
        camera.IsDirty = true;
    }
    
    protected override void Draw(GameTime gameTime)
    {
        // 开始渲染性能监控
        _performanceMonitor.BeginTimer("Rendering");
        
        GraphicsDevice.Clear(Color.CornflowerBlue);
        
        // 获取相机矩阵
        var playerEntity = _ecsWorld.PlayerEntity;
        var camera = playerEntity.GetComponent<Camera>();
        
        // 设置视锥体
        var viewFrustum = new BoundingFrustum(camera.ViewMatrix * camera.ProjectionMatrix);
        var cameraPosition = playerEntity.GetComponent<Position>().Value;
        
        // 更新可见性系统
        _ecsWorld.SetViewFrustum(viewFrustum, cameraPosition);
        
        // 渲染ECS实体
        var blockQuery = _ecsWorld.Store.Query<Block, Position, Visibility>();
        var chunkQuery = _ecsWorld.Store.Query<Chunk, Position>();
        
        _ecsRenderer.RenderVisibleEntities(blockQuery, chunkQuery, camera.ViewMatrix, camera.ProjectionMatrix);
        
        // 渲染调试信息
        if (IsDebugMode)
        {
            RenderDebugInfo();
        }
        
        // 结束渲染性能监控
        _performanceMonitor.EndTimer("Rendering");
        
        base.Draw(gameTime);
    }
    
    private void RenderDebugInfo()
    {
        // 这里可以添加调试信息的渲染
        // 比如FPS、实体数量、内存使用等
    }
    
    #region 辅助方法
    
    private bool IsDebugMode { get; set; }
    
    private void ToggleDebugMode()
    {
        IsDebugMode = !IsDebugMode;
        Console.WriteLine($"Debug mode: {IsDebugMode}");
    }
    
    private void ToggleFullscreen()
    {
        _graphics.IsFullScreen = !_graphics.IsFullScreen;
        _graphics.ApplyChanges();
    }
    
    private void IncreaseRenderDistance()
    {
        // 增加渲染距离
        Console.WriteLine("Increased render distance");
    }
    
    private void DecreaseRenderDistance()
    {
        // 减少渲染距离
        Console.WriteLine("Decreased render distance");
    }
    
    private void RegenerateWorld()
    {
        // 重新生成世界
        Console.WriteLine("Regenerating world...");
        
        // 清空现有实体
        _ecsWorld.Store.DeleteAllEntities();
        
        // 重新创建玩家
        _ecsWorld.CreateDefaultPlayer();
        
        // 重新创建地形
        CreateInitialTerrain();
        CreateTestEntities();
        
        Console.WriteLine("World regenerated");
    }
    
    #endregion
    
    protected override void Dispose(bool disposing)
    {
        if (disposing)
        {
            _ecsWorld.Destroy();
            _ecsRenderer.Dispose();
        }
        
        base.Dispose(disposing);
    }
}

/// <summary>
/// 性能监控器
/// </summary>
public class PerformanceMonitor
{
    private readonly Stopwatch _frameStopwatch = new Stopwatch();
    private readonly Dictionary<string, Stopwatch> _timers = new Dictionary<string, Stopwatch>();
    private float _frameTime;
    private int _frameCount;
    
    public void StartFrame()
    {
        _frameStopwatch.Restart();
    }
    
    public void EndFrame()
    {
        _frameStopwatch.Stop();
        _frameTime = _frameStopwatch.ElapsedMilliseconds;
        _frameCount++;
        
        // 每秒输出一次统计
        if (_frameCount % 60 == 0)
        {
            PrintStats();
        }
    }
    
    public void BeginTimer(string name)
    {
        if (!_timers.TryGetValue(name, out var timer))
        {
            timer = new Stopwatch();
            _timers[name] = timer;
        }
        
        timer.Restart();
    }
    
    public void EndTimer(string name)
    {
        if (_timers.TryGetValue(name, out var timer))
        {
            timer.Stop();
        }
    }
    
    private void PrintStats()
    {
        Console.WriteLine($"=== Performance Stats ===");
        Console.WriteLine($"Frame Time: {_frameTime:F2}ms");
        Console.WriteLine($"FPS: {1000f / _frameTime:F1}");
        
        foreach (var kvp in _timers)
        {
            Console.WriteLine($"{kvp.Key}: {kvp.Value.ElapsedMilliseconds:F2}ms");
        }
    }
}
```

## 总结

本文档提供了MCGame项目中Friflo ECS的完整实际代码示例，涵盖了从基础实体管理到高级系统实现的各个方面。所有示例都基于项目实际代码，可直接用于开发参考。

**关键示例包括：**
1. **基础示例** - ECS世界创建、实体操作、组件管理
2. **组件示例** - 自定义组件定义、组件操作、验证
3. **系统示例** - 自定义系统实现、系统组合、复杂逻辑
4. **查询示例** - 高级查询模式、查询优化、性能监控
5. **管理器示例** - 方块管理、区块管理、渲染集成
6. **完整游戏循环** - 完整的游戏实现，包含所有ECS功能

这些示例展示了Friflo ECS在实际游戏开发中的强大功能和灵活性，为开发者提供了实用的参考代码。通过合理使用这些示例，可以快速构建高性能的ECS游戏系统。
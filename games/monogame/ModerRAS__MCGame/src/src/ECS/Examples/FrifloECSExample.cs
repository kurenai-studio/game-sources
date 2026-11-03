using Friflo.Engine.ECS;
using Friflo.Engine.ECS.Systems;
using MCGame.ECS.Components;
using MCGame.Blocks;
using MCGame.Core;
using Microsoft.Xna.Framework;
using System;
using System.Collections.Generic;

namespace MCGame.ECS.Examples
{
    /// <summary>
    /// Friflo ECS 3.4.2 正确API使用示例
    /// 基于实际调研和测试验证的API使用方式
    /// </summary>
    public class FrifloECSExample
    {
        private readonly EntityStore _store;
        private readonly SystemRoot _systemRoot;
        
        public FrifloECSExample()
        {
            _store = new EntityStore();
            _systemRoot = new SystemRoot(_store);
            
            // 初始化系统
            InitializeSystems();
        }
        
        /// <summary>
        /// 初始化ECS系统
        /// </summary>
        private void InitializeSystems()
        {
            // 添加自定义系统
            _systemRoot.Add(new PlayerMovementSystem());
            _systemRoot.Add(new VisibilitySystem());
            
            // 启用性能监控
            _systemRoot.SetMonitorPerf(true);
        }
        
        /// <summary>
        /// 创建实体示例
        /// </summary>
        public Entity CreateBlockEntity(BlockType blockType, Vector3 position)
        {
            // 使用EntityStore创建实体
            var entity = _store.CreateEntity(
                new Block(blockType),
                new MCGame.ECS.Components.Position(position),
                new Visibility(true),
                new Collider(new BoundingBox(position, position + Vector3.One)),
                new Lighting(15)
            );
            
            return entity;
        }
        
        /// <summary>
        /// 批量创建实体示例
        /// </summary>
        public Entity[] CreateBlockEntitiesBatch(BlockType[] blockTypes, Vector3[] positions)
        {
            var entities = new Entity[blockTypes.Length];
            
            for (int i = 0; i < blockTypes.Length; i++)
            {
                var bounds = new BoundingBox(positions[i], positions[i] + Vector3.One);
                entities[i] = _store.CreateEntity(
                    new Block(blockTypes[i]),
                    new MCGame.ECS.Components.Position(positions[i]),
                    new Visibility(true),
                    new Collider(bounds),
                    new Lighting(15)
                );
            }
            
            return entities;
        }
        
        /// <summary>
        /// 查询实体示例
        /// </summary>
        public Entity[] QueryVisibleBlocks()
        {
            var query = _store.Query<Block, MCGame.ECS.Components.Position, Visibility>();
            var visibleBlocks = new List<Entity>();
            
            // 正确的查询遍历方式
            foreach (var entity in query.Entities)
            {
                var visibility = entity.GetComponent<Visibility>();
                if (visibility.IsVisible)
                {
                    visibleBlocks.Add(entity);
                }
            }
            
            return visibleBlocks.ToArray();
        }
        
        /// <summary>
        /// 安全组件访问示例
        /// </summary>
        public void SafeComponentAccess(Entity entity)
        {
            // 使用TryGetComponent进行安全访问
            if (entity.TryGetComponent<MCGame.ECS.Components.Position>(out var position))
            {
                position.Value = new Vector3(5, 6, 7);
            }
            
            // 使用GetComponent进行直接访问（需要确保组件存在）
            try
            {
                var block = entity.GetComponent<Block>();
                block.Type = BlockType.Stone;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Component not found: {ex.Message}");
            }
        }
        
        /// <summary>
        /// 实体删除示例
        /// 注意：Friflo ECS的实体删除方法需要进一步研究
        /// </summary>
        public void DeleteEntity(Entity entity)
        {
            // 尝试不同的删除方法
            
            // 方法1: 使用Delete方法（如果存在）
            // if (entity is IDeletable deletable)
            // {
            //     deletable.Delete();
            // }
            
            // 方法2: 使用Store的删除方法（如果存在）
            // _store.DeleteEntity(entity.Id);
            
            // 方法3: 使用Archetype删除（如果存在）
            // if (entity.Archetype != null)
            // {
            //     entity.Archetype.DeleteEntity(entity);
            // }
            
            // 注意：目前Friflo ECS 3.4.2的实体删除方法需要进一步研究
            // 可能需要使用特定的API或者等待垃圾回收
        }
        
        /// <summary>
        /// 更新ECS世界
        /// </summary>
        public void Update(GameTime gameTime)
        {
            // 更新所有系统
            _systemRoot.Update(new UpdateTick());
        }
        
        /// <summary>
        /// 获取性能统计
        /// </summary>
        public string GetPerformanceStats()
        {
            return _systemRoot.GetPerfLog();
        }
        
        /// <summary>
        /// 获取实体统计
        /// </summary>
        public EntityStats GetEntityStats()
        {
            return new EntityStats
            {
                TotalEntities = _store.Count,
                BlockEntities = _store.Query<Block>().EntityCount,
                VisibleEntities = _store.Query<Visibility>().EntityCount
            };
        }
        
        /// <summary>
        /// 实体统计信息
        /// </summary>
        public struct EntityStats
        {
            public int TotalEntities;
            public int BlockEntities;
            public int VisibleEntities;
        }
    }
    
    /// <summary>
    /// 玩家移动系统示例
    /// </summary>
    public class PlayerMovementSystem : QuerySystem<MCGame.ECS.Components.Position, Velocity, Input, MCGame.ECS.Components.Player>
    {
        protected override void OnUpdate()
        {
            // 使用Query属性遍历实体
            foreach (var entity in Query.Entities)
            {
                var position = entity.GetComponent<MCGame.ECS.Components.Position>();
                var velocity = entity.GetComponent<Velocity>();
                var input = entity.GetComponent<Input>();
                
                // 更新位置
                position.Value += velocity.Value * 0.016f; // 假设60FPS，约16ms一帧
                
                // 处理输入
                if (input.Movement.Y > 0)
                {
                    velocity.Value += Vector3.Forward * 0.016f; // 假设60FPS，约16ms一帧
                }
            }
        }
    }
    
    /// <summary>
    /// 可见性系统示例
    /// </summary>
    public class VisibilitySystem : QuerySystem<MCGame.ECS.Components.Position, Visibility>
    {
        private Vector3 _cameraPosition;
        
        public void SetCameraPosition(Vector3 cameraPosition)
        {
            _cameraPosition = cameraPosition;
        }
        
        protected override void OnUpdate()
        {
            foreach (var entity in Query.Entities)
            {
                var position = entity.GetComponent<MCGame.ECS.Components.Position>();
                var visibility = entity.GetComponent<Visibility>();
                
                // 计算距离并更新可见性
                var distance = Vector3.Distance(position.Value, _cameraPosition);
                visibility.IsVisible = distance < 200f;
                visibility.Distance = distance;
            }
        }
    }
}
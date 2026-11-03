using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Friflo.Engine.ECS;
using Friflo.Engine.ECS.Systems;
using MCGame.ECS.Components;
using MCGame.Rendering;
using MCGame.Core;
using MCGame.Blocks;
using MCGame.Chunks;
using System.Collections.Generic;
using System.Diagnostics;
using System;

namespace MCGame.ECS.Systems
{
    /// <summary>
    /// ECS渲染系统
    /// 将ECS实体渲染到传统渲染管道
    /// 简化实现：将ECS区块和方块转换为传统渲染格式
    /// </summary>
    public class RenderingSystem : QuerySystem<MCGame.ECS.Components.Chunk, MCGame.ECS.Components.Position, Visibility>
    {
        private readonly RenderManager _renderManager;
        private readonly GraphicsDevice _graphicsDevice;
        private readonly BlockRegistry _blockRegistry;
        private readonly object _renderLock = new object();
        
        // 渲染缓存
        private readonly Dictionary<Entity, MCGame.Chunks.Chunk> _ecsToTraditionalChunkMap = new Dictionary<Entity, MCGame.Chunks.Chunk>();
        private readonly List<MCGame.Chunks.Chunk> _visibleEcsChunks = new List<MCGame.Chunks.Chunk>();
        private bool _renderCacheDirty = true;

        public RenderingSystem(RenderManager renderManager, GraphicsDevice graphicsDevice, BlockRegistry blockRegistry)
        {
            _renderManager = renderManager;
            _graphicsDevice = graphicsDevice;
            _blockRegistry = blockRegistry;
        }

        /// <summary>
        /// 更新渲染系统
        /// </summary>
        protected override void OnUpdate()
        {
            lock (_renderLock)
            {
                // 更新可见性
                UpdateVisibility();
                
                // 渲染可见区块
                RenderVisibleChunks();
                
                _renderCacheDirty = false;
            }
        }

        /// <summary>
        /// 更新渲染系统（公共接口）
        /// </summary>
        public void Update()
        {
            OnUpdate();
        }

        /// <summary>
        /// 更新实体可见性状态
        /// </summary>
        private void UpdateVisibility()
        {
            _visibleEcsChunks.Clear();
            
            foreach (var entity in Query.Entities)
            {
                var position = entity.GetComponent<MCGame.ECS.Components.Position>();
                var visibility = entity.GetComponent<Visibility>();
                var chunk = entity.GetComponent<MCGame.ECS.Components.Chunk>();
                
                // 更新距离
                visibility.Distance = Vector3.Distance(position.Value, _renderManager.FrustumCulling.CameraPosition);
                
                // 检查是否在视锥体内
                var chunkBounds = new BoundingBox(
                    position.Value,
                    position.Value + new Vector3(16, 256, 16)
                );
                
                // 简化检查：使用距离判断
                var isVisible = visibility.Distance < 200f; // 渲染距离
                
                if (isVisible)
                {
                    visibility.IsVisible = true;
                    _visibleEcsChunks.Add(ConvertToTraditionalChunk(entity, chunk, position.Value));
                }
                else
                {
                    visibility.IsVisible = false;
                }
            }
        }

        /// <summary>
        /// 渲染可见区块
        /// </summary>
        private void RenderVisibleChunks()
        {
            // 清空映射表
            _ecsToTraditionalChunkMap.Clear();
            
            // 批量创建传统区块
            foreach (var entity in Query.Entities)
            {
                var position = entity.GetComponent<MCGame.ECS.Components.Position>();
                var chunk = entity.GetComponent<MCGame.ECS.Components.Chunk>();
                
                if (entity.GetComponent<Visibility>().IsVisible)
                {
                    var traditionalChunk = ConvertToTraditionalChunk(entity, chunk, position.Value);
                    _ecsToTraditionalChunkMap[entity] = traditionalChunk;
                }
            }
            
            // 使用传统渲染管道渲染
            if (_visibleEcsChunks.Count > 0)
            {
                _renderManager.RenderChunks(_visibleEcsChunks);
            }
        }

        /// <summary>
        /// 将ECS区块转换为传统区块
        /// </summary>
        private MCGame.Chunks.Chunk ConvertToTraditionalChunk(Entity ecsEntity, MCGame.ECS.Components.Chunk ecsChunk, Vector3 position)
        {
            var traditionalChunk = new MCGame.Chunks.Chunk(new ChunkPosition((int)position.X / 16, 0, (int)position.Z / 16));
            
            // 设置区块状态
            traditionalChunk.IsLoaded = ecsChunk.IsLoaded;
            traditionalChunk.IsDirty = ecsChunk.IsDirty;
            
            return traditionalChunk;
        }

        /// <summary>
        /// 获取可见的ECS区块数量
        /// </summary>
        public int GetVisibleEcsChunkCount()
        {
            return _visibleEcsChunks.Count;
        }

        /// <summary>
        /// 获取渲染缓存状态
        /// </summary>
        public bool IsRenderCacheDirty()
        {
            return _renderCacheDirty;
        }

        /// <summary>
        /// 标记渲染缓存为脏
        /// </summary>
        public void MarkRenderCacheDirty()
        {
            _renderCacheDirty = true;
        }

        /// <summary>
        /// 清理资源
        /// </summary>
        public void Clear()
        {
            _ecsToTraditionalChunkMap.Clear();
            _visibleEcsChunks.Clear();
            _renderCacheDirty = true;
        }
    }

    /// <summary>
    /// ECS渲染管理器
    /// 协调所有ECS渲染系统
    /// </summary>
    public class ECSRenderManager : IDisposable
    {
        private readonly RenderingSystem _chunkRenderingSystem;
        private readonly ECSWorld _ecsWorld;
        private readonly RenderManager _renderManager;
        private readonly GraphicsDevice _graphicsDevice;
        private readonly BlockRegistry _blockRegistry;
        
        // 性能统计
        private int _totalVisibleChunks;
        private int _totalVisibleBlocks;
        private float _renderTime;
        private Stopwatch _renderStopwatch;

        public ECSRenderManager(ECSWorld ecsWorld, RenderManager renderManager, 
                               GraphicsDevice graphicsDevice, BlockRegistry blockRegistry)
        {
            _ecsWorld = ecsWorld;
            _renderManager = renderManager;
            _graphicsDevice = graphicsDevice;
            _blockRegistry = blockRegistry;
            
            // 创建渲染系统
            _chunkRenderingSystem = new RenderingSystem(renderManager, graphicsDevice, blockRegistry);
            
            // 初始化性能统计
            _renderStopwatch = new Stopwatch();
        }

        /// <summary>
        /// 初始化渲染系统
        /// </summary>
        public void Initialize(SystemRoot systemRoot)
        {
            // 将渲染系统添加到ECS系统根节点
            if (systemRoot != null)
            {
                systemRoot.Add(_chunkRenderingSystem);
                Console.WriteLine("ECS渲染系统已添加到系统根节点");
            }
            else
            {
                Console.WriteLine("警告: 系统根节点为空，ECS渲染系统将独立运行");
            }
            
            Console.WriteLine("ECS渲染系统初始化完成");
        }

        /// <summary>
        /// 更新渲染系统
        /// </summary>
        public void Update(GameTime gameTime)
        {
            _renderStopwatch.Restart();
            
            // 更新区块渲染系统
            _chunkRenderingSystem.Update();
            
            _renderStopwatch.Stop();
            _renderTime = _renderStopwatch.ElapsedMilliseconds;
        }

        /// <summary>
        /// 更新视锥体信息
        /// </summary>
        public void UpdateFrustum(Matrix view, Matrix projection, Vector3 cameraPosition)
        {
            // 传递视锥体信息给渲染系统
            _renderManager.UpdateCamera(view, projection, cameraPosition);
        }

        /// <summary>
        /// 获取渲染统计信息
        /// </summary>
        public ECSRenderStats GetStats()
        {
            return new ECSRenderStats
            {
                VisibleChunks = _chunkRenderingSystem.GetVisibleEcsChunkCount(),
                RenderTime = _renderTime,
                TotalEntities = _ecsWorld.Store.Count
            };
        }

        /// <summary>
        /// 清理资源
        /// </summary>
        public void Dispose()
        {
            _chunkRenderingSystem?.Clear();
            _renderStopwatch?.Stop();
        }
    }

    /// <summary>
    /// ECS渲染统计信息
    /// </summary>
    public struct ECSRenderStats
    {
        public int VisibleChunks { get; set; }
        public int BlockBatches { get; set; }
        public float RenderTime { get; set; }
        public int TotalEntities { get; set; }
        
        public ECSRenderStats()
        {
            VisibleChunks = 0;
            BlockBatches = 0;
            RenderTime = 0;
            TotalEntities = 0;
        }
    }
}
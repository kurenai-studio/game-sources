using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Friflo.Engine.ECS;
using Friflo.Engine.ECS.Systems;
using MCGame.ECS.Components;
using MCGame.ECS.Rendering;
using MCGame.Rendering;
using MCGame.Blocks;
using MCGame.Core;
using System.Collections.Generic;
using System.Diagnostics;

namespace MCGame.ECS.Rendering
{
    /// <summary>
    /// ECS渲染管理器
    /// 管理ECS实体的渲染和性能统计
    /// 简化实现：专注于ECS渲染的集成和性能监控
    /// </summary>
    public class ECSRenderManager
    {
        private readonly ECSWorld _ecsWorld;
        private readonly RenderManager _renderManager;
        private readonly GraphicsDevice _graphicsDevice;
        private readonly BlockRegistry _blockRegistry;
        private readonly ECSRenderer _ecsRenderer;
        private RenderingSystem _renderingSystem;
        private SystemRoot _systemRoot;
        
        // 渲染统计
        private int _visibleChunks;
        private float _renderTime;
        private int _drawCalls;
        private int _triangles;
        private readonly Stopwatch _renderStopwatch;
        
        // 视锥体和相机
        private Matrix _viewMatrix;
        private Matrix _projectionMatrix;
        private Vector3 _cameraPosition;

        /// <summary>
        /// 构造函数
        /// </summary>
        public ECSRenderManager(
            ECSWorld ecsWorld, 
            RenderManager renderManager, 
            GraphicsDevice graphicsDevice, 
            BlockRegistry blockRegistry)
        {
            _ecsWorld = ecsWorld;
            _renderManager = renderManager;
            _graphicsDevice = graphicsDevice;
            _blockRegistry = blockRegistry;
            _ecsRenderer = new ECSRenderer(graphicsDevice);
            _renderStopwatch = new Stopwatch();
        }

        /// <summary>
        /// 初始化渲染系统
        /// </summary>
        public void Initialize(SystemRoot systemRoot)
        {
            _systemRoot = systemRoot;
            
            // 创建并添加渲染系统
            _renderingSystem = new RenderingSystem(_graphicsDevice);
            systemRoot.Add(_renderingSystem);
            
            Console.WriteLine("ECS渲染管理器初始化完成");
        }

        /// <summary>
        /// 更新视锥体
        /// </summary>
        public void UpdateFrustum(Matrix viewMatrix, Matrix projectionMatrix, Vector3 cameraPosition)
        {
            _viewMatrix = viewMatrix;
            _projectionMatrix = projectionMatrix;
            _cameraPosition = cameraPosition;
            
            // 更新渲染系统的相机参数
            _renderingSystem?.SetCamera(viewMatrix, projectionMatrix, cameraPosition);
            
            // 更新ECS世界的视锥体
            var frustum = new BoundingFrustum(viewMatrix * projectionMatrix);
            _ecsWorld.SetViewFrustum(frustum, cameraPosition);
        }

        /// <summary>
        /// 更新渲染系统
        /// </summary>
        public void Update(GameTime gameTime)
        {
            // 更新渲染统计
            _visibleChunks = 0;
            _renderTime = 0;
        }

        /// <summary>
        /// 渲染ECS实体
        /// </summary>
        public void Render()
        {
            _renderStopwatch.Restart();
            
            try
            {
                // 重置统计
                _visibleChunks = 0;
                _drawCalls = 0;
                _triangles = 0;
                
                // 如果渲染系统存在，它会通过SystemRoot自动更新
                // 这里我们只需要获取统计信息
                if (_renderingSystem != null)
                {
                    var (drawCalls, triangles) = _renderingSystem.GetRenderStats();
                    _drawCalls = drawCalls;
                    _triangles = triangles;
                }
                
                // 统计可见区块
                var chunkQuery = _ecsWorld.Store.Query<Chunk, MCGame.ECS.Components.Position>();
                foreach (var chunk in chunkQuery.Entities)
                {
                    var visibility = chunk.TryGetComponent<Visibility>(out var vis) ? vis : new Visibility(false);
                    if (visibility.IsVisible)
                    {
                        _visibleChunks++;
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"ECS渲染失败: {ex.Message}");
            }
            
            _renderStopwatch.Stop();
            _renderTime = _renderStopwatch.ElapsedMilliseconds;
        }

        /// <summary>
        /// 获取渲染统计信息
        /// </summary>
        public RenderStats GetStats()
        {
            return new RenderStats
            {
                VisibleChunks = _visibleChunks,
                RenderTime = _renderTime,
                DrawCalls = _drawCalls,
                Triangles = _triangles
            };
        }

        /// <summary>
        /// 释放资源
        /// </summary>
        public void Dispose()
        {
            _ecsRenderer?.Dispose();
            _renderingSystem?.Dispose();
        }
    }

    /// <summary>
    /// 渲染统计信息
    /// </summary>
    public struct RenderStats
    {
        public int VisibleChunks { get; set; }
        public float RenderTime { get; set; }
        public int DrawCalls { get; set; }
        public int Triangles { get; set; }
    }
}
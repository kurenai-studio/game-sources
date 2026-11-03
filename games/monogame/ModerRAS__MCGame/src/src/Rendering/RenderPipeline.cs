using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using MCGame.Core;
using MCGame.Chunks;
using MCGame.Blocks;
using MCGame.Utils;
using System;
using System.Collections.Generic;

namespace MCGame.Rendering
{
    /// <summary>
    /// 渲染管道
    /// 管理所有渲染阶段和渲染批次
    /// 简化实现：简单的多阶段渲染系统
    /// </summary>
    public class RenderPipeline : IDisposable
    {
        // 渲染阶段
        private readonly List<IRenderPass> _renderPasses;
        
        // 渲染批次
        private readonly List<RenderBatch> _opaqueBatches;
        private readonly List<RenderBatch> _transparentBatches;
        
        // GPU资源
        private readonly GraphicsDevice _graphicsDevice;
        private BasicEffect _basicEffect;
        
        // 渲染状态
        private RasterizerState _rasterizerState;
        private DepthStencilState _depthStencilState;
        
        // 性能统计
        private RenderStats _stats;
        private bool _statsDirty;

        public RenderStats Stats => _stats;
        public IReadOnlyList<IRenderPass> RenderPasses => _renderPasses;

        public RenderPipeline(GraphicsDevice graphicsDevice)
        {
            var serilogLogger = Logger.GetSerilogLogger();
            serilogLogger?.Info("Creating RenderPipeline...");
            
            _graphicsDevice = graphicsDevice;
            _renderPasses = new List<IRenderPass>();
            _opaqueBatches = new List<RenderBatch>();
            _transparentBatches = new List<RenderBatch>();
            _stats = new RenderStats();
            _statsDirty = false;

            serilogLogger?.Info("Initializing render effects...");
            InitializeEffects();
            InitializeRenderStates();
            InitializeRenderPasses();
        }

        /// <summary>
        /// 初始化着色器效果
        /// </summary>
        private void InitializeEffects()
        {
            _basicEffect = new BasicEffect(_graphicsDevice)
            {
                VertexColorEnabled = false,
                TextureEnabled = true,
                LightingEnabled = true,
                PreferPerPixelLighting = false,
                AmbientLightColor = new Vector3(0.2f, 0.2f, 0.2f),
                DiffuseColor = new Vector3(0.8f, 0.8f, 0.8f),
                SpecularColor = new Vector3(0.2f, 0.2f, 0.2f),
                SpecularPower = 16f,
                Alpha = 1f,
                FogEnabled = false,
                World = Matrix.Identity,
                View = Matrix.Identity,
                Projection = Matrix.Identity
            };

            // 设置默认光源方向
            _basicEffect.DirectionalLight0.Enabled = true;
            _basicEffect.DirectionalLight0.DiffuseColor = new Vector3(1f, 1f, 0.9f);
            _basicEffect.DirectionalLight0.Direction = new Vector3(0.5f, -1f, 0.5f);
            _basicEffect.DirectionalLight0.SpecularColor = new Vector3(0.5f, 0.5f, 0.5f);

            _basicEffect.DirectionalLight1.Enabled = false;
            _basicEffect.DirectionalLight2.Enabled = false;
        }

        /// <summary>
        /// 初始化渲染状态
        /// </summary>
        private void InitializeRenderStates()
        {
            _rasterizerState = new RasterizerState
            {
                FillMode = FillMode.Solid,
                CullMode = CullMode.CullCounterClockwiseFace,
                DepthBias = 0,
                SlopeScaleDepthBias = 0,
                MultiSampleAntiAlias = true,
                ScissorTestEnable = false
            };

            _depthStencilState = new DepthStencilState
            {
                DepthBufferEnable = true,
                DepthBufferWriteEnable = true,
                DepthBufferFunction = CompareFunction.LessEqual,
                StencilEnable = false,
                TwoSidedStencilMode = false
            };
        }

        /// <summary>
        /// 初始化渲染阶段
        /// </summary>
        private void InitializeRenderPasses()
        {
            _renderPasses.Add(new OpaquePass());
            _renderPasses.Add(new TransparentPass());
        }

        /// <summary>
        /// 更新相机矩阵
        /// </summary>
        public void UpdateCamera(Matrix view, Matrix projection, Vector3 cameraPosition)
        {
            _basicEffect.View = view;
            _basicEffect.Projection = projection;

            // 更新所有批次的世界矩阵
            UpdateBatchTransforms(cameraPosition);
        }

        /// <summary>
        /// 更新批次变换矩阵
        /// </summary>
        private void UpdateBatchTransforms(Vector3 cameraPosition)
        {
            for (int i = 0; i < _opaqueBatches.Count; i++)
            {
                var batch = _opaqueBatches[i];
                var newBatch = new RenderBatch
                {
                    Mesh = batch.Mesh,
                    Material = batch.Material,
                    Transform = Matrix.CreateTranslation(batch.Bounds.Min),
                    Distance = Vector3.Distance(cameraPosition, (batch.Bounds.Min + batch.Bounds.Max) * 0.5f),
                    Bounds = batch.Bounds
                };
                _opaqueBatches[i] = newBatch;
            }

            for (int i = 0; i < _transparentBatches.Count; i++)
            {
                var batch = _transparentBatches[i];
                var newBatch = new RenderBatch
                {
                    Mesh = batch.Mesh,
                    Material = batch.Material,
                    Transform = Matrix.CreateTranslation(batch.Bounds.Min),
                    Distance = Vector3.Distance(cameraPosition, (batch.Bounds.Min + batch.Bounds.Max) * 0.5f),
                    Bounds = batch.Bounds
                };
                _transparentBatches[i] = newBatch;
            }
        }

        /// <summary>
        /// 添加渲染批次
        /// </summary>
        public void AddRenderBatch(RenderBatch batch)
        {
            if (batch.Mesh == null || batch.Mesh.VertexCount == 0)
            {
                return;
            }

            // 设置默认材质效果
            if (batch.Material.Effect == null)
            {
                var newMaterial = batch.Material;
                newMaterial.Effect = _basicEffect;
                batch = new RenderBatch
                {
                    Mesh = batch.Mesh,
                    Material = newMaterial,
                    Transform = batch.Transform,
                    Distance = batch.Distance,
                    Bounds = batch.Bounds
                };
            }

            // 根据透明度分类
            if (batch.Material.IsTransparent)
            {
                _transparentBatches.Add(batch);
            }
            else
            {
                _opaqueBatches.Add(batch);
            }

            _statsDirty = true;
        }

        /// <summary>
        /// 清空渲染批次
        /// </summary>
        public void ClearBatches()
        {
            _opaqueBatches.Clear();
            _transparentBatches.Clear();
            _statsDirty = true;
        }

        /// <summary>
        /// 执行渲染
        /// </summary>
        public void Render()
        {
            var serilogLogger = Logger.GetSerilogLogger();
            serilogLogger?.Render("Starting render pipeline execution...");
            serilogLogger?.Render("Opaque batches: {Count}, Transparent batches: {Count}", _opaqueBatches.Count, _transparentBatches.Count);
            
            // 设置渲染状态
            _graphicsDevice.RasterizerState = _rasterizerState;
            _graphicsDevice.DepthStencilState = _depthStencilState;

            // 更新统计信息
            if (_statsDirty)
            {
                UpdateStats();
                _statsDirty = false;
            }

            // 重置统计
            _stats.DrawCalls = 0;
            _stats.Triangles = 0;

            // 执行渲染阶段
            serilogLogger?.Render("Executing {Count} render passes...", _renderPasses.Count);
            foreach (var pass in _renderPasses)
            {
                serilogLogger?.Render("Executing render pass: {PassName}", pass.Name);
                pass.Begin(_graphicsDevice);

                var batches = pass.Name == "Opaque" ? _opaqueBatches : _transparentBatches;
                serilogLogger?.Render("Pass {PassName} has {BatchCount} batches", pass.Name, batches.Count);
                pass.Execute(_graphicsDevice, batches);

                pass.End(_graphicsDevice);
            }
            
            serilogLogger?.Render("Render pipeline completed. Draw calls: {DrawCalls}, Triangles: {Triangles}", _stats.DrawCalls, _stats.Triangles);
        }

        /// <summary>
        /// 更新统计信息
        /// </summary>
        private void UpdateStats()
        {
            _stats.VisibleChunks = 0;
            _stats.TotalVertices = 0;

            foreach (var batch in _opaqueBatches)
            {
                _stats.VisibleChunks++;
                _stats.TotalVertices += batch.Mesh.VertexCount;
            }

            foreach (var batch in _transparentBatches)
            {
                _stats.VisibleChunks++;
                _stats.TotalVertices += batch.Mesh.VertexCount;
            }
        }

        /// <summary>
        /// 设置雾效
        /// </summary>
        public void SetFog(bool enabled, float start, float end, Color color)
        {
            _basicEffect.FogEnabled = enabled;
            _basicEffect.FogStart = start;
            _basicEffect.FogEnd = end;
            _basicEffect.FogColor = color.ToVector3();
        }

        /// <summary>
        /// 设置环境光
        /// </summary>
        public void SetAmbientLight(Vector3 color)
        {
            _basicEffect.AmbientLightColor = color;
        }

        /// <summary>
        /// 设置方向光
        /// </summary>
        public void SetDirectionalLight(Vector3 direction, Vector3 diffuseColor, Vector3 specularColor)
        {
            _basicEffect.DirectionalLight0.Direction = direction;
            _basicEffect.DirectionalLight0.DiffuseColor = diffuseColor;
            _basicEffect.DirectionalLight0.SpecularColor = specularColor;
        }

        /// <summary>
        /// 获取基本效果
        /// </summary>
        public BasicEffect GetBasicEffect()
        {
            return _basicEffect;
        }

        /// <summary>
        /// 添加自定义渲染阶段
        /// </summary>
        public void AddRenderPass(IRenderPass renderPass)
        {
            _renderPasses.Add(renderPass);
        }

        /// <summary>
        /// 移除渲染阶段
        /// </summary>
        public void RemoveRenderPass(IRenderPass renderPass)
        {
            _renderPasses.Remove(renderPass);
        }

        /// <summary>
        /// 获取渲染批次数量
        /// </summary>
        public int GetBatchCount()
        {
            return _opaqueBatches.Count + _transparentBatches.Count;
        }

        /// <summary>
        /// 获取不透明批次数量
        /// </summary>
        public int GetOpaqueBatchCount()
        {
            return _opaqueBatches.Count;
        }

        /// <summary>
        /// 获取透明批次数量
        /// </summary>
        public int GetTransparentBatchCount()
        {
            return _transparentBatches.Count;
        }

        /// <summary>
        /// 设置纹理
        /// </summary>
        public void SetTexture(Texture2D texture)
        {
            _basicEffect.Texture = texture;
        }

        /// <summary>
        /// 释放资源
        /// </summary>
        public void Dispose()
        {
            _basicEffect?.Dispose();
            _rasterizerState?.Dispose();
            _depthStencilState?.Dispose();

            foreach (var batch in _opaqueBatches)
            {
                batch.Mesh?.Dispose();
            }

            foreach (var batch in _transparentBatches)
            {
                batch.Mesh?.Dispose();
            }

            _opaqueBatches.Clear();
            _transparentBatches.Clear();
            _renderPasses.Clear();
        }
    }

    /// <summary>
    /// 渲染管理器
    /// 统一管理渲染管道和视锥剔除
    /// </summary>
    public class RenderManager : IDisposable
    {
        private readonly RenderPipeline _renderPipeline;
        private readonly FrustumCulling _frustumCulling;
        private readonly GraphicsDevice _graphicsDevice;
        private readonly BlockRegistry _blockRegistry;

        public RenderPipeline Pipeline => _renderPipeline;
        public FrustumCulling FrustumCulling => _frustumCulling;

        public RenderManager(GraphicsDevice graphicsDevice, BlockRegistry blockRegistry)
        {
            _graphicsDevice = graphicsDevice;
            _blockRegistry = blockRegistry;
            _renderPipeline = new RenderPipeline(graphicsDevice);
            _frustumCulling = new FrustumCulling();
        }

        /// <summary>
        /// 更新相机
        /// </summary>
        public void UpdateCamera(Matrix view, Matrix projection, Vector3 cameraPosition)
        {
            _renderPipeline.UpdateCamera(view, projection, cameraPosition);
            _frustumCulling.UpdateFrustum(view, projection);
        }

        /// <summary>
        /// 渲染区块列表
        /// </summary>
        public void RenderChunks(List<Chunk> chunks)
        {
            var serilogLogger = Logger.GetSerilogLogger();
            serilogLogger?.Render("RenderChunks called with {Count} chunks", chunks.Count);
            
            _renderPipeline.ClearBatches();

            // 创建默认材质
            var defaultMaterial = new Material
            {
                Texture = _blockRegistry.GetBlockTexture(BlockType.Stone),
                Effect = _renderPipeline.GetBasicEffect(),
                IsTransparent = false,
                Name = "Default"
            };

            int validMeshCount = 0;
            int visibleChunkCount = 0;
            int batchedChunkCount = 0;
            
            // 添加区块到渲染批次
            serilogLogger?.Render("Processing chunks for rendering...");
            foreach (var chunk in chunks)
            {
                if (chunk.Mesh != null && chunk.Mesh.VertexCount > 0)
                {
                    validMeshCount++;
                    if (_frustumCulling.IsChunkVisible(chunk))
                    {
                        visibleChunkCount++;
                        var batch = new RenderBatch
                        {
                            Mesh = chunk.Mesh,
                            Material = defaultMaterial,
                            Transform = Matrix.CreateTranslation(chunk.Bounds.Min),
                            Distance = Vector3.Distance(
                                _frustumCulling.CameraPosition, 
                                (chunk.Bounds.Min + chunk.Bounds.Max) * 0.5f
                            ),
                            Bounds = chunk.Bounds
                        };

                        _renderPipeline.AddRenderBatch(batch);
                        batchedChunkCount++;
                    }
                }
            }
            
            serilogLogger?.Render("Chunk rendering stats: {ValidMeshes} valid meshes, {VisibleChunks} visible chunks, {BatchedChunks} batched chunks", validMeshCount, visibleChunkCount, batchedChunkCount);
            Logger.Debug($"Chunk rendering stats: {validMeshCount} valid meshes, {visibleChunkCount} visible chunks, {batchedChunkCount} batched chunks");

            // 执行渲染
            serilogLogger?.Render("Executing render pipeline...");
            _renderPipeline.Render();
        }

        /// <summary>
        /// 获取渲染统计信息
        /// </summary>
        public RenderStats GetStats()
        {
            return _renderPipeline.Stats;
        }

        /// <summary>
        /// 设置渲染选项
        /// </summary>
        public void SetRenderOptions(bool fogEnabled, float fogStart, float fogEnd, Color fogColor)
        {
            _renderPipeline.SetFog(fogEnabled, fogStart, fogEnd, fogColor);
        }

        /// <summary>
        /// 设置光照
        /// </summary>
        public void SetLighting(Vector3 ambient, Vector3 lightDirection, Vector3 lightColor)
        {
            _renderPipeline.SetAmbientLight(ambient);
            _renderPipeline.SetDirectionalLight(lightDirection, lightColor, Vector3.One * 0.5f);
        }

        /// <summary>
        /// 释放资源
        /// </summary>
        public void Dispose()
        {
            _renderPipeline?.Dispose();
            _frustumCulling?.Dispose();
        }
    }
}
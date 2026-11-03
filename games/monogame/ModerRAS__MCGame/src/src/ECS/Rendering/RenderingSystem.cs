using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Friflo.Engine.ECS;
using Friflo.Engine.ECS.Systems;
using MCGame.ECS.Components;
using MCGame.ECS.Utils;
using MCGame.Blocks;
using System.Collections.Generic;

namespace MCGame.ECS.Rendering
{
    /// <summary>
    /// ECS渲染系统
    /// 使用Friflo ECS的QuerySystem进行高效的实体渲染
    /// 简化实现：专注于查询优化和批量渲染
    /// 性能优化：集成对象池和批量处理
    /// </summary>
    public class RenderingSystem : QuerySystem<Block, MCGame.ECS.Components.Position, Visibility>
    {
        private readonly GraphicsDevice _graphicsDevice;
        private readonly BasicEffect _basicEffect;
        private readonly RasterizerState _rasterizerState;
        private readonly DepthStencilState _depthStencilState;
        private readonly Dictionary<Core.BlockType, VertexBuffer> _blockVertexBuffers;
        private readonly Dictionary<Core.BlockType, IndexBuffer> _blockIndexBuffers;
        
        // 性能优化组件
        private readonly ECSObjectPool _objectPool;
        
        // 渲染状态
        private Matrix _viewMatrix;
        private Matrix _projectionMatrix;
        private Vector3 _cameraPosition;
        private int _drawCalls;
        private int _triangles;

        /// <summary>
        /// 构造函数
        /// </summary>
        public RenderingSystem(GraphicsDevice graphicsDevice)
        {
            _graphicsDevice = graphicsDevice;
            _objectPool = new ECSObjectPool();
            
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

            // 初始化方块缓冲区字典
            _blockVertexBuffers = new Dictionary<Core.BlockType, VertexBuffer>();
            _blockIndexBuffers = new Dictionary<Core.BlockType, IndexBuffer>();
        }

        /// <summary>
        /// 设置相机参数
        /// </summary>
        public void SetCamera(Matrix viewMatrix, Matrix projectionMatrix, Vector3 cameraPosition)
        {
            _viewMatrix = viewMatrix;
            _projectionMatrix = projectionMatrix;
            _cameraPosition = cameraPosition;
        }

        /// <summary>
        /// 系统更新 - 渲染所有可见方块
        /// </summary>
        protected override void OnUpdate()
        {
            // 设置渲染状态
            _graphicsDevice.RasterizerState = _rasterizerState;
            _graphicsDevice.DepthStencilState = _depthStencilState;

            // 设置相机矩阵
            _basicEffect.View = _viewMatrix;
            _basicEffect.Projection = _projectionMatrix;

            // 重置统计
            _drawCalls = 0;
            _triangles = 0;

            // 收集并排序可见实体
            var visibleEntities = new List<(Entity entity, float distance)>();
            
            foreach (var entity in Query.Entities)
            {
                var visibility = entity.GetComponent<Visibility>();
                if (visibility.IsVisible)
                {
                    var position = entity.GetComponent<MCGame.ECS.Components.Position>();
                    var distance = Vector3.Distance(position.Value, _cameraPosition);
                    visibleEntities.Add((entity, distance));
                }
            }

            // 按距离从远到近排序
            visibleEntities.Sort((a, b) => b.distance.CompareTo(a.distance));

            // 批量渲染相同类型的方块
            RenderBlocksBatch(visibleEntities);
        }

        /// <summary>
        /// 批量渲染方块
        /// </summary>
        private void RenderBlocksBatch(List<(Entity entity, float distance)> visibleEntities)
        {
            // 使用对象池优化的字典
            var blocksByType = DictionaryPool<Core.BlockType, List<Matrix>>.Get();
            
            foreach (var (entity, _) in visibleEntities)
            {
                var block = entity.GetComponent<Block>();
                var position = entity.GetComponent<MCGame.ECS.Components.Position>();
                var lighting = entity.TryGetComponent<Lighting>(out var lightComponent) ? lightComponent : new Lighting();
                
                if (!blocksByType.ContainsKey(block.Type))
                {
                    blocksByType[block.Type] = ListPool<Matrix>.Get();
                }
                
                blocksByType[block.Type].Add(Matrix.CreateTranslation(position.Value));
            }

            // 渲染每种类型的方块
            foreach (var (blockType, transforms) in blocksByType)
            {
                RenderBlockType(blockType, transforms);
                ListPool<Matrix>.Release(transforms);
            }
            
            DictionaryPool<Core.BlockType, List<Matrix>>.Release(blocksByType);
        }

        /// <summary>
        /// 渲染特定类型的方块
        /// </summary>
        private void RenderBlockType(Core.BlockType blockType, List<Matrix> transforms)
        {
            // 获取或创建缓冲区
            if (!_blockVertexBuffers.TryGetValue(blockType, out var vertexBuffer))
            {
                CreateBlockBuffers(blockType);
                _blockVertexBuffers.TryGetValue(blockType, out vertexBuffer);
            }

            if (!_blockIndexBuffers.TryGetValue(blockType, out var indexBuffer))
            {
                _blockIndexBuffers.TryGetValue(blockType, out indexBuffer);
            }

            if (vertexBuffer == null || indexBuffer == null)
                return;

            // 设置缓冲区
            _graphicsDevice.SetVertexBuffer(vertexBuffer);
            _graphicsDevice.Indices = indexBuffer;

            // 设置基础颜色
            var color = GetBlockColor(blockType);
            var brightness = 1.0f; // 默认亮度
            _basicEffect.DiffuseColor = new Vector3(color.R / 255f * brightness, color.G / 255f * brightness, color.B / 255f * brightness);
            _basicEffect.AmbientLightColor = new Vector3(0.1f, 0.1f, 0.1f);

            // 批量渲染
            foreach (var transform in transforms)
            {
                _basicEffect.World = transform;

                foreach (var pass in _basicEffect.CurrentTechnique.Passes)
                {
                    pass.Apply();
                    _graphicsDevice.DrawIndexedPrimitives(PrimitiveType.TriangleList, 0, 0, indexBuffer.IndexCount / 3);
                }
                
                _drawCalls++;
                _triangles += indexBuffer.IndexCount / 3;
            }
        }

        /// <summary>
        /// 创建方块的顶点和索引缓冲区
        /// </summary>
        private void CreateBlockBuffers(Core.BlockType blockType)
        {
            // 创建方块的顶点数据
            var vertices = CreateBlockVertices(blockType);
            var indices = CreateBlockIndices();

            // 创建顶点缓冲区
            var vertexBuffer = new VertexBuffer(_graphicsDevice, VertexPositionColorTexture.VertexDeclaration, vertices.Length, BufferUsage.WriteOnly);
            vertexBuffer.SetData(vertices);
            _blockVertexBuffers[blockType] = vertexBuffer;

            // 创建索引缓冲区
            var indexBuffer = new IndexBuffer(_graphicsDevice, IndexElementSize.ThirtyTwoBits, indices.Length, BufferUsage.WriteOnly);
            indexBuffer.SetData(indices);
            _blockIndexBuffers[blockType] = indexBuffer;
        }

        /// <summary>
        /// 创建方块顶点数据
        /// </summary>
        private VertexPositionColorTexture[] CreateBlockVertices(Core.BlockType blockType)
        {
            var vertices = new VertexPositionColorTexture[24]; // 立方体有6个面，每个面4个顶点

            // 根据方块类型设置颜色
            var color = GetBlockColor(blockType);

            // 前面
            vertices[0] = new VertexPositionColorTexture(new Vector3(0, 0, 1), color, new Vector2(0, 0));
            vertices[1] = new VertexPositionColorTexture(new Vector3(1, 0, 1), color, new Vector2(1, 0));
            vertices[2] = new VertexPositionColorTexture(new Vector3(1, 1, 1), color, new Vector2(1, 1));
            vertices[3] = new VertexPositionColorTexture(new Vector3(0, 1, 1), color, new Vector2(0, 1));

            // 后面
            vertices[4] = new VertexPositionColorTexture(new Vector3(1, 0, 0), color, new Vector2(0, 0));
            vertices[5] = new VertexPositionColorTexture(new Vector3(0, 0, 0), color, new Vector2(1, 0));
            vertices[6] = new VertexPositionColorTexture(new Vector3(0, 1, 0), color, new Vector2(1, 1));
            vertices[7] = new VertexPositionColorTexture(new Vector3(1, 1, 0), color, new Vector2(0, 1));

            // 左面
            vertices[8] = new VertexPositionColorTexture(new Vector3(0, 0, 0), color, new Vector2(0, 0));
            vertices[9] = new VertexPositionColorTexture(new Vector3(0, 0, 1), color, new Vector2(1, 0));
            vertices[10] = new VertexPositionColorTexture(new Vector3(0, 1, 1), color, new Vector2(1, 1));
            vertices[11] = new VertexPositionColorTexture(new Vector3(0, 1, 0), color, new Vector2(0, 1));

            // 右面
            vertices[12] = new VertexPositionColorTexture(new Vector3(1, 0, 1), color, new Vector2(0, 0));
            vertices[13] = new VertexPositionColorTexture(new Vector3(1, 0, 0), color, new Vector2(1, 0));
            vertices[14] = new VertexPositionColorTexture(new Vector3(1, 1, 0), color, new Vector2(1, 1));
            vertices[15] = new VertexPositionColorTexture(new Vector3(1, 1, 1), color, new Vector2(0, 1));

            // 上面
            vertices[16] = new VertexPositionColorTexture(new Vector3(0, 1, 0), color, new Vector2(0, 0));
            vertices[17] = new VertexPositionColorTexture(new Vector3(1, 1, 0), color, new Vector2(1, 0));
            vertices[18] = new VertexPositionColorTexture(new Vector3(1, 1, 1), color, new Vector2(1, 1));
            vertices[19] = new VertexPositionColorTexture(new Vector3(0, 1, 1), color, new Vector2(0, 1));

            // 下面
            vertices[20] = new VertexPositionColorTexture(new Vector3(0, 0, 1), color, new Vector2(0, 0));
            vertices[21] = new VertexPositionColorTexture(new Vector3(1, 0, 1), color, new Vector2(1, 0));
            vertices[22] = new VertexPositionColorTexture(new Vector3(1, 0, 0), color, new Vector2(1, 1));
            vertices[23] = new VertexPositionColorTexture(new Vector3(0, 0, 0), color, new Vector2(0, 1));

            return vertices;
        }

        /// <summary>
        /// 创建方块索引数据
        /// </summary>
        private int[] CreateBlockIndices()
        {
            var indices = new int[36]; // 每个面2个三角形，6个面 = 12个三角形 = 36个索引

            // 前面
            indices[0] = 0; indices[1] = 1; indices[2] = 2;
            indices[3] = 0; indices[4] = 2; indices[5] = 3;

            // 后面
            indices[6] = 4; indices[7] = 5; indices[8] = 6;
            indices[9] = 4; indices[10] = 6; indices[11] = 7;

            // 左面
            indices[12] = 8; indices[13] = 9; indices[14] = 10;
            indices[15] = 8; indices[16] = 10; indices[17] = 11;

            // 右面
            indices[18] = 12; indices[19] = 13; indices[20] = 14;
            indices[21] = 12; indices[22] = 14; indices[23] = 15;

            // 上面
            indices[24] = 16; indices[25] = 17; indices[26] = 18;
            indices[27] = 16; indices[28] = 18; indices[29] = 19;

            // 下面
            indices[30] = 20; indices[31] = 21; indices[32] = 22;
            indices[33] = 20; indices[34] = 22; indices[35] = 23;

            return indices;
        }

        /// <summary>
        /// 获取方块颜色
        /// </summary>
        private Color GetBlockColor(Core.BlockType blockType)
        {
            return blockType switch
            {
                Core.BlockType.Grass => new Color(34, 139, 34),
                Core.BlockType.Dirt => new Color(139, 69, 19),
                Core.BlockType.Stone => new Color(128, 128, 128),
                Core.BlockType.Wood => new Color(139, 90, 43),
                Core.BlockType.Leaves => new Color(0, 100, 0),
                Core.BlockType.Sand => new Color(238, 203, 173),
                Core.BlockType.Water => new Color(64, 164, 223),
                Core.BlockType.Glass => new Color(176, 224, 230),
                Core.BlockType.Cobblestone => new Color(128, 128, 128),
                Core.BlockType.Iron => new Color(192, 192, 192),
                Core.BlockType.Gold => new Color(255, 215, 0),
                Core.BlockType.Diamond => new Color(0, 255, 255),
                Core.BlockType.Coal => new Color(64, 64, 64),
                Core.BlockType.Bedrock => new Color(64, 64, 64),
                _ => new Color(128, 128, 128)
            };
        }

        /// <summary>
        /// 获取渲染统计
        /// </summary>
        public (int drawCalls, int triangles) GetRenderStats()
        {
            return (_drawCalls, _triangles);
        }

        /// <summary>
        /// 释放资源
        /// </summary>
        public void Dispose()
        {
            _basicEffect?.Dispose();
            _rasterizerState?.Dispose();
            _depthStencilState?.Dispose();
            _objectPool?.Clear();

            foreach (var buffer in _blockVertexBuffers.Values)
            {
                buffer?.Dispose();
            }

            foreach (var buffer in _blockIndexBuffers.Values)
            {
                buffer?.Dispose();
            }

            _blockVertexBuffers.Clear();
            _blockIndexBuffers.Clear();
        }
    }
}
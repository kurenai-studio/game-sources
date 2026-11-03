using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using MCGame.Core;
using System;
using System.Collections.Generic;

namespace MCGame.Blocks
{
    /// <summary>
    /// 方块定义结构
    /// 包含方块的所有属性和渲染信息
    /// </summary>
    public struct BlockDefinition
    {
        public string Name { get; set; }
        public bool IsTransparent { get; set; }
        public bool IsSolid { get; set; }
        public bool IsLiquid { get; set; }
        public string Texture { get; set; }
        public float Hardness { get; set; }
        public Color BaseColor { get; set; }
        public Vector3[] TextureUVs { get; set; }
        public bool ShouldRenderFace { get; set; }
        public bool IsLightSource { get; set; }
        public byte LightLevel { get; set; }

        public static BlockDefinition Default => new BlockDefinition
        {
            Name = "Unknown",
            IsTransparent = false,
            IsSolid = true,
            IsLiquid = false,
            Texture = "error",
            Hardness = 1.0f,
            BaseColor = Color.Magenta,
            TextureUVs = new Vector3[6],
            ShouldRenderFace = true,
            IsLightSource = false,
            LightLevel = 0
        };
    }

    /// <summary>
    /// 方块注册表
    /// 管理所有方块类型的定义和属性
    /// 简化实现：使用字典存储，支持动态注册
    /// </summary>
    public class BlockRegistry
    {
        private readonly Dictionary<BlockType, BlockDefinition> _blockDefinitions;
        private readonly Dictionary<string, BlockType> _nameToType;
        private readonly GraphicsDevice _graphicsDevice;
        private readonly Dictionary<string, Texture2D> _textureCache;

        public IReadOnlyDictionary<BlockType, BlockDefinition> BlockDefinitions => _blockDefinitions;

        public BlockRegistry(GraphicsDevice graphicsDevice)
        {
            _graphicsDevice = graphicsDevice;
            _blockDefinitions = new Dictionary<BlockType, BlockDefinition>();
            _nameToType = new Dictionary<string, BlockType>();
            _textureCache = new Dictionary<string, Texture2D>();

            RegisterDefaultBlocks();
            InitializeDefaultTextures();
        }

        /// <summary>
        /// 注册默认方块类型
        /// 简化实现：只注册基础方块类型
        /// </summary>
        private void RegisterDefaultBlocks()
        {
            // 空气方块
            RegisterBlock(BlockType.Air, new BlockDefinition
            {
                Name = "Air",
                IsTransparent = true,
                IsSolid = false,
                IsLiquid = false,
                Texture = null,
                Hardness = 0f,
                BaseColor = Color.Transparent,
                ShouldRenderFace = false,
                IsLightSource = false,
                LightLevel = 0
            });

            // 石头
            RegisterBlock(BlockType.Stone, new BlockDefinition
            {
                Name = "Stone",
                IsTransparent = false,
                IsSolid = true,
                IsLiquid = false,
                Texture = "stone",
                Hardness = 1.5f,
                BaseColor = new Color(128, 128, 128),
                TextureUVs = CreateDefaultUVs(),
                ShouldRenderFace = true,
                IsLightSource = false,
                LightLevel = 0
            });

            // 草地
            RegisterBlock(BlockType.Grass, new BlockDefinition
            {
                Name = "Grass",
                IsTransparent = false,
                IsSolid = true,
                IsLiquid = false,
                Texture = "grass",
                Hardness = 0.6f,
                BaseColor = new Color(34, 139, 34),
                TextureUVs = CreateDefaultUVs(),
                ShouldRenderFace = true,
                IsLightSource = false,
                LightLevel = 0
            });

            // 泥土
            RegisterBlock(BlockType.Dirt, new BlockDefinition
            {
                Name = "Dirt",
                IsTransparent = false,
                IsSolid = true,
                IsLiquid = false,
                Texture = "dirt",
                Hardness = 0.5f,
                BaseColor = new Color(139, 69, 19),
                TextureUVs = CreateDefaultUVs(),
                ShouldRenderFace = true,
                IsLightSource = false,
                LightLevel = 0
            });

            // 木头
            RegisterBlock(BlockType.Wood, new BlockDefinition
            {
                Name = "Wood",
                IsTransparent = false,
                IsSolid = true,
                IsLiquid = false,
                Texture = "wood",
                Hardness = 2.0f,
                BaseColor = new Color(139, 90, 43),
                TextureUVs = CreateDefaultUVs(),
                ShouldRenderFace = true,
                IsLightSource = false,
                LightLevel = 0
            });

            // 树叶
            RegisterBlock(BlockType.Leaves, new BlockDefinition
            {
                Name = "Leaves",
                IsTransparent = true,
                IsSolid = true,
                IsLiquid = false,
                Texture = "leaves",
                Hardness = 0.2f,
                BaseColor = new Color(34, 139, 34),
                TextureUVs = CreateDefaultUVs(),
                ShouldRenderFace = true,
                IsLightSource = false,
                LightLevel = 0
            });

            // 水
            RegisterBlock(BlockType.Water, new BlockDefinition
            {
                Name = "Water",
                IsTransparent = true,
                IsSolid = false,
                IsLiquid = true,
                Texture = "water",
                Hardness = 0f,
                BaseColor = new Color(64, 164, 223),
                TextureUVs = CreateDefaultUVs(),
                ShouldRenderFace = true,
                IsLightSource = false,
                LightLevel = 0
            });

            // 沙子
            RegisterBlock(BlockType.Sand, new BlockDefinition
            {
                Name = "Sand",
                IsTransparent = false,
                IsSolid = true,
                IsLiquid = false,
                Texture = "sand",
                Hardness = 0.5f,
                BaseColor = new Color(238, 203, 173),
                TextureUVs = CreateDefaultUVs(),
                ShouldRenderFace = true,
                IsLightSource = false,
                LightLevel = 0
            });

            // 玻璃
            RegisterBlock(BlockType.Glass, new BlockDefinition
            {
                Name = "Glass",
                IsTransparent = true,
                IsSolid = true,
                IsLiquid = false,
                Texture = "glass",
                Hardness = 0.3f,
                BaseColor = new Color(200, 200, 255),
                TextureUVs = CreateDefaultUVs(),
                ShouldRenderFace = true,
                IsLightSource = false,
                LightLevel = 0
            });

            // 基岩
            RegisterBlock(BlockType.Bedrock, new BlockDefinition
            {
                Name = "Bedrock",
                IsTransparent = false,
                IsSolid = true,
                IsLiquid = false,
                Texture = "bedrock",
                Hardness = float.MaxValue,
                BaseColor = new Color(64, 64, 64),
                TextureUVs = CreateDefaultUVs(),
                ShouldRenderFace = true,
                IsLightSource = false,
                LightLevel = 0
            });
        }

        /// <summary>
        /// 初始化默认纹理
        /// 简化实现：为每种方块类型创建基础颜色纹理
        /// </summary>
        private void InitializeDefaultTextures()
        {
            // 为每种方块类型创建一个简单的颜色纹理
            foreach (var blockType in _blockDefinitions.Keys)
            {
                var definition = _blockDefinitions[blockType];
                if (definition.Texture != null)
                {
                    var texture = CreateColorTexture(definition.BaseColor);
                    _textureCache[definition.Texture] = texture;
                }
            }
        }

        /// <summary>
        /// 创建纯色纹理
        /// </summary>
        private Texture2D CreateColorTexture(Color color)
        {
            var texture = new Texture2D(_graphicsDevice, 16, 16);
            var colorData = new Color[16 * 16];
            
            for (int i = 0; i < colorData.Length; i++)
            {
                colorData[i] = color;
            }
            
            texture.SetData(colorData);
            return texture;
        }

        /// <summary>
        /// 获取方块纹理
        /// </summary>
        public Texture2D GetBlockTexture(BlockType blockType)
        {
            var definition = GetBlockDefinition(blockType);
            if (definition.Texture != null && _textureCache.TryGetValue(definition.Texture, out var texture))
            {
                return texture;
            }
            
            // 返回默认纹理
            return GetDefaultTexture();
        }

        /// <summary>
        /// 获取默认纹理
        /// </summary>
        private Texture2D GetDefaultTexture()
        {
            if (!_textureCache.TryGetValue("default", out var defaultTexture))
            {
                defaultTexture = CreateColorTexture(Color.White);
                _textureCache["default"] = defaultTexture;
            }
            return defaultTexture;
        }

        /// <summary>
        /// 注册方块类型
        /// </summary>
        public void RegisterBlock(BlockType type, BlockDefinition definition)
        {
            if (_blockDefinitions.ContainsKey(type))
            {
                throw new ArgumentException($"Block type {type} is already registered");
            }

            _blockDefinitions[type] = definition;
            _nameToType[definition.Name] = type;
        }

        /// <summary>
        /// 获取方块定义
        /// </summary>
        public BlockDefinition GetBlockDefinition(BlockType type)
        {
            if (_blockDefinitions.TryGetValue(type, out var definition))
            {
                return definition;
            }

            return BlockDefinition.Default;
        }

        /// <summary>
        /// 通过名称获取方块类型
        /// </summary>
        public BlockType GetBlockType(string name)
        {
            if (_nameToType.TryGetValue(name, out var type))
            {
                return type;
            }

            return BlockType.Air;
        }

        /// <summary>
        /// 检查方块是否透明
        /// </summary>
        public bool IsTransparent(BlockType type)
        {
            return GetBlockDefinition(type).IsTransparent;
        }

        /// <summary>
        /// 检查方块是否为固体
        /// </summary>
        public bool IsSolid(BlockType type)
        {
            return GetBlockDefinition(type).IsSolid;
        }

        /// <summary>
        /// 检查方块是否应该渲染面
        /// </summary>
        public bool ShouldRenderFace(BlockType type)
        {
            return GetBlockDefinition(type).ShouldRenderFace;
        }

        /// <summary>
        /// 获取方块的基础颜色
        /// </summary>
        public Color GetBaseColor(BlockType type)
        {
            return GetBlockDefinition(type).BaseColor;
        }

        /// <summary>
        /// 创建默认的UV坐标
        /// 简化实现：所有面使用相同的UV坐标
        /// </summary>
        private Vector3[] CreateDefaultUVs()
        {
            return new Vector3[6]
            {
                new Vector3(0, 0, 0), // Up
                new Vector3(0, 0, 0), // Down
                new Vector3(0, 0, 0), // North
                new Vector3(0, 0, 0), // South
                new Vector3(0, 0, 0), // East
                new Vector3(0, 0, 0)  // West
            };
        }

        /// <summary>
        /// 获取所有注册的方块类型
        /// </summary>
        public IEnumerable<BlockType> GetAllBlockTypes()
        {
            return _blockDefinitions.Keys;
        }

        /// <summary>
        /// 检查方块类型是否已注册
        /// </summary>
        public bool IsBlockTypeRegistered(BlockType type)
        {
            return _blockDefinitions.ContainsKey(type);
        }
    }

    /// <summary>
    /// 方块工具类
    /// 提供方块相关的实用方法
    /// </summary>
    public static class BlockHelper
    {
        /// <summary>
        /// 检查方块面是否可见
        /// 简化实现：只检查相邻方块是否为透明
        /// </summary>
        public static bool IsFaceVisible(BlockType currentBlock, BlockType adjacentBlock, Direction direction)
        {
            // 如果当前方块不渲染面，则不可见
            if (currentBlock == BlockType.Air)
                return false;

            // 如果相邻方块是透明方块，则当前方块面可见
            // 这里需要通过BlockRegistry实例来检查方块透明度，但由于是静态方法，我们使用简化的透明方块检查
            return IsTransparentBlock(adjacentBlock);
        }

        /// <summary>
        /// 检查方块是否透明（简化实现）
        /// </summary>
        private static bool IsTransparentBlock(BlockType blockType)
        {
            return blockType == BlockType.Air || 
                   blockType == BlockType.Water || 
                   blockType == BlockType.Glass || 
                   blockType == BlockType.Leaves;
        }

        /// <summary>
        /// 获取方块面的法线方向
        /// </summary>
        public static Vector3 GetFaceNormal(Direction direction)
        {
            return direction switch
            {
                Direction.Up => Vector3.Up,
                Direction.Down => Vector3.Down,
                Direction.North => Vector3.Forward,
                Direction.South => Vector3.Backward,
                Direction.East => Vector3.Right,
                Direction.West => Vector3.Left,
                _ => Vector3.Zero
            };
        }

        /// <summary>
        /// 获取方块面的顶点偏移
        /// 用于计算方块面的顶点位置
        /// </summary>
        public static Vector3[] GetFaceVertices(Direction direction, Vector3 position)
        {
            var halfSize = Vector3.One * 0.5f;
            var basePos = position;

            return direction switch
            {
                Direction.Up => new Vector3[]
                {
                    basePos + new Vector3(-halfSize.X, halfSize.Y, -halfSize.Z),
                    basePos + new Vector3(halfSize.X, halfSize.Y, -halfSize.Z),
                    basePos + new Vector3(halfSize.X, halfSize.Y, halfSize.Z),
                    basePos + new Vector3(-halfSize.X, halfSize.Y, halfSize.Z)
                },
                Direction.Down => new Vector3[]
                {
                    basePos + new Vector3(-halfSize.X, -halfSize.Y, -halfSize.Z),
                    basePos + new Vector3(-halfSize.X, -halfSize.Y, halfSize.Z),
                    basePos + new Vector3(halfSize.X, -halfSize.Y, halfSize.Z),
                    basePos + new Vector3(halfSize.X, -halfSize.Y, -halfSize.Z)
                },
                Direction.North => new Vector3[]
                {
                    basePos + new Vector3(-halfSize.X, -halfSize.Y, -halfSize.Z),
                    basePos + new Vector3(halfSize.X, -halfSize.Y, -halfSize.Z),
                    basePos + new Vector3(halfSize.X, halfSize.Y, -halfSize.Z),
                    basePos + new Vector3(-halfSize.X, halfSize.Y, -halfSize.Z)
                },
                Direction.South => new Vector3[]
                {
                    basePos + new Vector3(-halfSize.X, -halfSize.Y, halfSize.Z),
                    basePos + new Vector3(-halfSize.X, halfSize.Y, halfSize.Z),
                    basePos + new Vector3(halfSize.X, halfSize.Y, halfSize.Z),
                    basePos + new Vector3(halfSize.X, -halfSize.Y, halfSize.Z)
                },
                Direction.East => new Vector3[]
                {
                    basePos + new Vector3(halfSize.X, -halfSize.Y, -halfSize.Z),
                    basePos + new Vector3(halfSize.X, -halfSize.Y, halfSize.Z),
                    basePos + new Vector3(halfSize.X, halfSize.Y, halfSize.Z),
                    basePos + new Vector3(halfSize.X, halfSize.Y, -halfSize.Z)
                },
                Direction.West => new Vector3[]
                {
                    basePos + new Vector3(-halfSize.X, -halfSize.Y, -halfSize.Z),
                    basePos + new Vector3(-halfSize.X, halfSize.Y, -halfSize.Z),
                    basePos + new Vector3(-halfSize.X, halfSize.Y, halfSize.Z),
                    basePos + new Vector3(-halfSize.X, -halfSize.Y, halfSize.Z)
                },
                _ => new Vector3[4]
            };
        }
    }
}
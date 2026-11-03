using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using MCGame.Core;

namespace MCGame.WorldGeneration
{
    /// <summary>
    /// 柏林噪声生成器，用于程序化地形生成
    /// </summary>
    public class PerlinNoise
    {
        private readonly int[] _permutation;
        private readonly Random _random;

        /// <summary>
        /// 初始化柏林噪声生成器
        /// </summary>
        /// <param name="seed">随机种子</param>
        public PerlinNoise(int seed = 0)
        {
            _random = new Random(seed);
            _permutation = new int[512];
            
            // 生成排列表
            var p = new int[256];
            for (int i = 0; i < 256; i++)
            {
                p[i] = i;
            }
            
            // 随机打乱排列表
            for (int i = 255; i > 0; i--)
            {
                int j = _random.Next(i + 1);
                (p[i], p[j]) = (p[j], p[i]);
            }
            
            // 复制排列表以避免溢出
            for (int i = 0; i < 256; i++)
            {
                _permutation[i] = p[i];
                _permutation[i + 256] = p[i];
            }
        }

        /// <summary>
        /// 获取2D柏林噪声值
        /// </summary>
        /// <param name="x">X坐标</param>
        /// <param name="y">Y坐标</param>
        /// <returns>噪声值（-1到1之间）</returns>
        public float Noise(float x, float y)
        {
            // 找到网格单元坐标
            int X = (int)Math.Floor(x) & 255;
            int Y = (int)Math.Floor(y) & 255;
            
            // 找到相对坐标
            x -= (float)Math.Floor(x);
            y -= (float)Math.Floor(y);
            
            // 计算淡入淡出曲线
            float u = Fade(x);
            float v = Fade(y);
            
            // 混合四个角的贡献
            int a = _permutation[X] + Y;
            int aa = _permutation[a];
            int ab = _permutation[a + 1];
            int b = _permutation[X + 1] + Y;
            int ba = _permutation[b];
            int bb = _permutation[b + 1];
            
            // 插值
            float x1 = Lerp(Grad(_permutation[aa], x, y), Grad(_permutation[ba], x - 1, y), u);
            float x2 = Lerp(Grad(_permutation[ab], x, y - 1), Grad(_permutation[bb], x - 1, y - 1), u);
            
            return Lerp(x1, x2, v);
        }

        /// <summary>
        /// 获取多层噪声（分形噪声）
        /// </summary>
        /// <param name="x">X坐标</param>
        /// <param name="y">Y坐标</param>
        /// <param name="octaves">层数</param>
        /// <param name="persistence">持续性</param>
        /// <param name="scale">缩放</param>
        /// <returns>分形噪声值</returns>
        public float FractalNoise(float x, float y, int octaves = 4, float persistence = 0.5f, float scale = 0.01f)
        {
            float total = 0;
            float frequency = scale;
            float amplitude = 1;
            float maxValue = 0;
            
            for (int i = 0; i < octaves; i++)
            {
                total += Noise(x * frequency, y * frequency) * amplitude;
                maxValue += amplitude;
                amplitude *= persistence;
                frequency *= 2;
            }
            
            return total / maxValue;
        }

        /// <summary>
        /// 获取3D多层噪声（分形噪声）
        /// </summary>
        /// <param name="x">X坐标</param>
        /// <param name="y">Y坐标</param>
        /// <param name="z">Z坐标</param>
        /// <param name="octaves">层数</param>
        /// <param name="persistence">持续性</param>
        /// <param name="scale">缩放</param>
        /// <returns>分形噪声值</returns>
        public float FractalNoise(float x, float y, float z, int octaves = 4, float persistence = 0.5f, float scale = 0.01f)
        {
            float total = 0;
            float frequency = scale;
            float amplitude = 1;
            float maxValue = 0;
            
            for (int i = 0; i < octaves; i++)
            {
                total += Noise3D(x * frequency, y * frequency, z * frequency) * amplitude;
                maxValue += amplitude;
                amplitude *= persistence;
                frequency *= 2;
            }
            
            return total / maxValue;
        }

        /// <summary>
        /// 获取地形高度
        /// </summary>
        /// <param name="x">X坐标</param>
        /// <param name="z">Z坐标</param>
        /// <param name="seaLevel">海平面高度</param>
        /// <returns>地形高度</returns>
        public int GetTerrainHeight(int x, int z, int seaLevel = 64)
        {
            // 使用分形噪声生成地形
            float height = FractalNoise(x, z, 4, 0.5f, 0.005f);
            
            // 将噪声值映射到高度范围
            int minHeight = 0;
            int maxHeight = 256;
            int terrainHeight = (int)(minHeight + (height + 1) * 0.5f * (maxHeight - minHeight));
            
            // 确保高度在合理范围内
            terrainHeight = Math.Max(minHeight, Math.Min(maxHeight, terrainHeight));
            
            return terrainHeight;
        }

        /// <summary>
        /// 获取生物群系类型
        /// </summary>
        /// <param name="x">X坐标</param>
        /// <param name="z">Z坐标</param>
        /// <returns>生物群系类型</returns>
        public BiomeType GetBiomeType(int x, int z)
        {
            // 使用不同的噪声参数确定生物群系
            float temperature = FractalNoise(x, z, 2, 0.7f, 0.002f);
            float humidity = FractalNoise(x + 1000, z + 1000, 2, 0.7f, 0.002f);
            
            // 根据温度和湿度确定生物群系
            if (temperature < -0.3f)
            {
                return BiomeType.Tundra;
            }
            else if (temperature < 0.1f)
            {
                if (humidity > 0.2f)
                    return BiomeType.Taiga;
                else
                    return BiomeType.Plains;
            }
            else if (temperature < 0.4f)
            {
                if (humidity > 0.4f)
                    return BiomeType.Forest;
                else if (humidity > 0.1f)
                    return BiomeType.Plains;
                else
                    return BiomeType.Desert;
            }
            else
            {
                if (humidity > 0.3f)
                    return BiomeType.Jungle;
                else
                    return BiomeType.Desert;
            }
        }

        /// <summary>
        /// 淡入淡出曲线
        /// </summary>
        private static float Fade(float t)
        {
            return t * t * t * (t * (t * 6 - 15) + 10);
        }

        /// <summary>
        /// 线性插值
        /// </summary>
        private static float Lerp(float a, float b, float t)
        {
            return a + t * (b - a);
        }

        /// <summary>
        /// 梯度函数
        /// </summary>
        private static float Grad(int hash, float x, float y)
        {
            int h = hash & 15;
            float u = h < 8 ? x : y;
            float v = h < 4 ? y : h == 12 || h == 14 ? x : 0;
            return ((h & 1) == 0 ? u : -u) + ((h & 2) == 0 ? v : -v);
        }

        /// <summary>
        /// 3D梯度函数
        /// </summary>
        private static float Grad(int hash, float x, float y, float z)
        {
            int h = hash & 15;
            float u = h < 8 ? x : y;
            float v = h < 4 ? y : h == 12 || h == 14 ? x : z;
            return ((h & 1) == 0 ? u : -u) + ((h & 2) == 0 ? v : -v);
        }

        /// <summary>
        /// 获取3D柏林噪声值
        /// </summary>
        /// <param name="x">X坐标</param>
        /// <param name="y">Y坐标</param>
        /// <param name="z">Z坐标</param>
        /// <returns>噪声值（-1到1之间）</returns>
        public float Noise3D(float x, float y, float z)
        {
            // 简化的3D噪声实现
            float xy = Noise(x, y);
            float yz = Noise(y, z);
            float xz = Noise(x, z);
            
            return (xy + yz + xz) / 3.0f;
        }
    }

    /// <summary>
    /// 生物群系类型
    /// </summary>
    public enum BiomeType
    {
        /// <summary>海洋</summary>
        Ocean,
        /// <summary>平原</summary>
        Plains,
        /// <summary>沙漠</summary>
        Desert,
        /// <summary>森林</summary>
        Forest,
        /// <summary>针叶林</summary>
        Taiga,
        /// <summary>丛林</summary>
        Jungle,
        /// <summary>苔原</summary>
        Tundra,
        /// <summary>山脉</summary>
        Mountains
    }

    /// <summary>
    /// 世界生成器，负责生成地形和生物群系
    /// </summary>
    public class WorldGenerator
    {
        private readonly PerlinNoise _heightNoise;
        private readonly PerlinNoise _biomeNoise;
        private readonly PerlinNoise _caveNoise;
        private readonly int _seed;

        /// <summary>
        /// 初始化世界生成器
        /// </summary>
        /// <param name="seed">世界种子</param>
        public WorldGenerator(int seed = 0)
        {
            _seed = seed;
            _heightNoise = new PerlinNoise(seed);
            _biomeNoise = new PerlinNoise(seed + 1000);
            _caveNoise = new PerlinNoise(seed + 2000);
        }

        /// <summary>
        /// 生成区块数据
        /// </summary>
        /// <param name="chunkX">区块X坐标</param>
        /// <param name="chunkZ">区块Z坐标</param>
        /// <param name="chunkSize">区块大小</param>
        /// <returns>区块数据数组</returns>
        public byte[,,] GenerateChunk(int chunkX, int chunkZ, int chunkSize = 16)
        {
            // 修改为支持完整高度的区块数据格式：16x256x16
            var chunkData = new byte[chunkSize, 256, chunkSize];
            int worldX = chunkX * chunkSize;
            int worldZ = chunkZ * chunkSize;

            for (int x = 0; x < chunkSize; x++)
            {
                for (int z = 0; z < chunkSize; z++)
                {
                    int worldPosX = worldX + x;
                    int worldPosZ = worldZ + z;

                    // 获取地形高度
                    int terrainHeight = _heightNoise.GetTerrainHeight(worldPosX, worldPosZ);
                    
                    // 获取生物群系
                    BiomeType biome = _biomeNoise.GetBiomeType(worldPosX, worldPosZ);

                    // 生成地形 - 现在支持完整高度范围（0-255）
                    for (int y = 0; y < 256; y++)
                    {
                        int worldY = y;
                        
                        // 基础地形生成
                        if (worldY < terrainHeight)
                        {
                            if (worldY < 5)
                            {
                                // 基岩层
                                chunkData[x, y, z] = (byte)BlockType.Bedrock;
                            }
                            else if (worldY < terrainHeight - 3)
                            {
                                // 石头层
                                chunkData[x, y, z] = (byte)BlockType.Stone;
                            }
                            else
                            {
                                // 根据生物群系设置表层方块
                                chunkData[x, y, z] = (byte)GetSurfaceBlock(biome, worldY, terrainHeight);
                            }
                        }
                        else if (worldY == terrainHeight)
                        {
                            // 表层方块
                            chunkData[x, y, z] = (byte)GetSurfaceBlock(biome, worldY, terrainHeight);
                        }
                        else
                        {
                            // 空气
                            chunkData[x, y, z] = (byte)BlockType.Air;
                        }

                        // 生成洞穴 - 只在合理的Y范围内生成
                        if (worldY > 5 && worldY < terrainHeight && ShouldGenerateCave(worldPosX, worldY, worldPosZ))
                        {
                            chunkData[x, y, z] = (byte)BlockType.Air;
                        }
                    }
                }
            }

            return chunkData;
        }

        /// <summary>
        /// 获取表层方块类型
        /// </summary>
        /// <param name="biome">生物群系</param>
        /// <param name="y">Y坐标</param>
        /// <param name="terrainHeight">地形高度</param>
        /// <returns>方块类型</returns>
        private BlockType GetSurfaceBlock(BiomeType biome, int y, int terrainHeight)
        {
            switch (biome)
            {
                case BiomeType.Desert:
                    return BlockType.Sand;
                case BiomeType.Ocean:
                    return y < 62 ? BlockType.Sand : BlockType.Dirt;
                case BiomeType.Forest:
                case BiomeType.Plains:
                case BiomeType.Taiga:
                    return y == terrainHeight ? BlockType.Grass : BlockType.Dirt;
                case BiomeType.Jungle:
                    return y == terrainHeight ? BlockType.Grass : BlockType.Dirt;
                case BiomeType.Tundra:
                    return BlockType.Dirt; // 使用泥土代替雪，因为Core中没有Snow类型
                case BiomeType.Mountains:
                    return BlockType.Stone;
                default:
                    return BlockType.Dirt;
            }
        }

        /// <summary>
        /// 判断是否应该生成洞穴
        /// </summary>
        /// <param name="x">X坐标</param>
        /// <param name="y">Y坐标</param>
        /// <param name="z">Z坐标</param>
        /// <returns>是否生成洞穴</returns>
        private bool ShouldGenerateCave(int x, int y, int z)
        {
            // 只在地下生成洞穴
            if (y > 50) return false;
            if (y < 10) return false;

            // 使用3D噪声生成洞穴
            float caveNoise = _caveNoise.FractalNoise(x, y, z, 3, 0.5f, 0.02f);
            
            // 噪声值大于阈值时生成洞穴
            return caveNoise > 0.6f;
        }

        /// <summary>
        /// 获取世界种子
        /// </summary>
        public int Seed => _seed;
    }
}
# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

这是一个基于MonoGame框架的类Minecraft游戏，实现了体素化世界渲染、柏林噪声地形生成和第一人称游戏体验。项目采用C# 13.0和.NET 9.0开发。

## 常用命令

### 构建和运行
```bash
# 构建主项目
dotnet build MCGame.csproj

# 运行游戏
dotnet run --project MCGame.csproj

# 发布游戏 - Windows版本
dotnet publish -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true

# 发布游戏 - Linux版本
dotnet publish -c Release -r linux-x64 --self-contained true -p:PublishSingleFile=true

# 构建测试项目
dotnet build tests/MCGame.Tests.csproj
```

### 测试
```bash
# 运行所有测试
dotnet test tests/MCGame.Tests.csproj

# 运行单个测试（示例）
dotnet test tests/MCGame.Tests.csproj --filter "TestName"
```

## 核心架构

### 系统架构
项目采用模块化设计，主要包含以下核心系统：

1. **核心系统** (`src/Core/`)
   - `MCGame.cs` - 主游戏类，管理游戏循环和系统初始化
   - `Structures.cs` - 核心数据结构定义

2. **区块系统** (`src/Chunks/`)
   - `Chunk.cs` - 16x16x256区块实现，使用16位方块数据存储
   - `ChunkManager.cs` - 区块管理器，处理动态加载和卸载

3. **渲染系统** (`src/Rendering/`)
   - `ChunkMesh.cs` - 区块网格管理，支持网格合并优化
   - `ChunkMesher.cs` - 网格生成器，处理可见面计算
   - `RenderPipeline.cs` - 渲染管道，管理DrawCall和性能优化
   - `FrustumCulling.cs` - 视锥剔除，使用球形包围盒优化

4. **世界生成** (`src/WorldGeneration/`)
   - `PerlinNoise.cs` - 柏林噪声生成器，支持2D/3D噪声
   - 集成到区块系统中的程序化地形生成

5. **方块系统** (`src/Blocks/`)
   - `BlockRegistry.cs` - 方块注册表，管理方块类型

6. **玩家系统** (`src/Player/`)
   - `Player.cs` - 玩家控制和物理系统

### 关键设计模式

#### 区块网格合并
- **实现位置**: `src/Rendering/ChunkMesh.cs`
- **简化实现**: 合并整个区块的可见面为单一网格，大幅减少DrawCall
- **性能优化**: 使用16位索引缓冲区，支持顶点重用

#### 视锥剔除
- **实现位置**: `src/Rendering/FrustumCulling.cs`
- **简化实现**: 使用球形包围盒而非AABB，性能更好但精度略低
- **优化策略**: 结合距离剔除，避免渲染远距离区块

#### 内存优化
- **方块数据存储**: 使用16位而非32位存储方块信息，节省50%内存
- **对象池**: `src/Utils/ObjectPool.cs` - 减少内存分配和GC压力

### 柏林噪声地形生成

#### 核心算法
- **实现位置**: `src/WorldGeneration/PerlinNoise.cs`
- **特性**: 支持分形噪声、3D洞穴生成、生物群系系统
- **集成**: 在`Chunk.cs`的`GenerateTerrain()`方法中调用

#### 生物群系系统
- **类型**: 平原、沙漠、森林、针叶林、丛林、苔原、山脉
- **生成参数**: 基于温度和湿度计算
- **高度变化**: 使用多层噪声叠加实现自然地形

### 性能目标
- **帧率**: 稳定60 FPS
- **DrawCall**: < 1000次/帧
- **内存使用**: < 2GB
- **可见区块**: 10-15个区块（取决于渲染距离）

## 开发注意事项

### 项目结构规范
- 所有源代码位于`src/`目录下
- 按功能模块组织子目录
- 遵循C#命名规范和代码组织原则

### 性能优化重点
1. **网格合并**: 确保每个区块只生成一个网格
2. **视锥剔除**: 只渲染可见区块
3. **多线程**: 异步区块生成和网格计算
4. **内存管理**: 使用对象池和16位数据存储

### 调试功能
- **F3**: 切换调试模式，显示性能统计
- **F11**: 切换全屏
- **+/-**: 调整渲染距离
- **F**: 切换飞行模式
- **R**: 重新生成世界

### 已知简化实现
1. **着色器系统**: 使用基础光照着色器而非复杂PBR
2. **物理系统**: 简化的碰撞检测和物理模拟
3. **多线程管理**: 使用.NET内置任务池
4. **内容管理**: 暂时禁用MonoGame内容构建器

## 依赖关系
- **MonoGame.Framework.DesktopGL** 3.8.1.303
- **.NET 9.0** 运行时
- **HLSL** 着色器语言

## 构建配置
- **目标框架**: net9.0
- **目标平台**: win-x64,linux-x64
- **发布模式**: 单文件发布，自包含
- **GC配置**: 服务器GC，并发GC
- **优化**: 启用ReadyToRun和压缩

## 目录结构
- docker相关配置放在docker文件夹中
- 临时文件放在tmp文件夹中
- 测试项目放在tests文件夹中
- 脚本放在scripts文件夹中
- 文档放在docs文件夹中
- 正常的游戏代码放在src文件夹中
- 游戏素材放在assets文件夹中

## 其他注意事项
- 根目录中不要随便建任何的sh、md、py、csproj等文件，所有的文件建立需要放置在相关的目录中，根目录需要保持干净
- 根目录中必须保证没有其他的csproj文件，以确保dotnet命令可以找到唯一的解决方案
- 如果是外面下载的库，项目引用务必使用对应库的nuget包来引用，严禁本地直接引用
- 这是在WSL2环境运行的，所以你可以直接运行windows程序

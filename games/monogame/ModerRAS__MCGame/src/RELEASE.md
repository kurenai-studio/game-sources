# 发布说明

## 自动发布功能

本项目现在支持自动发布release功能，可以通过GitHub Actions自动构建和发布跨平台版本。

### 发布方式

#### 1. 标签触发发布（推荐）

创建版本标签会自动触发发布：

```bash
# 使用版本管理脚本
./scripts/version.sh 1.0.1 "Bug Fix Release"

# 或者手动创建标签
git tag -a "v1.0.1" -m "Release description"
git push origin v1.0.1
```

#### 2. 手动触发发布

1. 访问 [GitHub Actions](https://github.com/ModerRAS/MCGame/actions)
2. 选择 "Create Release" workflow
3. 点击 "Run workflow"
4. 输入版本号和发布标题
5. 选择是否为预发布版本

### 版本管理脚本

#### Linux/Mac
```bash
./scripts/version.sh <版本号> [发布标题]
# 例如: ./scripts/version.sh 1.0.1 "Bug Fix Release"
```

#### Windows
```cmd
scripts\version.bat <版本号> [发布标题]
# 例如: scripts\version.bat 1.0.1 "Bug Fix Release"
```

### 发布内容

自动发布包含：
- **Windows版本**: MCGame-Windows-x64.zip
- **Linux版本**: MCGame-Linux-x64.tar.gz
- **发布说明**: 自动生成的功能介绍和使用说明

### 系统要求

- .NET 9.0 Runtime
- OpenGL 3.3+ 兼容显卡
- 最少2GB内存

### 安装说明

1. 下载对应平台的发布包
2. 解压文件
3. 运行可执行文件：
   - Windows: MCGame.exe
   - Linux: ./MCGame

### 控制说明

- **WASD**: 移动
- **鼠标**: 视角控制
- **空格**: 跳跃
- **Shift**: 冲刺
- **F**: 切换飞行模式
- **F3**: 切换调试信息
- **F11**: 切换全屏
- **+/-**: 调整渲染距离
- **R**: 重新生成世界

### 技术特性

- 基于MonoGame 3.8.1
- 使用Friflo ECS实体组件系统
- 程序化地形生成
- 基于区块的世界渲染
- 高性能的内存管理
- 完整的性能监控

### 已知问题

- ECS实体删除在某些边缘情况下可能有问题
- 性能可能因硬件配置而异
- 大型世界的优化有限

### 开发信息

- **架构**: ECS (Entity Component System)
- **语言**: C# 13.0
- **框架**: .NET 9.0
- **图形**: OpenGL (MonoGame)
- **平台**: Windows, Linux

### 构建说明

本地构建：

```bash
# 构建项目
dotnet build MCGame.csproj

# 发布Windows版本
dotnet publish -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true

# 发布Linux版本
dotnet publish -c Release -r linux-x64 --self-contained true -p:PublishSingleFile=true
```

### 支持和反馈

如有问题或建议，请通过GitHub Issues反馈。
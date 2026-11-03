using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using MCGame.Blocks;
using MCGame.Chunks;
using MCGame.Player;
using MCGame.Rendering;
using MCGame.Utils;
// using MCGame.ECS;
// using MCGame.ECS.Managers;
// using MCGame.ECS.Systems;
// using Friflo.Engine.ECS;
// using Friflo.Engine.ECS.Systems;
// using MCGame.ECS.Components;
// using Pos = MCGame.ECS.Components.Position;
// using Rot = MCGame.ECS.Components.Rotation;
// using PlayerComp = MCGame.ECS.Components.Player;
using System;
using System.Collections.Generic;
using System.Diagnostics;

namespace MCGame.Core
{
    /// <summary>
    /// MCGame主游戏类
    /// 基于MonoGame框架的类Minecraft游戏主程序
    /// 简化实现：基础的游戏循环和系统管理
    /// </summary>
    public class MCGame : Game
    {
        // MonoGame组件
        private CustomGraphicsDeviceManager _graphics;
        private SpriteBatch _spriteBatch;
        private SpriteFont _debugFont;
        private Texture2D _pixelTexture;

        // 核心系统
        private BlockRegistry _blockRegistry;
        private ChunkManager _chunkManager;
        private PlayerController _playerController;
        private RenderManager _renderManager;

        // ECS系统 - 暂时禁用
        // private ECSWorld _ecsWorld;
        // private ECSBlockManager _ecsBlockManager;
        // private ECSChunkManager _ecsChunkManager;
        // private SystemRoot _systemRoot;
        // private ECSRenderManager _ecsRenderManager;
        // private PerformanceBenchmarkSystem _benchmarkSystem;

        // 游戏状态
        private WorldSettings _worldSettings;
        private bool _isInitialized;
        private bool _debugMode;
        private bool _ecsEnabled;

        // 性能监控
        private Stopwatch _frameStopwatch;
        private float _frameTime;
        private int _fps;
        private int _frameCount;
        private float _fpsTimer;

        // 调试信息
        private RenderStatistics _renderStats;
        private ChunkManagerStats _chunkStats;

        // 相机参数
        private float _renderDistance = 150f;

        public MCGame()
        {
            try
            {
                // 初始化Serilog日志系统
                Logger.Initialize(useSerilog: true);
                var serilogLogger = Logger.GetSerilogLogger();
                serilogLogger?.Info("=== MCGame Starting ===");
                serilogLogger?.MemoryUsage();
                
                Logger.Info("Initializing MCGame...");
                
                // 创建图形设备管理器
                try
                {
                    Logger.Info("Creating Graphics Device Manager...");
                    _graphics = new CustomGraphicsDeviceManager(this);
                    Logger.Info("CustomGraphicsDeviceManager created successfully");
                }
                catch (Exception ex)
                {
                    Logger.Fatal($"Failed to create CustomGraphicsDeviceManager: {ex.Message}", ex);
                    throw;
                }
                
                Content.RootDirectory = "Content";
                IsMouseVisible = true;
                
                // 设置窗口标题
                Window.Title = "MCGame - MonoGame Minecraft Clone";
                
                // 初始化性能监控
                _frameStopwatch = new Stopwatch();
                _renderStats = new RenderStatistics();
                _debugMode = true;
                
                Logger.Info("MCGame constructor completed successfully");
            }
            catch (Exception ex)
            {
                Logger.Fatal($"Failed to initialize MCGame: {ex.Message}", ex);
                throw;
            }
        }

        /// <summary>
        /// 初始化游戏
        /// </summary>
        protected override void Initialize()
        {
            try
            {
                var serilogLogger = Logger.GetSerilogLogger();
                serilogLogger?.Info("Starting game initialization...");
                serilogLogger?.MemoryUsage();
                
                Logger.Info("Starting game initialization...");
                
                // 设置图形设备参数
                Logger.Debug("Configuring graphics...");
                
                // 尝试使用自定义图形设备管理器
                if (_graphics != null)
                {
                    Logger.Debug("Trying to create graphics device...");
                    bool deviceConfigured = _graphics.TryCreateDevice();
                    if (!deviceConfigured)
                    {
                        Logger.Fatal("Failed to configure any graphics device");
                        throw new InvalidOperationException("No suitable graphics device configuration found");
                    }
                    serilogLogger?.Info("Graphics device configured successfully");
                }
                
                DetectGraphicsCapabilities();
                ConfigureGraphics();

                // 初始化对象池管理器
                Logger.Debug("Initializing object pool manager...");
                ObjectPoolManager.Initialize();

                // 初始化世界设置
                Logger.Debug("Setting up world settings...");
                _worldSettings = WorldSettings.Default;
                _worldSettings.RenderDistance = 10;
                serilogLogger?.Info($"World settings configured with render distance: {_worldSettings.RenderDistance}");

                // 初始化核心系统
                serilogLogger?.Info("Initializing Core Systems...");
                Logger.Debug("Initializing core systems...");
                InitializeCoreSystems();
                serilogLogger?.Info("Core Systems initialized successfully");

                // 初始化输入处理
                Logger.Debug("Initializing input handling...");
                InitializeInput();

                serilogLogger?.Info("Game initialization completed successfully");
                serilogLogger?.MemoryUsage();
                Logger.Info("Game initialization completed successfully");
                
                base.Initialize();
            }
            catch (Exception ex)
            {
                Logger.Fatal($"Failed to initialize game: {ex.Message}", ex);
                throw;
            }
        }

        /// <summary>
        /// 检测图形设备能力
        /// 简化实现：检查系统是否支持所需的图形功能
        /// </summary>
        private void DetectGraphicsCapabilities()
        {
            try
            {
                Logger.Debug("Detecting graphics capabilities...");
                
                // 检查是否有图形设备
                if (_graphics == null)
                {
                    Logger.Error("CustomGraphicsDeviceManager is null");
                    return;
                }
                
                // 记录默认设置
                Logger.Debug($"Default graphics profile: {_graphics.GraphicsProfile}");
                Logger.Debug($"Default back buffer size: {_graphics.PreferredBackBufferWidth}x{_graphics.PreferredBackBufferHeight}");
                
                // 检查支持的图形配置
                var supportedProfiles = new List<GraphicsProfile>();
                foreach (GraphicsProfile profile in Enum.GetValues(typeof(GraphicsProfile)))
                {
                    try
                    {
                        _graphics.GraphicsProfile = profile;
                        Logger.Debug($"Graphics profile {profile} is supported");
                        supportedProfiles.Add(profile);
                    }
                    catch
                    {
                        Logger.Debug($"Graphics profile {profile} is not supported");
                    }
                }
                
                Logger.Info($"Supported graphics profiles: {string.Join(", ", supportedProfiles)}");
                
                // 恢复默认profile
                if (supportedProfiles.Contains(GraphicsProfile.HiDef))
                {
                    _graphics.GraphicsProfile = GraphicsProfile.HiDef;
                }
                else if (supportedProfiles.Contains(GraphicsProfile.Reach))
                {
                    _graphics.GraphicsProfile = GraphicsProfile.Reach;
                }
                
                Logger.Debug($"Selected graphics profile: {_graphics.GraphicsProfile}");
                
                // 记录详细的图形能力信息
                _graphics.LogGraphicsCapabilities();
            }
            catch (Exception ex)
            {
                Logger.Error($"Failed to detect graphics capabilities: {ex.Message}");
            }
        }

        /// <summary>
        /// 配置图形设备
        /// 简化实现：支持图形配置降级，从HiDef到Reach profile
        /// </summary>
        private void ConfigureGraphics()
        {
            try
            {
                Logger.Debug("Configuring graphics device...");
                
                // 设置窗口大小
                _graphics.PreferredBackBufferWidth = 1280;
                _graphics.PreferredBackBufferHeight = 720;
                _graphics.IsFullScreen = false;
                _graphics.SynchronizeWithVerticalRetrace = true;
                
                // 尝试使用HiDef profile，如果失败则降级到Reach
                try
                {
                    _graphics.GraphicsProfile = GraphicsProfile.HiDef;
                    Logger.Debug($"Attempting to use HiDef graphics profile");
                }
                catch (Exception ex)
                {
                    Logger.Warning($"HiDef profile not supported: {ex.Message}");
                    Logger.Debug("Falling back to Reach graphics profile");
                    _graphics.GraphicsProfile = GraphicsProfile.Reach;
                }
                
                Logger.Debug($"Set resolution to 1280x720, {_graphics.GraphicsProfile} profile");
                
                // 尝试应用图形设置
                try
                {
                    _graphics.ApplyChanges();
                    Logger.Debug("Applied graphics settings");
                }
                catch (Exception ex)
                {
                    Logger.Error($"Failed to apply graphics settings: {ex.Message}");
                    
                    // 尝试更基础的设置
                    Logger.Debug("Attempting basic graphics configuration");
                    _graphics.PreferredBackBufferWidth = 800;
                    _graphics.PreferredBackBufferHeight = 600;
                    _graphics.GraphicsProfile = GraphicsProfile.Reach;
                    _graphics.SynchronizeWithVerticalRetrace = false;
                    
                    _graphics.ApplyChanges();
                    Logger.Debug("Applied basic graphics settings");
                }

                // 设置视口
                try
                {
                    GraphicsDevice.Viewport = new Viewport(0, 0, _graphics.PreferredBackBufferWidth, _graphics.PreferredBackBufferHeight);
                    Logger.Debug("Set viewport");
                }
                catch (Exception ex)
                {
                    Logger.Error($"Failed to set viewport: {ex.Message}");
                    // 如果视口设置失败，使用默认视口
                }
                
                Logger.Info($"Graphics device configured successfully with {_graphics.GraphicsProfile} profile");
            }
            catch (Exception ex)
            {
                Logger.Fatal($"Failed to configure graphics device: {ex.Message}", ex);
                throw;
            }
        }

        /// <summary>
        /// 初始化核心系统
        /// </summary>
        private void InitializeCoreSystems()
        {
            try
            {
                Logger.Debug("Initializing core systems...");
                
                // 初始化方块注册表
                Logger.Debug("Creating block registry...");
                _blockRegistry = new BlockRegistry(GraphicsDevice);
                Logger.Info("Block registry initialized successfully");

                // 初始化区块管理器
                Logger.Debug("Creating chunk manager...");
                _chunkManager = new ChunkManager(GraphicsDevice, _blockRegistry, _worldSettings);
                Logger.Info("Chunk manager initialized successfully");

                // 初始化玩家控制器
                Logger.Debug("Creating player controller...");
                var initialPosition = new Vector3(0, 130, 0); // 在地形上方（地形高度约128）
                _playerController = new PlayerController(GraphicsDevice, initialPosition);
                Logger.Info($"Player controller initialized at position {initialPosition}");

                // 初始化渲染管理器
                Logger.Debug("Creating render manager...");
                _renderManager = new RenderManager(GraphicsDevice, _blockRegistry);

                // 配置渲染选项
                Logger.Debug("Configuring rendering options...");
                ConfigureRendering();

                // 初始化ECS系统 - 暂时禁用
                // InitializeECS();
                // InitializeECSRendering();

                _isInitialized = true;
                Logger.Info("Core systems initialized successfully");
            }
            catch (Exception ex)
            {
                Logger.Fatal($"Failed to initialize core systems: {ex.Message}", ex);
                throw;
            }
        }

        /// <summary>
        /// 配置渲染选项
        /// </summary>
        private void ConfigureRendering()
        {
            // 设置渲染距离
            _renderManager.FrustumCulling.SetMaxRenderDistance(_renderDistance);

            // 设置雾效
            _renderManager.SetRenderOptions(
                fogEnabled: true,
                fogStart: 50f,
                fogEnd: _renderDistance,
                fogColor: new Color(135, 206, 235) // 天空蓝
            );

            // 设置光照
            _renderManager.SetLighting(
                ambient: new Vector3(0.3f, 0.3f, 0.3f),
                lightDirection: new Vector3(0.5f, -1f, 0.5f),
                lightColor: new Vector3(1f, 1f, 0.9f)
            );
        }

     
    
        /// <summary>
        /// 初始化输入处理
        /// </summary>
        private void InitializeInput()
        {
            // 注册键盘事件
            Window.TextInput += HandleTextInput;
        }

        /// <summary>
        /// 处理文本输入
        /// </summary>
        private void HandleTextInput(object? sender, TextInputEventArgs e)
        {
            // 处理控制台命令或其他文本输入
            // 简化实现：预留接口
        }

        /// <summary>
        /// 加载内容
        /// </summary>
        protected override void LoadContent()
        {
            try
            {
                Logger.Info("Loading game content...");
                
                // 创建SpriteBatch
                Logger.Debug("Creating SpriteBatch...");
                _spriteBatch = new SpriteBatch(GraphicsDevice);

                // 加载调试字体
                Logger.Debug("Loading debug font...");
                try
                {
                    _debugFont = Content.Load<SpriteFont>("DebugFont");
                    Logger.Info("Debug font loaded successfully");
                }
                catch (Exception ex)
                {
                    Logger.Warning($"Failed to load debug font: {ex.Message}");
                    Logger.Info("Will use default rendering for debug text");
                    _debugFont = null;
                }

                // 创建像素纹理用于绘制简单图形
                Logger.Debug("Creating pixel texture...");
                _pixelTexture = new Texture2D(GraphicsDevice, 1, 1);
                _pixelTexture.SetData(new[] { Color.White });
                
                Logger.Info("Game content loading completed successfully");
            }
            catch (Exception ex)
            {
                Logger.Fatal($"Failed to load game content: {ex.Message}", ex);
                throw;
            }
        }

        /// <summary>
        /// 初始化内容
        /// </summary>
        private void InitializeContent()
        {
            try
            {
                Logger.Debug("Initializing additional content...");
                
                // 加载纹理和着色器
                // 简化实现：预留内容加载接口
                
                Logger.Debug("Additional content initialization completed");
            }
            catch (Exception ex)
            {
                Logger.Error($"Failed to initialize additional content: {ex.Message}", ex);
            }
        }

        /// <summary>
        /// 更新游戏状态
        /// </summary>
        protected override void Update(GameTime gameTime)
        {
            try
            {
                // 开始帧计时
                _frameStopwatch.Restart();

                // 处理退出
                if (GamePad.GetState(PlayerIndex.One).Buttons.Back == Microsoft.Xna.Framework.Input.ButtonState.Pressed || 
                    Keyboard.GetState().IsKeyDown(Microsoft.Xna.Framework.Input.Keys.Escape))
                {
                    Logger.Info("Exit requested by user");
                    Exit();
                }

                // 处理调试模式切换
                HandleDebugMode();

            if (_isInitialized)
            {
                // 更新玩家
                _playerController.Update(gameTime);

                // 更新区块管理器
                Logger.Debug($"Updating chunk manager at player position {_playerController.Player.Position}");
                _chunkManager.Update(_playerController.Player.Position);

                // 更新相机
                UpdateCamera();
                
  
                // 更新渲染统计
                UpdateRenderStats();

              }

            // 处理特殊输入
            HandleSpecialInput();

            base.Update(gameTime);

            // 结束帧计时
            _frameStopwatch.Stop();
            _frameTime = _frameStopwatch.ElapsedMilliseconds;
            UpdateFPS(gameTime);
            
            }
            catch (Exception ex)
            {
                Logger.Error($"Error in game update: {ex.Message}", ex);
                // 不要抛出异常，让游戏继续运行
            }
        }

        /// <summary>
        /// 更新相机
        /// </summary>
        private void UpdateCamera()
        {
            var player = _playerController.Player;
            _renderManager.UpdateCamera(
                player.ViewMatrix,
                player.ProjectionMatrix,
                player.Position
            );
        }

        /// <summary>
        /// 更新渲染统计
        /// </summary>
        private void UpdateRenderStats()
        {
            var stats = _renderManager.GetStats();
            _renderStats.DrawCalls = stats.DrawCalls;
            _renderStats.Triangles = stats.Triangles;
            _renderStats.VisibleChunks = stats.VisibleChunks;
            _renderStats.FrameTime = _frameTime;
            _renderStats.FPS = _fps;

            _chunkStats = _chunkManager.GetStats();
        }

  
        /// <summary>
        /// 更新FPS
        /// </summary>
        private void UpdateFPS(GameTime gameTime)
        {
            _frameCount++;
            _fpsTimer += (float)gameTime.ElapsedGameTime.TotalSeconds;

            if (_fpsTimer >= 1.0f)
            {
                _fps = _frameCount;
                _frameCount = 0;
                _fpsTimer = 0f;
            }
        }

        /// <summary>
        /// 处理调试模式
        /// </summary>
        private void HandleDebugMode()
        {
            var keyboard = Keyboard.GetState();
            
            // F3切换调试模式
            if (keyboard.IsKeyDown(Microsoft.Xna.Framework.Input.Keys.F3) && !Keyboard.GetState().IsKeyDown(Microsoft.Xna.Framework.Input.Keys.F3))
            {
                _debugMode = !_debugMode;
            }
        }

        /// <summary>
        /// 处理特殊输入
        /// </summary>
        private void HandleSpecialInput()
        {
            var keyboard = Keyboard.GetState();
            var player = _playerController.Player;

            // F11切换全屏
            if (keyboard.IsKeyDown(Microsoft.Xna.Framework.Input.Keys.F11) && !Keyboard.GetState().IsKeyDown(Microsoft.Xna.Framework.Input.Keys.F11))
            {
                _graphics.IsFullScreen = !_graphics.IsFullScreen;
                _graphics.ApplyChanges();
            }

            // 调整渲染距离
            if (keyboard.IsKeyDown(Microsoft.Xna.Framework.Input.Keys.OemPlus))
            {
                _renderDistance = Math.Min(300f, _renderDistance + 5f);
                _renderManager.FrustumCulling.SetMaxRenderDistance(_renderDistance);
            }
            if (keyboard.IsKeyDown(Microsoft.Xna.Framework.Input.Keys.OemMinus))
            {
                _renderDistance = Math.Max(50f, _renderDistance - 5f);
                _renderManager.FrustumCulling.SetMaxRenderDistance(_renderDistance);
            }

            // 切换飞行模式
            if (keyboard.IsKeyDown(Microsoft.Xna.Framework.Input.Keys.F) && !Keyboard.GetState().IsKeyDown(Microsoft.Xna.Framework.Input.Keys.F))
            {
                _playerController.EnableFlying = !_playerController.EnableFlying;
            }

            // 重新生成世界
            if (keyboard.IsKeyDown(Microsoft.Xna.Framework.Input.Keys.R) && !Keyboard.GetState().IsKeyDown(Microsoft.Xna.Framework.Input.Keys.R))
            {
                RegenerateWorld();
            }

                }

        /// <summary>
        /// 重新生成世界
        /// </summary>
        private void RegenerateWorld()
        {
            // 保存玩家位置
            var playerPos = _playerController.Player.Position;

            // 重新创建区块管理器
            _chunkManager.Dispose();
            _chunkManager = new ChunkManager(GraphicsDevice, _blockRegistry, _worldSettings);

            // 恢复玩家位置
            _playerController.Player.SetPosition(playerPos);
        }

        /// <summary>
        /// 绘制游戏
        /// </summary>
        protected override void Draw(GameTime gameTime)
        {
            try
            {
                // 清空屏幕 - 使用天空蓝色
                GraphicsDevice.Clear(new Color(135, 206, 235)); // 天空蓝

                if (_isInitialized)
                {
                    // 渲染3D场景
                    Render3DScene();

                    // 渲染UI
                    RenderUI();
                }

                base.Draw(gameTime);
            }
            catch (Exception ex)
            {
                Logger.Error($"Error in game draw: {ex.Message}", ex);
                // 尝试继续渲染，即使出错
                try
                {
                    GraphicsDevice.Clear(Color.Red);
                    base.Draw(gameTime);
                }
                catch
                {
                    // 如果连基本渲染都失败，就忽略
                }
            }
        }

        /// <summary>
        /// 渲染3D场景
        /// </summary>
        private void Render3DScene()
        {
            // 获取可见区块
            var visibleChunks = _chunkManager.GetVisibleChunks(_renderManager.FrustumCulling);
            
            // 添加调试信息
            if (visibleChunks.Count == 0)
            {
                Logger.Debug("No visible chunks found for rendering");
            }
            else
            {
                Logger.Debug($"Rendering {visibleChunks.Count} visible chunks");
            }

            // 渲染区块
            _renderManager.RenderChunks(visibleChunks);
        }

        /// <summary>
        /// 渲染UI
        /// </summary>
        private void RenderUI()
        {
            if (_spriteBatch == null) return;
            
            _spriteBatch.Begin();

            // 绘制调试信息
            if (_debugMode && _debugFont != null)
            {
                RenderDebugInfo();
            }

            // 渲染十字准心
            RenderCrosshair();

            _spriteBatch.End();
        }

        /// <summary>
        /// 渲染调试信息
        /// </summary>
        private void RenderDebugInfo()
        {
                  
            // 获取玩家所在区块的信息用于调试
            var playerChunkPos = ChunkPosition.FromWorldPosition(_playerController.Player.Position, Chunk.SIZE);
            var playerChunk = _chunkManager.GetChunk(playerChunkPos);
            var playerBlock = _chunkManager.GetBlock(_playerController.Player.Position);
            
            var debugLines = new List<string>
            {
                $"MCGame Debug Mode",
                $"FPS: {_fps}",
                $"Frame Time: {_frameTime:F2}ms",
                $"",
                $"Player Position: {_playerController.Player.Position}",
                $"Player Chunk: {playerChunkPos}",
                $"Player Block: {playerBlock.Type}",
                $"Player Yaw: {_playerController.Player.Yaw:F2}",
                $"Player Pitch: {_playerController.Player.Pitch:F2}",
                $"",
                $"Player Chunk Loaded: {playerChunk?.IsLoaded ?? false}",
                $"Player Chunk Meshed: {playerChunk?.IsMeshGenerated ?? false}",
                $"Player Chunk State: {playerChunk?.State}",
                $"",
                $"Render Distance: {_renderDistance:F0}",
                $"Draw Calls: {_renderStats.DrawCalls}",
                $"Triangles: {_renderStats.Triangles}",
                $"Visible Chunks: {_renderStats.VisibleChunks}",
                $"",
                $"Loaded Chunks: {_chunkStats.LoadedChunks}",
                $"Queued Generation: {_chunkStats.QueuedGeneration}",
                $"Queued Meshing: {_chunkStats.QueuedMeshing}",
                $"Chunks Generated: {_chunkStats.ChunksGeneratedThisFrame}",
                $"Chunks Meshed: {_chunkStats.ChunksMeshedThisFrame}",
                $"Pool Size: {_chunkStats.PoolSize}",
                $"",
                $"Flying Mode: {_playerController.EnableFlying}",
                $"Mouse Locked: {_playerController.Player.IsMouseButtonDown(MouseButton.Right)}"
            };

            var y = 10;
            foreach (var line in debugLines)
            {
                _spriteBatch.DrawString(_debugFont, line, new Vector2(10, y), Color.White);
                y += 20;
            }
        }

        /// <summary>
        /// 渲染十字准心
        /// </summary>
        private void RenderCrosshair()
        {
            // 十字准心应该在SpriteBatch.Begin()之后调用，不在这里调用Begin/End
            var centerX = GraphicsDevice.Viewport.Width / 2;
            var centerY = GraphicsDevice.Viewport.Height / 2;

            // 绘制十字准心
            if (_debugFont != null)
            {
                _spriteBatch.DrawString(_debugFont, "+", 
                    new Vector2(centerX - 5, centerY - 10), Color.White);
            }
            else
            {
                // 如果没有字体，使用简单的线条绘制十字准心
                var lineThickness = 2;
                var lineLength = 10;
                
                // 水平线
                _spriteBatch.Draw(_pixelTexture, new Rectangle(centerX - lineLength, centerY - lineThickness/2, lineLength * 2, lineThickness), Color.White);
                // 垂直线
                _spriteBatch.Draw(_pixelTexture, new Rectangle(centerX - lineThickness/2, centerY - lineLength, lineThickness, lineLength * 2), Color.White);
            }
        }

        /// <summary>
        /// 释放资源
        /// </summary>
        protected override void UnloadContent()
        {
            // 释放资源
            _chunkManager?.Dispose();
            _renderManager?.Dispose();
            _spriteBatch?.Dispose();
            _pixelTexture?.Dispose();
            
                    
            base.UnloadContent();
        }

        /// <summary>
        /// 获取游戏统计信息
        /// </summary>
        public GameStats GetGameStats()
        {
            return new GameStats
            {
                FPS = _fps,
                FrameTime = _frameTime,
                IsInitialized = _isInitialized,
                LoadedChunks = _chunkStats.LoadedChunks,
                VisibleChunks = _renderStats.VisibleChunks,
                DrawCalls = _renderStats.DrawCalls,
                Triangles = _renderStats.Triangles,
                RenderDistance = _renderDistance,
                DebugMode = _debugMode
            };
        }
    }

    /// <summary>
    /// 游戏统计信息
    /// </summary>
    public struct GameStats
    {
        public int FPS { get; set; }
        public float FrameTime { get; set; }
        public bool IsInitialized { get; set; }
        public int LoadedChunks { get; set; }
        public int VisibleChunks { get; set; }
        public int DrawCalls { get; set; }
        public int Triangles { get; set; }
        public float RenderDistance { get; set; }
        public bool DebugMode { get; set; }
    }

    /// <summary>
    /// 游戏入口点
    /// </summary>
    public static class Program
    {
        /// <summary>
        /// 应用程序入口点
        /// </summary>
        [STAThread]
        static void Main(string[] args)
        {
            try
            {
                // 初始化日志系统
                Logger.Initialize();
                Logger.Info("=== MCGame Starting ===");
                Logger.Info($"Platform: {Environment.OSVersion}");
                Logger.Info($"Working Directory: {Environment.CurrentDirectory}");
                Logger.Info($"Base Directory: {AppContext.BaseDirectory}");
                
                // 记录系统信息
                LogSystemInfo();
                
                // 配置环境变量
                EnvironmentConfig.ConfigureMonoGameEnvironment();
                
                // 检查命令行参数
                var headlessMode = args.Contains("--headless") || args.Contains("-h");
                var forceSoftwareRendering = args.Contains("--software") || args.Contains("-s");
                
                if (headlessMode)
                {
                    Logger.Info("Starting in headless mode...");
                    RunHeadlessMode();
                    return;
                }
                
                if (forceSoftwareRendering)
                {
                    Logger.Info("Forcing software rendering...");
                    Environment.SetEnvironmentVariable("LIBGL_ALWAYS_SOFTWARE", "1");
                }
                
                // 尝试正常启动游戏
                try
                {
                    using (var game = new MCGame())
                    {
                        Logger.Info("Starting game loop...");
                        game.Run();
                    }
                }
                catch (NoSuitableGraphicsDeviceException graphicsEx)
                {
                    Logger.Fatal($"Graphics device creation failed: {graphicsEx.Message}");
                    Logger.Info("Attempting to start in headless mode as fallback...");
                    
                    // 自动切换到无头模式
                    RunHeadlessMode();
                }
                
                Logger.Info("=== MCGame Exiting Normally ===");
            }
            catch (Exception ex)
            {
                // 确保在异常情况下也能记录日志
                try
                {
                    Logger.Fatal($"Application crashed: {ex.Message}", ex);
                    
                    // 如果日志初始化失败，使用Console输出
                    Console.WriteLine($"=== FATAL ERROR ===");
                    Console.WriteLine($"Message: {ex.Message}");
                    Console.WriteLine($"Type: {ex.GetType().Name}");
                    Console.WriteLine($"Stack Trace: {ex.StackTrace}");
                    
                    if (ex.InnerException != null)
                    {
                        Console.WriteLine($"Inner Exception: {ex.InnerException.Message}");
                    }
                    
                    Console.WriteLine("=== END ERROR ===");
                    Console.WriteLine("Press any key to exit...");
                    Console.ReadKey();
                }
                catch
                {
                    // 如果连Console都无法使用，就无法显示错误了
                    // 在Linux环境中，System.Windows.Forms不可用
                }
                
                Environment.Exit(1);
            }
        }

        /// <summary>
        /// 运行无头模式
        /// </summary>
        private static void RunHeadlessMode()
        {
            Logger.Info("Starting MCGame in headless mode...");
            
            try
            {
                // 创建无头模式启动器
                var headlessLauncher = new HeadlessGameLauncher(null);
                headlessLauncher.StartHeadlessMode();
                
                // 等待用户输入以退出
                Logger.Info("Headless mode running. Press Ctrl+C to exit.");
                
                // 使用Console.ReadLine来保持程序运行
                Console.ReadLine();
                
                // 停止无头模式
                headlessLauncher.StopHeadlessMode();
            }
            catch (Exception ex)
            {
                Logger.Fatal($"Failed to run headless mode: {ex.Message}", ex);
            }
        }

        private static void LogSystemInfo()
        {
            try
            {
                Logger.Info($"System Information:");
                Logger.Info($"  OS Version: {Environment.OSVersion}");
                Logger.Info($"  Processor Count: {Environment.ProcessorCount}");
                Logger.Info($"  Working Set: {Environment.WorkingSet / 1024 / 1024} MB");
                Logger.Info($"  Is 64-bit Process: {Environment.Is64BitProcess}");
                
                // 检查MonoGame相关
                var assemblies = AppDomain.CurrentDomain.GetAssemblies();
                var monogameAssemblies = assemblies.Where(a => a.FullName?.Contains("MonoGame") ?? false);
                foreach (var asm in monogameAssemblies)
                {
                    Logger.Info($"  MonoGame Assembly: {asm.FullName}");
                }
                
                // 检查ECS相关
                var ecsAssemblies = assemblies.Where(a => a.FullName?.Contains("Friflo") ?? false);
                foreach (var asm in ecsAssemblies)
                {
                    Logger.Info($"  ECS Assembly: {asm.FullName}");
                }
            }
            catch (Exception ex)
            {
                Logger.Warning($"Failed to log system info: {ex.Message}");
            }
        }
    }
}
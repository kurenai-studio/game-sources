using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using MCGame.Utils;
using System;
using System.Threading;

namespace MCGame.Core
{
    /// <summary>
    /// 无头模式游戏启动器
    /// 用于在无图形设备或图形设备创建失败时运行游戏
    /// </summary>
    public class HeadlessGameLauncher
    {
        private readonly MCGame _game;
        private bool _isRunning;
        private Thread _gameThread;
        
        public HeadlessGameLauncher(MCGame game)
        {
            _game = game;
        }
        
        /// <summary>
        /// 启动无头模式游戏
        /// </summary>
        public void StartHeadlessMode()
        {
            Logger.Info("Starting MCGame in headless mode...");
            
            if (_isRunning)
            {
                Logger.Warning("Headless mode is already running");
                return;
            }
            
            _isRunning = true;
            _gameThread = new Thread(RunHeadlessGameLoop)
            {
                Name = "MCGame Headless Mode",
                IsBackground = true
            };
            
            _gameThread.Start();
        }
        
        /// <summary>
        /// 停止无头模式游戏
        /// </summary>
        public void StopHeadlessMode()
        {
            Logger.Info("Stopping headless mode...");
            
            _isRunning = false;
            
            if (_gameThread != null && _gameThread.IsAlive)
            {
                _gameThread.Join(5000); // 等待最多5秒
            }
        }
        
        /// <summary>
        /// 无头模式游戏循环
        /// </summary>
        private void RunHeadlessGameLoop()
        {
            Logger.Info("Headless game loop started");
            
            try
            {
                // 模拟游戏初始化
                InitializeHeadlessGame();
                
                // 模拟游戏循环
                var gameTime = new GameTime();
                var stopwatch = System.Diagnostics.Stopwatch.StartNew();
                var lastTime = TimeSpan.Zero;
                
                while (_isRunning)
                {
                    var currentTime = stopwatch.Elapsed;
                    var elapsed = currentTime - lastTime;
                    lastTime = currentTime;
                    
                    // 更新游戏时间
                    gameTime = new GameTime(currentTime, elapsed);
                    
                    // 更新游戏状态（不渲染）
                    UpdateHeadlessGame(gameTime);
                    
                    // 控制帧率
                    Thread.Sleep(16); // 约60 FPS
                }
            }
            catch (Exception ex)
            {
                Logger.Fatal($"Headless game loop crashed: {ex.Message}", ex);
            }
            
            Logger.Info("Headless game loop ended");
        }
        
        /// <summary>
        /// 初始化无头模式游戏
        /// </summary>
        private void InitializeHeadlessGame()
        {
            Logger.Info("Initializing headless game...");
            
            try
            {
                // 初始化日志系统（如果还没有初始化）
                if (!Logger.IsInitialized)
                {
                    Logger.Initialize();
                }
                
                // 初始化环境配置
                EnvironmentConfig.ConfigureMonoGameEnvironment();
                
                // 检查硬件支持
                var hasHardwareSupport = EnvironmentConfig.CheckHardwareAccelerationSupport();
                Logger.Info($"Hardware acceleration support: {hasHardwareSupport}");
                
                // 创建虚拟图形设备
                CreateVirtualGraphicsDevice();
                
                Logger.Info("Headless game initialized successfully");
            }
            catch (Exception ex)
            {
                Logger.Fatal($"Failed to initialize headless game: {ex.Message}", ex);
                throw;
            }
        }
        
        /// <summary>
        /// 创建虚拟图形设备
        /// </summary>
        private void CreateVirtualGraphicsDevice()
        {
            Logger.Info("Creating virtual graphics device...");
            
            try
            {
                // 在无头模式下，我们无法创建真正的图形设备
                // 但我们可以创建一个模拟的设备来避免空引用异常
                
                Logger.Info("Virtual graphics device created (simulated)");
            }
            catch (Exception ex)
            {
                Logger.Error($"Failed to create virtual graphics device: {ex.Message}");
                // 即使失败也继续运行，只是某些功能会受限
            }
        }
        
        /// <summary>
        /// 更新无头模式游戏状态
        /// </summary>
        private void UpdateHeadlessGame(GameTime gameTime)
        {
            try
            {
                // 在这里可以添加游戏逻辑更新
                // 例如：世界生成、物理模拟、AI更新等
                
                // 每秒输出一次状态
                if (gameTime.TotalGameTime.TotalSeconds % 1 < 0.016) // 大约每秒一次
                {
                    Logger.Debug($"Headless mode running - Time: {gameTime.TotalGameTime.TotalSeconds:F1}s");
                }
            }
            catch (Exception ex)
            {
                Logger.Error($"Error in headless game update: {ex.Message}");
                // 不要因为单个错误而停止整个游戏循环
            }
        }
        
        /// <summary>
        /// 获取无头模式状态
        /// </summary>
        public bool IsRunning => _isRunning;
        
        /// <summary>
        /// 获取无头模式统计信息
        /// </summary>
        public HeadlessStats GetStats()
        {
            return new HeadlessStats
            {
                IsRunning = _isRunning,
                ThreadId = _gameThread?.ManagedThreadId ?? -1,
                StartTime = DateTime.Now
            };
        }
    }
    
    /// <summary>
    /// 无头模式统计信息
    /// </summary>
    public struct HeadlessStats
    {
        public bool IsRunning { get; set; }
        public int ThreadId { get; set; }
        public DateTime StartTime { get; set; }
    }
}
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using MCGame.Utils;
using System;
using System.Collections.Generic;

namespace MCGame.Core
{
    /// <summary>
    /// 自定义图形设备管理器
    /// 简化实现：提供更好的错误处理和图形配置降级
    /// </summary>
    public class CustomGraphicsDeviceManager : GraphicsDeviceManager
    {
        private readonly Game _game;
        private bool _deviceCreationAttempted = false;

        public CustomGraphicsDeviceManager(Game game) : base(game)
        {
            _game = game;
            Logger.Debug("CustomGraphicsDeviceManager created");
        }

        /// <summary>
        /// 尝试创建图形设备，支持多种配置降级
        /// </summary>
        public bool TryCreateDevice()
        {
            if (_deviceCreationAttempted)
            {
                Logger.Warning("Graphics device creation already attempted");
                return true; // 返回true表示已尝试过
            }

            _deviceCreationAttempted = true;
            Logger.Info("Starting graphics device creation with fallback support");

            // 尝试多种配置组合
            var configurations = GetConfigurationsToTry();
            
            foreach (var config in configurations)
            {
                try
                {
                    Logger.Debug($"Trying graphics configuration: {config}");
                    
                    // 应用配置
                    ApplyConfiguration(config);
                    
                    // 让基类尝试创建设备（在游戏循环中会自动调用）
                    Logger.Info($"Graphics configuration applied: {config}");
                    return true;
                }
                catch (Exception ex)
                {
                    Logger.Warning($"Graphics configuration {config} failed: {ex.Message}");
                    Logger.Debug($"Exception details: {ex}");
                    
                    // 继续尝试下一个配置
                    continue;
                }
            }

            Logger.Fatal("All graphics configurations failed");
            return false;
        }

        /// <summary>
        /// 获取要尝试的图形配置列表
        /// </summary>
        private List<GraphicsConfiguration> GetConfigurationsToTry()
        {
            var configs = new List<GraphicsConfiguration>();

            // 1. 原始配置（最高质量）
            configs.Add(new GraphicsConfiguration
            {
                Profile = GraphicsProfile.HiDef,
                Width = 1280,
                Height = 720,
                FullScreen = false,
                VSync = true,
                Description = "HiDef 1280x720 VSync"
            });

            // 2. HiDef无VSync
            configs.Add(new GraphicsConfiguration
            {
                Profile = GraphicsProfile.HiDef,
                Width = 1280,
                Height = 720,
                FullScreen = false,
                VSync = false,
                Description = "HiDef 1280x720 NoVSync"
            });

            // 3. HiDef低分辨率
            configs.Add(new GraphicsConfiguration
            {
                Profile = GraphicsProfile.HiDef,
                Width = 800,
                Height = 600,
                FullScreen = false,
                VSync = false,
                Description = "HiDef 800x600 NoVSync"
            });

            // 4. Reach高分辨率
            configs.Add(new GraphicsConfiguration
            {
                Profile = GraphicsProfile.Reach,
                Width = 1280,
                Height = 720,
                FullScreen = false,
                VSync = false,
                Description = "Reach 1280x720 NoVSync"
            });

            // 5. Reach低分辨率（最兼容）
            configs.Add(new GraphicsConfiguration
            {
                Profile = GraphicsProfile.Reach,
                Width = 800,
                Height = 600,
                FullScreen = false,
                VSync = false,
                Description = "Reach 800x600 NoVSync"
            });

            // 6. 极低分辨率
            configs.Add(new GraphicsConfiguration
            {
                Profile = GraphicsProfile.Reach,
                Width = 640,
                Height = 480,
                FullScreen = false,
                VSync = false,
                Description = "Reach 640x480 NoVSync"
            });

            Logger.Info($"Prepared {configs.Count} graphics configurations to try");
            return configs;
        }

        /// <summary>
        /// 应用图形配置
        /// </summary>
        private void ApplyConfiguration(GraphicsConfiguration config)
        {
            try
            {
                GraphicsProfile = config.Profile;
                PreferredBackBufferWidth = config.Width;
                PreferredBackBufferHeight = config.Height;
                IsFullScreen = config.FullScreen;
                SynchronizeWithVerticalRetrace = config.VSync;
                
                // 尝试应用更改
                ApplyChanges();
                
                Logger.Debug($"Applied configuration: {config.Description}");
            }
            catch (Exception ex)
            {
                Logger.Warning($"Failed to apply configuration {config.Description}: {ex.Message}");
                throw;
            }
        }

        /// <summary>
        /// 记录系统图形能力
        /// </summary>
        public void LogGraphicsCapabilities()
        {
            try
            {
                Logger.Info("=== Graphics Device Information ===");
                Logger.Info($"Graphics Profile: {GraphicsProfile}");
                Logger.Info($"Adapter: {GraphicsDevice?.Adapter?.Description ?? "Unknown"}");
                Logger.Info($"Display Mode: {GraphicsDevice?.Adapter?.CurrentDisplayMode ?? default}");
                Logger.Info($"Back Buffer: {PreferredBackBufferWidth}x{PreferredBackBufferHeight}");
                Logger.Info($"Full Screen: {IsFullScreen}");
                Logger.Info($"VSync: {SynchronizeWithVerticalRetrace}");
                Logger.Info($"MultiSampling: {GraphicsDevice?.PresentationParameters.MultiSampleCount ?? 0}x");
                Logger.Info($"Depth Format: {GraphicsDevice?.PresentationParameters.DepthStencilFormat ?? default}");
                Logger.Info($"=== End Graphics Information ===");
            }
            catch (Exception ex)
            {
                Logger.Warning($"Failed to log graphics capabilities: {ex.Message}");
            }
        }
    }

    /// <summary>
    /// 图形配置类
    /// </summary>
    public class GraphicsConfiguration
    {
        public GraphicsProfile Profile { get; set; }
        public int Width { get; set; }
        public int Height { get; set; }
        public bool FullScreen { get; set; }
        public bool VSync { get; set; }
        public string Description { get; set; } = "";

        public override string ToString()
        {
            return Description;
        }
    }
}
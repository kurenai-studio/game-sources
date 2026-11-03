using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.InteropServices;

namespace MCGame.Utils
{
    /// <summary>
    /// 环境配置管理器
    /// 用于设置MonoGame相关的环境变量和配置
    /// </summary>
    public static class EnvironmentConfig
    {
        /// <summary>
        /// 配置MonoGame环境变量
        /// </summary>
        public static void ConfigureMonoGameEnvironment()
        {
            Logger.Info("Configuring MonoGame environment variables...");
            
            // 设置MonoGame环境变量
            SetEnvironmentVariable("MONOGAME_FORCE_DESKTOP_GL", "1");
            SetEnvironmentVariable("MONOGAME_FORCE_OPENGL", "1");
            SetEnvironmentVariable("MONOGAME_DEBUG_MODE", "1");
            
            // 在Linux上可能需要的环境变量
            if (RuntimeInformation.IsOSPlatform(OSPlatform.Linux))
            {
                SetEnvironmentVariable("DISPLAY", ":0");
                SetEnvironmentVariable("LIBGL_ALWAYS_SOFTWARE", "1"); // 强制软件渲染
            }
            
            // 在Windows上的环境变量
            if (RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
            {
                SetEnvironmentVariable("MONOGAME_PLATFORM", "DesktopGL");
                SetEnvironmentVariable("MONOGAME_BACKEND", "OpenGL");
            }
            
            LogEnvironmentVariables();
        }
        
        /// <summary>
        /// 设置环境变量
        /// </summary>
        private static void SetEnvironmentVariable(string name, string value)
        {
            try
            {
                Environment.SetEnvironmentVariable(name, value);
                Logger.Debug($"Set environment variable: {name}={value}");
            }
            catch (Exception ex)
            {
                Logger.Warning($"Failed to set environment variable {name}: {ex.Message}");
            }
        }
        
        /// <summary>
        /// 记录当前环境变量
        /// </summary>
        private static void LogEnvironmentVariables()
        {
            Logger.Info("=== Environment Variables ===");
            
            var variables = new[]
            {
                "MONOGAME_FORCE_DESKTOP_GL",
                "MONOGAME_FORCE_OPENGL",
                "MONOGAME_DEBUG_MODE",
                "MONOGAME_PLATFORM",
                "MONOGAME_BACKEND",
                "DISPLAY",
                "LIBGL_ALWAYS_SOFTWARE"
            };
            
            foreach (var variable in variables)
            {
                var value = Environment.GetEnvironmentVariable(variable);
                Logger.Info($"{variable}={value ?? "(not set)"}");
            }
            
            Logger.Info("=== End Environment Variables ===");
        }
        
        /// <summary>
        /// 检查是否支持硬件加速
        /// </summary>
        public static bool CheckHardwareAccelerationSupport()
        {
            Logger.Info("Checking hardware acceleration support...");
            
            // 检查是否在虚拟环境中
            if (IsRunningInVirtualMachine())
            {
                Logger.Warning("Running in virtual machine, hardware acceleration may be limited");
                return false;
            }
            
            // 检查是否有显示设备
            if (!HasDisplayDevice())
            {
                Logger.Warning("No display device detected");
                return false;
            }
            
            Logger.Info("Hardware acceleration support check completed");
            return true;
        }
        
        /// <summary>
        /// 检查是否在虚拟机中运行
        /// </summary>
        private static bool IsRunningInVirtualMachine()
        {
            try
            {
                // 检查常见的虚拟机指示器
                var indicators = new[]
                {
                    "/proc/vz",
                    "/proc/bc",
                    "/proc/xen",
                    "/sys/bus/pci/devices/0000:00:0f.0",
                    "/sys/class/dmi/id/product_name",
                    "/sys/class/dmi/id/board_vendor"
                };
                
                foreach (var indicator in indicators)
                {
                    if (System.IO.File.Exists(indicator))
                    {
                        Logger.Debug($"Virtual machine indicator found: {indicator}");
                        return true;
                    }
                }
                
                return false;
            }
            catch (Exception ex)
            {
                Logger.Warning($"Failed to check virtual machine status: {ex.Message}");
                return false;
            }
        }
        
        /// <summary>
        /// 检查是否有显示设备
        /// </summary>
        private static bool HasDisplayDevice()
        {
            try
            {
                // 在Linux上检查X11显示
                if (RuntimeInformation.IsOSPlatform(OSPlatform.Linux))
                {
                    var display = Environment.GetEnvironmentVariable("DISPLAY");
                    if (string.IsNullOrEmpty(display))
                    {
                        Logger.Warning("DISPLAY environment variable not set");
                        return false;
                    }
                    
                    // 尝试连接到X11服务器
                    return CanConnectToX11Server();
                }
                
                return true;
            }
            catch (Exception ex)
            {
                Logger.Warning($"Failed to check display device: {ex.Message}");
                return false;
            }
        }
        
        /// <summary>
        /// 尝试连接到X11服务器
        /// </summary>
        private static bool CanConnectToX11Server()
        {
            try
            {
                var display = Environment.GetEnvironmentVariable("DISPLAY");
                if (string.IsNullOrEmpty(display)) return false;
                
                // 尝试使用xdpyinfo检查X11服务器
                var process = new System.Diagnostics.Process
                {
                    StartInfo = new System.Diagnostics.ProcessStartInfo
                    {
                        FileName = "xdpyinfo",
                        Arguments = "-display " + display,
                        RedirectStandardOutput = true,
                        RedirectStandardError = true,
                        UseShellExecute = false,
                        CreateNoWindow = true
                    }
                };
                
                process.Start();
                process.WaitForExit();
                
                var success = process.ExitCode == 0;
                Logger.Debug($"X11 server connection test: {(success ? "Success" : "Failed")}");
                return success;
            }
            catch (Exception ex)
            {
                Logger.Debug($"X11 server connection test failed: {ex.Message}");
                return false;
            }
        }
    }
}
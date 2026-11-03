using System;
using System.IO;
using System.Text.Json;

namespace MCGame.Utils
{
    /// <summary>
    /// 日志配置类
    /// </summary>
    public class LogConfig
    {
        public LoggingConfig Logging { get; set; } = new LoggingConfig();
        public CrashReportingConfig CrashReporting { get; set; } = new CrashReportingConfig();
        public PerformanceConfig Performance { get; set; } = new PerformanceConfig();
    }

    /// <summary>
    /// 日志配置
    /// </summary>
    public class LoggingConfig
    {
        public LogLevelConfig LogLevel { get; set; } = new LogLevelConfig();
        public ConsoleConfig Console { get; set; } = new ConsoleConfig();
        public FileConfig File { get; set; } = new FileConfig();
        public DebugConfig Debug { get; set; } = new DebugConfig();
    }

    /// <summary>
    /// 日志级别配置
    /// </summary>
    public class LogLevelConfig
    {
        public string Default { get; set; } = "Information";
        public string MCGame { get; set; } = "Debug";
        public string MCGame_Core { get; set; } = "Information";
        public string MCGame_Rendering { get; set; } = "Information";
        public string MCGame_ECS { get; set; } = "Debug";
        public string MCGame_Utils { get; set; } = "Information";
    }

    /// <summary>
    /// 控制台配置
    /// </summary>
    public class ConsoleConfig
    {
        public bool Enabled { get; set; } = true;
        public string LogLevel { get; set; } = "Information";
        public bool IncludeTimestamps { get; set; } = true;
        public bool IncludeLogLevel { get; set; } = true;
        public bool IncludeCategory { get; set; } = true;
        public bool ColorOutput { get; set; } = true;
    }

    /// <summary>
    /// 文件配置
    /// </summary>
    public class FileConfig
    {
        public bool Enabled { get; set; } = true;
        public string LogLevel { get; set; } = "Debug";
        public string Path { get; set; } = "logs";
        public string FileName { get; set; } = "mcgame_{date}_{time}.log";
        public string MaxFileSize { get; set; } = "10MB";
        public int MaxRetainedFiles { get; set; } = 5;
        public bool IncludeTimestamps { get; set; } = true;
        public bool IncludeLogLevel { get; set; } = true;
        public bool IncludeCategory { get; set; } = true;
        public string FlushInterval { get; set; } = "1s";
    }

    /// <summary>
    /// 调试配置
    /// </summary>
    public class DebugConfig
    {
        public bool Enabled { get; set; } = true;
        public bool LogToFile { get; set; } = true;
        public bool LogToConsole { get; set; } = true;
        public bool LogExceptions { get; set; } = true;
        public bool LogFrameTimes { get; set; } = false;
        public bool LogMemoryUsage { get; set; } = false;
        public bool LogRenderStats { get; set; } = false;
    }

    /// <summary>
    /// 崩溃报告配置
    /// </summary>
    public class CrashReportingConfig
    {
        public bool Enabled { get; set; } = true;
        public bool CreateDumpFiles { get; set; } = false;
        public bool ShowErrorDialog { get; set; } = true;
        public bool LogSystemInfo { get; set; } = true;
        public bool LogStackTrace { get; set; } = true;
        public bool LogInnerExceptions { get; set; } = true;
    }

    /// <summary>
    /// 性能配置
    /// </summary>
    public class PerformanceConfig
    {
        public bool LogSlowOperations { get; set; } = true;
        public string SlowOperationThreshold { get; set; } = "16ms";
        public bool LogFrameTimeWarnings { get; set; } = true;
        public string FrameTimeWarningThreshold { get; set; } = "33ms";
        public bool LogMemoryWarnings { get; set; } = true;
        public string MemoryWarningThreshold { get; set; } = "1GB";
    }

    /// <summary>
    /// 日志配置管理器
    /// </summary>
    public static class LogConfigManager
    {
        private static LogConfig _config;
        private static readonly string _configPath = "logging.json";

        public static LogConfig Config
        {
            get
            {
                if (_config == null)
                {
                    _config = LoadConfig();
                }
                return _config;
            }
        }

        public static LogConfig LoadConfig()
        {
            try
            {
                if (File.Exists(_configPath))
                {
                    var json = File.ReadAllText(_configPath);
                    var config = JsonSerializer.Deserialize<LogConfig>(json);
                    Console.WriteLine($"Loaded logging configuration from {_configPath}");
                    return config ?? new LogConfig();
                }
                else
                {
                    Console.WriteLine("No logging configuration found, using defaults");
                    return new LogConfig();
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Failed to load logging configuration: {ex.Message}");
                return new LogConfig();
            }
        }

        public static void SaveConfig(LogConfig config)
        {
            try
            {
                var options = new JsonSerializerOptions
                {
                    WriteIndented = true,
                    PropertyNamingPolicy = JsonNamingPolicy.CamelCase
                };
                
                var json = JsonSerializer.Serialize(config, options);
                File.WriteAllText(_configPath, json);
                Console.WriteLine($"Saved logging configuration to {_configPath}");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Failed to save logging configuration: {ex.Message}");
            }
        }

        public static LogLevel ParseLogLevel(string levelString)
        {
            return Enum.TryParse<LogLevel>(levelString, true, out var level) 
                ? level 
                : LogLevel.Info;
        }

        public static long ParseSize(string sizeString)
        {
            if (string.IsNullOrEmpty(sizeString)) return 0;

            sizeString = sizeString.Trim().ToUpperInvariant();
            
            if (sizeString.EndsWith("KB")) return long.Parse(sizeString.Substring(0, sizeString.Length - 2)) * 1024;
            if (sizeString.EndsWith("MB")) return long.Parse(sizeString.Substring(0, sizeString.Length - 2)) * 1024 * 1024;
            if (sizeString.EndsWith("GB")) return long.Parse(sizeString.Substring(0, sizeString.Length - 2)) * 1024 * 1024 * 1024;
            
            return long.Parse(sizeString);
        }

        public static TimeSpan ParseTimeSpan(string timeString)
        {
            if (string.IsNullOrEmpty(timeString)) return TimeSpan.Zero;

            timeString = timeString.Trim().ToUpperInvariant();
            
            if (timeString.EndsWith("MS")) return TimeSpan.FromMilliseconds(double.Parse(timeString.Substring(0, timeString.Length - 2)));
            if (timeString.EndsWith("S")) return TimeSpan.FromSeconds(double.Parse(timeString.Substring(0, timeString.Length - 1)));
            if (timeString.EndsWith("M")) return TimeSpan.FromMinutes(double.Parse(timeString.Substring(0, timeString.Length - 1)));
            if (timeString.EndsWith("H")) return TimeSpan.FromHours(double.Parse(timeString.Substring(0, timeString.Length - 1)));
            
            return TimeSpan.FromMilliseconds(double.Parse(timeString));
        }
    }
}
using System;
using System.IO;
using System.Threading;
using Serilog;

namespace MCGame.Utils
{
    /// <summary>
    /// 日志级别枚举
    /// </summary>
    public enum LogLevel
    {
        Debug = 0,
        Info = 1,
        Warning = 2,
        Error = 3,
        Fatal = 4
    }

    /// <summary>
    /// 日志系统接口
    /// </summary>
    public interface ILogger
    {
        void Log(LogLevel level, string message, Exception exception = null);
        void Debug(string message);
        void Info(string message);
        void Warning(string message);
        void Error(string message, Exception exception = null);
        void Fatal(string message, Exception exception = null);
    }

    /// <summary>
    /// 日志系统基类
    /// </summary>
    public abstract class BaseLogger : ILogger
    {
        public LogLevel MinLevel { get; set; } = LogLevel.Debug;

        public virtual void Log(LogLevel level, string message, Exception exception = null)
        {
            if (level < MinLevel) return;

            var timestamp = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss.fff");
            var logMessage = $"[{timestamp}] [{level}] {message}";

            if (exception != null)
            {
                logMessage += $"\nException: {exception.GetType().Name}: {exception.Message}";
                logMessage += $"\nStack Trace: {exception.StackTrace}";
            }

            WriteLog(logMessage);
        }

        public virtual void Debug(string message) => Log(LogLevel.Debug, message);
        public virtual void Info(string message) => Log(LogLevel.Info, message);
        public virtual void Warning(string message) => Log(LogLevel.Warning, message);
        public virtual void Error(string message, Exception exception = null) => Log(LogLevel.Error, message, exception);
        public virtual void Fatal(string message, Exception exception = null) => Log(LogLevel.Fatal, message, exception);

        protected abstract void WriteLog(string message);
    }

    /// <summary>
    /// 控制台日志记录器
    /// </summary>
    public class ConsoleLogger : BaseLogger
    {
        protected override void WriteLog(string message)
        {
            Console.WriteLine(message);
        }
    }

    /// <summary>
    /// 文件日志记录器
    /// </summary>
    public class FileLogger : BaseLogger
    {
        private readonly string _logFilePath;
        private readonly object _lock = new object();

        public FileLogger(string logFilePath)
        {
            _logFilePath = logFilePath;
            EnsureLogDirectoryExists();
        }

        protected override void WriteLog(string message)
        {
            lock (_lock)
            {
                try
                {
                    File.AppendAllText(_logFilePath, message + Environment.NewLine);
                }
                catch (Exception ex)
                {
                    // 如果文件写入失败，回退到控制台输出
                    Console.WriteLine($"Failed to write to log file: {ex.Message}");
                    Console.WriteLine($"Original message: {message}");
                }
            }
        }

        private void EnsureLogDirectoryExists()
        {
            try
            {
                var directory = Path.GetDirectoryName(_logFilePath);
                if (!string.IsNullOrEmpty(directory) && !Directory.Exists(directory))
                {
                    Directory.CreateDirectory(directory);
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Failed to create log directory: {ex.Message}");
            }
        }
    }

    /// <summary>
    /// 组合日志记录器（可以同时输出到多个目标）
    /// </summary>
    public class CompositeLogger : ILogger
    {
        private readonly ILogger[] _loggers;

        public CompositeLogger(params ILogger[] loggers)
        {
            _loggers = loggers ?? Array.Empty<ILogger>();
        }

        public void Log(LogLevel level, string message, Exception exception = null)
        {
            foreach (var logger in _loggers)
            {
                try
                {
                    logger.Log(level, message, exception);
                }
                catch (Exception ex)
                {
                    // 避免日志记录器本身的异常影响程序运行
                    Console.WriteLine($"Logger failed: {ex.Message}");
                }
            }
        }

        public void Debug(string message) => Log(LogLevel.Debug, message);
        public void Info(string message) => Log(LogLevel.Info, message);
        public void Warning(string message) => Log(LogLevel.Warning, message);
        public void Error(string message, Exception exception = null) => Log(LogLevel.Error, message, exception);
        public void Fatal(string message, Exception exception = null) => Log(LogLevel.Fatal, message, exception);
    }

    /// <summary>
    /// 静态日志管理器
    /// </summary>
    public static class Logger
    {
        private static ILogger _instance;
        private static readonly object _lock = new object();
        
        /// <summary>
        /// 获取日志系统是否已初始化
        /// </summary>
        public static bool IsInitialized => _instance != null;

        public static ILogger Instance
        {
            get
            {
                if (_instance == null)
                {
                    lock (_lock)
                    {
                        if (_instance == null)
                        {
                            // 默认配置：控制台 + 文件日志
                            _instance = CreateDefaultLogger();
                        }
                    }
                }
                return _instance;
            }
            set
            {
                lock (_lock)
                {
                    _instance = value;
                }
            }
        }

        public static void Log(LogLevel level, string message, Exception exception = null)
        {
            Instance.Log(level, message, exception);
        }

        public static void Debug(string message) => Instance.Debug(message);
        public static void Info(string message) => Instance.Info(message);
        public static void Warning(string message) => Instance.Warning(message);
        public static void Error(string message, Exception exception = null) => Instance.Error(message, exception);
        public static void Fatal(string message, Exception exception = null) => Instance.Fatal(message, exception);

        private static ILogger CreateDefaultLogger()
        {
            try
            {
                // 加载配置
                var config = LogConfigManager.Config;
                
                var loggers = new List<ILogger>();
                
                // 控制台日志记录器
                if (config.Logging.Console.Enabled)
                {
                    var consoleLogger = new ConsoleLogger 
                    { 
                        MinLevel = LogConfigManager.ParseLogLevel(config.Logging.Console.LogLevel) 
                    };
                    loggers.Add(consoleLogger);
                }
                
                // 文件日志记录器
                if (config.Logging.File.Enabled)
                {
                    var logDir = Path.Combine(AppContext.BaseDirectory, config.Logging.File.Path);
                    var fileName = config.Logging.File.FileName
                        .Replace("{date}", DateTime.Now.ToString("yyyyMMdd"))
                        .Replace("{time}", DateTime.Now.ToString("HHmmss"));
                    var logFile = Path.Combine(logDir, fileName);
                    
                    var fileLogger = new FileLogger(logFile) 
                    { 
                        MinLevel = LogConfigManager.ParseLogLevel(config.Logging.File.LogLevel) 
                    };
                    loggers.Add(fileLogger);
                }
                
                if (loggers.Count == 0)
                {
                    // 如果没有启用任何日志记录器，至少使用控制台
                    loggers.Add(new ConsoleLogger { MinLevel = LogLevel.Info });
                }
                
                Console.WriteLine($"Logger initialized with {loggers.Count} targets");
                return new CompositeLogger(loggers.ToArray());
            }
            catch (Exception ex)
            {
                // 如果创建默认日志记录器失败，至少保证控制台日志可用
                Console.WriteLine($"Failed to create default logger: {ex.Message}");
                return new ConsoleLogger { MinLevel = LogLevel.Debug };
            }
        }

        public static void Initialize(string logFilePath = null, LogLevel minLevel = LogLevel.Debug, bool useSerilog = true)
        {
            try
            {
                if (useSerilog)
                {
                    // 优先使用Serilog
                    Instance = new SerilogLogger();
                    Console.WriteLine("Serilog logger initialized successfully");
                }
                else
                {
                    // 回退到传统日志
                    if (string.IsNullOrEmpty(logFilePath))
                    {
                        logFilePath = Path.Combine(AppContext.BaseDirectory, "logs", $"mcgame_{DateTime.Now:yyyyMMdd_HHmmss}.log");
                    }

                    var consoleLogger = new ConsoleLogger { MinLevel = LogLevel.Info };
                    var fileLogger = new FileLogger(logFilePath) { MinLevel = minLevel };

                    Instance = new CompositeLogger(consoleLogger, fileLogger);
                    
                    Console.WriteLine("Traditional logger initialized successfully");
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Failed to initialize logger: {ex.Message}");
                Instance = new ConsoleLogger { MinLevel = LogLevel.Debug };
            }
        }

        /// <summary>
        /// 从IServiceProvider获取日志实例
        /// </summary>
        public static ILogger GetLogger(IServiceProvider serviceProvider)
        {
            if (serviceProvider == null)
            {
                return Instance;
            }

            // 尝试从服务容器获取日志实例
            var logger = serviceProvider.GetService(typeof(ILogger)) as ILogger;
            return logger ?? Instance;
        }

        /// <summary>
        /// 获取SerilogLogger实例（如果可用）
        /// </summary>
        public static SerilogLogger GetSerilogLogger()
        {
            return Instance as SerilogLogger;
        }
    }

    /// <summary>
    /// Serilog日志记录器
    /// 提供结构化日志、文件日志、控制台日志等高级功能
    /// </summary>
    public class SerilogLogger : BaseLogger
    {
        private readonly Serilog.ILogger _logger;
        private static readonly string _logDirectory = Path.Combine(AppContext.BaseDirectory, "logs");
        private static readonly string _logFile = Path.Combine(_logDirectory, $"mcgame_{DateTime.Now:yyyyMMdd_HHmmss}.log");

        public SerilogLogger()
        {
            try
            {
                // 确保日志目录存在
                Directory.CreateDirectory(_logDirectory);
                
                // 配置Serilog
                _logger = new Serilog.LoggerConfiguration()
                    .MinimumLevel.Debug()
                    .MinimumLevel.Override("Microsoft", Serilog.Events.LogEventLevel.Information)
                    .MinimumLevel.Override("System", Serilog.Events.LogEventLevel.Information)
                    .Enrich.FromLogContext()
                    .Enrich.WithProperty("ThreadId", "")
                    .Enrich.WithProperty("ProcessId", "")
                    .Enrich.WithProperty("MachineName", "")
                    .WriteTo.Console(
                        outputTemplate: "[{Timestamp:HH:mm:ss.fff} {Level:u3}] [{SourceContext}] {Message:lj}{NewLine}{Exception}")
                    .WriteTo.File(
                        path: _logFile,
                        rollingInterval: Serilog.RollingInterval.Hour,
                        outputTemplate: "[{Timestamp:yyyy-MM-dd HH:mm:ss.fff} {Level:u3}] [{SourceContext}] [{ThreadId}] {Message:lj}{NewLine}{Exception}")
                    .WriteTo.File(
                        path: Path.Combine(_logDirectory, "mcgame_debug.log"),
                        restrictedToMinimumLevel: Serilog.Events.LogEventLevel.Debug,
                        rollingInterval: Serilog.RollingInterval.Day,
                        outputTemplate: "[{Timestamp:yyyy-MM-dd HH:mm:ss.fff} {Level:u3}] [{SourceContext}] [{ThreadId}] {Message:lj}{NewLine}{Exception}")
                    .CreateLogger();
                
                _logger.Information("Serilog logger initialized");
                _logger.Information("Log file: {LogFile}", _logFile);
            }
            catch (Exception ex)
            {
                // 如果Serilog初始化失败，回退到简单日志
                Console.WriteLine($"Failed to initialize Serilog logger: {ex.Message}");
                _logger = null;
            }
        }

        protected override void WriteLog(string message)
        {
            if (_logger != null)
            {
                try
                {
                    _logger.Information(message);
                }
                catch
                {
                    // 如果Serilog写入失败，回退到控制台
                    Console.WriteLine(message);
                }
            }
            else
            {
                Console.WriteLine(message);
            }
        }

        public override void Debug(string message)
        {
            if (_logger != null)
            {
                _logger.Debug(message);
            }
            else
            {
                base.Debug(message);
            }
        }

        public override void Info(string message)
        {
            if (_logger != null)
            {
                _logger.Information(message);
            }
            else
            {
                base.Info(message);
            }
        }

        public override void Warning(string message)
        {
            if (_logger != null)
            {
                _logger.Warning(message);
            }
            else
            {
                base.Warning(message);
            }
        }

        public override void Error(string message, Exception exception = null)
        {
            if (_logger != null)
            {
                if (exception != null)
                {
                    _logger.Error(exception, message);
                }
                else
                {
                    _logger.Error(message);
                }
            }
            else
            {
                base.Error(message, exception);
            }
        }

        public override void Fatal(string message, Exception exception = null)
        {
            if (_logger != null)
            {
                if (exception != null)
                {
                    _logger.Fatal(exception, message);
                }
                else
                {
                    _logger.Fatal(message);
                }
            }
            else
            {
                base.Fatal(message, exception);
            }
        }

        /// <summary>
        /// 记录性能信息
        /// </summary>
        public void Performance(string operation, long elapsedMs)
        {
            if (_logger != null)
            {
                _logger.Information("[PERF] {Operation} completed in {ElapsedMs}ms", operation, elapsedMs);
            }
        }

        /// <summary>
        /// 记录渲染信息
        /// </summary>
        public void Render(string message, params object[] args)
        {
            if (_logger != null)
            {
                try
                {
                    if (args.Length > 0)
                    {
                        _logger.Information("[RENDER] " + message, args);
                    }
                    else
                    {
                        _logger.Information("[RENDER] {Message}", message);
                    }
                }
                catch (FormatException)
                {
                    // 如果格式化失败，回退到简单日志
                    _logger.Information("[RENDER] {Message}", message);
                }
            }
        }

        /// <summary>
        /// 记录区块信息
        /// </summary>
        public void Chunk(string message, params object[] args)
        {
            if (_logger != null)
            {
                try
                {
                    if (args.Length > 0)
                    {
                        _logger.Information("[CHUNK] " + message, args);
                    }
                    else
                    {
                        _logger.Information("[CHUNK] {Message}", message);
                    }
                }
                catch (FormatException)
                {
                    // 如果格式化失败，回退到简单日志
                    _logger.Information("[CHUNK] {Message}", message);
                }
            }
        }

        /// <summary>
        /// 记录内存使用情况
        /// </summary>
        public void MemoryUsage()
        {
            if (_logger != null)
            {
                try
                {
                    var process = System.Diagnostics.Process.GetCurrentProcess();
                    var memoryMB = process.WorkingSet64 / 1024 / 1024;
                    _logger.Information("[MEMORY] Usage: {MemoryMB}MB", memoryMB);
                }
                catch
                {
                    // 忽略内存日志错误
                }
            }
        }

        /// <summary>
        /// 关闭日志系统
        /// </summary>
        public void Shutdown()
        {
            if (_logger != null)
            {
                try
                {
                    _logger.Information("Serilog logger shutdown");
                    Serilog.Log.CloseAndFlush();
                }
                catch
                {
                    // 忽略关闭错误
                }
            }
        }
    }
}
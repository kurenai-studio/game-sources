using Serilog.Events;

namespace DerelictDimension.CommandLine;

/// <summary>
/// Container for parsed command-line arguments. Values are valid after <see cref="CMD.Parse"/> was called.
/// </summary>
public static class CommandLineArgs
{
    /// <summary>
    /// (Windows only) Create console for the game.
    /// </summary>
    public static bool EnableConsole;

    /// <summary>
    /// Minimum log level, messages of level less important it will be ignored.
    /// </summary>
    public static LogEventLevel LogLevel;

    /// <summary>
    /// Change language the game uses.
    /// </summary>
    public static string? Language;
    public static bool ShowHelp;
}

using Monod.Shared.Extensions;
using Serilog.Events;
using System.Collections.Generic;
using System.CommandLine;

namespace DerelictDimension.CommandLine;

/// <summary>
/// Class for parsing command-line arguments.
/// </summary>
public static class CMD
{
    private static Option<bool> ConsoleOp = new("--console")
    {
        Description = "(Windows only) Create console for the game, which works as input and output",
    };

    private static Option<bool> HelpOp = new("--help")
    {
        Description = "Show help message/manual",
    };

    private static Option<LogEventLevel> LogLevelOp = new("--log-level")
    {
        Description = "Minimum log level, messages of level less important it will be ignored",
        DefaultValueFactory = _ => LogEventLevel.Information,
    };

    private static Option<string> LanguageOp = new("--language", "--lang")
    {
        Description = "Change language the game uses",
    };

    /// <summary>
    /// Parses the specified command-line arguments, and sets <see cref="CommandLineArgs"/> based on parse result.
    /// </summary>
    /// <param name="args">Command-line arguments to parse.</param>
    public static void Parse(IReadOnlyList<string> args)
    {
        CreateRootCommand().Parse(args).Invoke();
    }

    /// <summary>
    /// Assign parse results to <see cref="CommandLineArgs"/>.
    /// </summary>
    /// <param name="result">Parse results to assign.</param>
    private static void AssignResults(ParseResult result)
    {
        CommandLineArgs.EnableConsole = result.GetValue(ConsoleOp);
        CommandLineArgs.LogLevel = result.GetValue(LogLevelOp);
        CommandLineArgs.Language = result.GetValue(LanguageOp);
        CommandLineArgs.ShowHelp = result.GetValue(HelpOp);
    }

    /// <summary>
    /// Adds all options from <see cref="CMD"/> (e.g. <see cref="ConsoleOp"/>) to <see cref="Command.Options"/>.
    /// </summary>
    /// <param name="root">Command, to which add options.</param>
    private static void AddOptionsToRoot(Command root)
    {
        root.Options.AddRange([ConsoleOp, HelpOp, LogLevelOp, LanguageOp]);
    }

    /// <summary>
    /// Create <see cref="RootCommand"/> for parsing command-line arguments.
    /// </summary>
    /// <returns>New instance of <see cref="RootCommand"/> with all the options and actions set.</returns>
    private static RootCommand CreateRootCommand()
    {
        RootCommand rootCommand = new();
        rootCommand.SetAction(AssignResults);
        AddOptionsToRoot(rootCommand);
        return rootCommand;
    }
}

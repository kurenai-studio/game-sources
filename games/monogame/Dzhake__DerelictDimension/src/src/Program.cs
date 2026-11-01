// 'global using' solves intellicode suggesting system.numerics and stuff like that
global using Friflo.Engine.ECS;
global using Microsoft.Xna.Framework;
global using Microsoft.Xna.Framework.Graphics;
global using Serilog;
global using Math = System.Math;
global using RectangleF = MLEM.Maths.RectangleF;
using DerelictDimension.CommandLine;
using Monod;
using Monod.Localization;
using Monod.LogModule;
using System;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Threading.Tasks;

namespace DerelictDimension;

/// <summary>
/// Entry class for the executable.
/// </summary>
public static class Program
{
    /// <summary>
    /// Name of running application.
    /// </summary>
    public static string AppName = "DerelictDimension";

    /// <summary>
    /// File path to file where error message should be written.
    /// </summary>
    public static readonly string errorFile = $"{AppContext.BaseDirectory}error.txt";

    /// <summary>
    /// File path to file which is created if the game fails to log an exception.
    /// </summary>
    public static readonly string errorx2File = $"{AppContext.BaseDirectory}ERRORX2.txt";

    /// <summary>
    /// Entry point of the executable. Acts as try/catch wrapper around <see cref="SafeMain"/>.
    /// </summary>
    public static void Main()
    {
        if (Debugger.IsAttached)
        {
            SafeMain();
        }
        else
        {
            try
            {
                SafeMain();
            }
            catch (Exception exception)
            {
                Crash(exception);
                Environment.Exit(1);
            }
        }
    }

    /// <summary>
    /// Entry point of executable, wrapped by <see cref="Main"/>. All exceptions here are caught and logged.
    /// </summary>
    public static void SafeMain()
    {
        //It's very important to erase those files early, in case crash will occur they always need to be up-to-date
        File.Delete(errorx2File);
        File.WriteAllText(errorFile, $"{DateTime.Now}\n");
        File.WriteAllText(LogHelper.LogFile, $"{DateTime.Now}\n");

        //DO NOT USE Main(string[]) ! That is different from Environment.GetCommandLineArgs(); because it doesn't include path to process executable as first arg. To prevent confusion and messing up indexes use Environment.GetCommandLineArgs(); instead.
        string[] args = Environment.GetCommandLineArgs();

        CMD.Parse(args.Skip(1).ToArray()); //First arg is the path to .exe/.dll, which crashes the parser
        if (args.Contains("--help"))
        {
            if (RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
                WindowsAPI.AllocConsoleSafe();
            Console.WriteLine("['--help' found, exiting the program]");
            Console.WriteLine("\nPress any key to exit..");
            Console.ReadKey();
            File.AppendAllText(LogHelper.LogFile, $"Command-line arguments: {args}\n['--help' found, exiting the program]");
            return; //Assume user doesn't want to launch the app, and wants help instead.
        }
        InitializeMonod(args);
        RunGame();
    }

    private static void InitializeMonod(string[] args)
    {
        if (CommandLineArgs.EnableConsole && RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
        {
            bool consoleAllocated = WindowsAPI.AllocConsoleSafe();
            if (consoleAllocated)
            {
                Log.Information("Allocated console for the game");
                Task.Run(ReadConsoleInput);
            }
            else
            {
                Log.Error("Failed to allocate console");
            }
        }

        MonodMain.EarlyInitialize();
        //DO NOT log anything with level below Information until this is called! Otherwise, those lines will never be logged.
        LogHelper.SetMinimumLogLevel(CommandLineArgs.LogLevel);
        if (CommandLineArgs.Language is not null) Locale.CurrentLanguage = CommandLineArgs.Language;

        Log.Information("Command-line arguments: {Args}", string.Join(' ', args));
        LogHelper.WriteStartupInfo();
    }

    /// <summary>
    /// Logs the <paramref name="exception"/>. Call before quitting the program on error.
    /// </summary>
    /// <param name="exception"><see cref="Exception"/> to log.</param>
    public static void Crash(Exception exception)
    {
        try
        {
            Log.Fatal(exception, "An exception was thrown.");
            File.AppendAllText(errorFile, $"{exception}\n\n\n");

            //open log.txt
            new Process
            {
                StartInfo = new ProcessStartInfo(LogHelper.LogFile)
                {
                    UseShellExecute = true
                }
            }.Start();
        }
        catch (Exception exception2)
        {
            //If the program exits without writing error file then error is here. I'm not even sure what would you if catch an exception here. Return some very uncommon exit code? 
            File.AppendAllText(errorFile, $"{exception}\n\n\n{exception2}");

            Environment.Exit(2);
        }
    }

    /// <summary>
    /// Run a new <see cref="TheGame"/>.
    /// </summary>
    public static void RunGame()
    {
        new TheGame().Run();
    }

    /// <summary>
    /// Read input from <see cref="Console"/> add adds it to <see cref="DevConsole.CommandsQueue"/>.
    /// </summary>
    public static async Task ReadConsoleInput()
    {
        while (true)
        {
            string? command = await Console.In.ReadLineAsync();
            switch (command)
            {
            case null:
                continue;
            case "exit":
                Environment.Exit(0);
                break;
            }

            DevConsole.CommandsQueue.Enqueue(command);
        }
    }
}


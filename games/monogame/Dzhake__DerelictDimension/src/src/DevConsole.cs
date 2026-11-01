using System.Collections.Generic;

namespace DerelictDimension;

/// <summary>
/// Class for managing console allocated via <see cref="WindowsAPI.AllocConsole"/>, and in-game console.
/// </summary>
public static class DevConsole
{
    /// <summary>
    /// Queue of commands inputted via <see cref="Program.ReadConsoleInput"/>.
    /// </summary>
    public static readonly Queue<string> CommandsQueue = new();

    /// <summary>
    /// Updates <see cref="DevConsole"/>.
    /// </summary>
    public static void Update()
    {
        for (; CommandsQueue.Count > 0;)
            Run(CommandsQueue.Dequeue());
    }

    /// <summary>
    /// Runs the specified <paramref name="command"/>.
    /// </summary>
    /// <param name="command">Command to run.</param>
    public static void Run(string command)
    {
        if (TheGame.Instance is null) return;
        TheGame.Instance.text = command;
    }
}

using System;
using System.IO;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace Breakout.Systems;

/// <summary>
/// Screenshot automation: `dotnet run -- --screenshot classic out.png` boots
/// the game, starts the named mode, waits for the entrance animation to
/// settle, saves one frame as a PNG and exits. It exists because the README
/// and study-guide screenshots must track the real game — a doc image nobody
/// can regenerate is a doc fact nobody can check. The capture happens at the
/// very end of the pipeline (the back buffer, after the CRT pass), so the
/// file shows exactly what a player sees. MonoGame has no "save screenshot"
/// call; the idiom is GetBackBufferData into a Color[], SetData onto a
/// throwaway Texture2D, and Texture2D.SaveAsPng — the read-back mirror of
/// the 1x1-pixel trick.
/// </summary>
public sealed class ScreenshotRig
{
    // Three seconds at 60 Hz: enough for the brick drop-in (0.5 s plus its
    // stagger) to land and the title's placeholder session to go quiet.
    private const int SettleTicks = 180;

    private readonly string _modeName;
    private int _ticks;

    public string OutputPath { get; }

    /// <summary>True once the settle time has passed — the shell captures at
    /// the end of its next Draw.</summary>
    public bool CaptureDue { get; private set; }

    private ScreenshotRig(string modeName, string outputPath)
    {
        _modeName = modeName;
        OutputPath = outputPath;
    }

    /// <summary>Null when the args don't ask for a screenshot — the normal
    /// game run. Program.cs calls this; nothing else parses argv.</summary>
    public static ScreenshotRig TryParse(string[] args)
    {
        int flag = Array.IndexOf(args, "--screenshot");
        if (flag < 0)
            return null;
        if (args.Length < flag + 3) // needs <mode> and <out.png> after the flag
            throw new ArgumentException(
                "usage: --screenshot <title|modern|coop|classic|double|cavity|progressive> <out.png>");
        return new ScreenshotRig(args[flag + 1], args[flag + 2]);
    }

    /// <summary>The mode to boot into; null means stay on the title screen.</summary>
    public GameMode? Mode => _modeName switch
    {
        "title" => null,
        "modern" => GameMode.Modern,
        "coop" => GameMode.Coop,
        "classic" => GameMode.Classic,
        "double" => GameMode.SuperDouble,
        "cavity" => GameMode.SuperCavity,
        "progressive" => GameMode.SuperProgressive,
        _ => throw new ArgumentException($"unknown screenshot mode '{_modeName}'"),
    };

    /// <summary>Called once per Update tick.</summary>
    public void Tick()
    {
        if (++_ticks >= SettleTicks)
            CaptureDue = true;
    }

    /// <summary>Save the current back buffer and stop asking for captures.
    /// Called after Present, so the CRT pass is in the pixels.</summary>
    public void Capture(GraphicsDevice device)
    {
        CaptureDue = false;

        int width = device.PresentationParameters.BackBufferWidth;
        int height = device.PresentationParameters.BackBufferHeight;
        var pixels = new Color[width * height];
        device.GetBackBufferData(pixels);

        using var texture = new Texture2D(device, width, height);
        texture.SetData(pixels);

        string directory = Path.GetDirectoryName(Path.GetFullPath(OutputPath));
        if (!string.IsNullOrEmpty(directory))
            Directory.CreateDirectory(directory);
        using FileStream stream = File.Create(OutputPath);
        texture.SaveAsPng(stream, width, height);
    }
}

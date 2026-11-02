using System;
using System.Collections.Generic;
using System.IO;
using System.Text.Json;

namespace Breakout.Systems;

/// <summary>
/// Top-five score tables, one per named table (see GameSession.ScoreTableFor),
/// persisted as JSON. The key
/// lesson: reading and writing game data are different problems. Levels load
/// through TitleContainer, which is READ-ONLY by design (on some platforms
/// the game's install directory cannot be written at all). Save data needs a
/// real, writable, per-user path — Environment.SpecialFolder.ApplicationData
/// resolves to the right place on each OS (AppData\Roaming on Windows,
/// ~/.config on Linux, ~/Library/Application Support on macOS).
///
/// All IO is wrapped in try/catch and failure degrades to "no high scores" —
/// same philosophy as the audio: a broken disk should never crash the game.
/// </summary>
public static class HighScores
{
    private const int Capacity = 5;

    private static readonly string FilePath = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
        "Breakout", "highscores.json");

    // Mode name → scores, descending. Loaded lazily on first use.
    private static Dictionary<string, List<int>> _tables;

    // Tables are keyed by name, not by GameMode: a key is "whatever makes
    // scores comparable", and that's finer-grained than the mode enum — an
    // endless generated run can't fairly share a table with a three-level
    // one, so GameSession.ScoreTable adds a suffix for those.
    public static IReadOnlyList<int> For(string table)
    {
        Load();
        return _tables.TryGetValue(table, out List<int> list)
            ? list
            : Array.Empty<int>();
    }

    public static int Best(string table)
    {
        IReadOnlyList<int> list = For(table);
        return list.Count > 0 ? list[0] : 0;
    }

    /// <summary>
    /// Submit a finished run. Returns the 0-based rank it earned in the
    /// table's top five, or -1 if it didn't place (or scored nothing).
    /// </summary>
    public static int Record(string table, int score)
    {
        if (score <= 0)
            return -1;

        Load();
        if (!_tables.TryGetValue(table, out List<int> list))
            _tables[table] = list = new List<int>();

        int rank = InsertScore(list, score);
        if (rank >= 0)
            Save();
        return rank;
    }

    /// <summary>
    /// The ranking core, separated from the file IO above so it is testable:
    /// a function of (list, score) can be exercised a hundred ways in a unit
    /// test, while anything touching ApplicationData cannot run safely on a
    /// build machine. Splitting the decision from the disk is the standard
    /// move that makes game logic testable at all.
    /// </summary>
    public static int InsertScore(List<int> scores, int score)
    {
        if (score <= 0)
            return -1;

        int rank = scores.FindIndex(existing => score > existing);
        if (rank < 0)
        {
            if (scores.Count >= Capacity)
                return -1;
            rank = scores.Count;
        }

        scores.Insert(rank, score);
        if (scores.Count > Capacity)
            scores.RemoveAt(Capacity);
        return rank;
    }

    private static void Load()
    {
        if (_tables != null)
            return;

        try
        {
            if (File.Exists(FilePath))
                _tables = JsonSerializer.Deserialize<Dictionary<string, List<int>>>(
                    File.ReadAllText(FilePath));
        }
        catch (Exception)
        {
            // Corrupt or unreadable file: start fresh rather than crash.
            // (Production code would log this; we have nowhere to log to.)
        }

        _tables ??= new Dictionary<string, List<int>>();
    }

    private static void Save()
    {
        try
        {
            Directory.CreateDirectory(Path.GetDirectoryName(FilePath));
            File.WriteAllText(FilePath, JsonSerializer.Serialize(_tables,
                new JsonSerializerOptions { WriteIndented = true }));
        }
        catch (Exception)
        {
            // Read-only disk or denied permissions: scores just don't persist
            // this session. Never let a save failure take the game down.
        }
    }
}

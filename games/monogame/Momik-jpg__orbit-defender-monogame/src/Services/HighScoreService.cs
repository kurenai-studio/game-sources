using System.Text.Json;
using OrbitDefender.Core;
using OrbitDefender.Models;

namespace OrbitDefender.Services;

public sealed class HighScoreService : IHighScoreService
{
    private readonly JsonSerializerOptions _jsonOptions = new()
    {
        WriteIndented = true
    };

    private readonly string _filePath;

    public HighScoreService(string? filePath = null)
    {
        _filePath = filePath ?? Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "AndrinPortfolio",
            "OrbitDefender",
            "highscores.json");
    }

    public IReadOnlyList<HighScoreEntry> Load()
    {
        TryLoad(out var entries);
        return entries;
    }

    private bool TryLoad(out List<HighScoreEntry> entries)
    {
        entries = new List<HighScoreEntry>();
        try
        {
            var rawJson = File.ReadAllText(_filePath);
            var loaded = JsonSerializer.Deserialize<List<HighScoreEntry>>(rawJson, _jsonOptions);
            if (loaded is null || loaded.Any(entry =>
                entry is null || entry.Score <= 0 || string.IsNullOrWhiteSpace(entry.PlayerName)))
            {
                return false;
            }

            entries = Normalize(loaded).ToList();
            return true;
        }
        catch (FileNotFoundException)
        {
            return true;
        }
        catch (DirectoryNotFoundException)
        {
            return true;
        }
        catch
        {
            return false;
        }
    }

    public bool Record(string playerName, int score, int level)
    {
        if (score <= 0)
        {
            return false;
        }

        var normalizedName = string.IsNullOrWhiteSpace(playerName) ? GameSettings.DefaultPilotName : playerName.Trim();
        if (!TryLoad(out var existing))
        {
            return false;
        }

        var newEntry = new HighScoreEntry
        {
            PlayerName = normalizedName,
            Score = score,
            Level = level,
            CreatedAtUtc = DateTime.UtcNow
        };

        existing.Add(newEntry);

        var ranked = Normalize(existing)
            .Take(GameSettings.MaxHighScores)
            .ToList();

        if (!Save(ranked))
        {
            return false;
        }

        return ranked.Any(item =>
            item.PlayerName == newEntry.PlayerName
            && item.Score == newEntry.Score
            && item.Level == newEntry.Level
            && item.CreatedAtUtc == newEntry.CreatedAtUtc);
    }

    private static IEnumerable<HighScoreEntry> Normalize(IEnumerable<HighScoreEntry> entries)
    {
        return entries
            .Where(entry => entry.Score > 0 && !string.IsNullOrWhiteSpace(entry.PlayerName))
            .OrderByDescending(entry => entry.Score)
            .ThenByDescending(entry => entry.Level)
            .ThenByDescending(entry => entry.CreatedAtUtc);
    }

    private bool Save(List<HighScoreEntry> entries)
    {
        string? temporaryPath = null;
        try
        {
            var directory = Path.GetDirectoryName(_filePath);
            if (!string.IsNullOrWhiteSpace(directory))
            {
                Directory.CreateDirectory(directory);
            }

            var json = JsonSerializer.Serialize(entries, _jsonOptions);
            temporaryPath = $"{_filePath}.{Guid.NewGuid():N}.tmp";
            File.WriteAllText(temporaryPath, json);
            File.Move(temporaryPath, _filePath, overwrite: true);
            return true;
        }
        catch
        {
            return false;
        }
        finally
        {
            if (temporaryPath is not null)
            {
                File.Delete(temporaryPath);
            }
        }
    }
}

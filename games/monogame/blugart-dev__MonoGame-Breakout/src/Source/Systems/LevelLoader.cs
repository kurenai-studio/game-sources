using System.Collections.Generic;
using System.IO;
using Microsoft.Xna.Framework;
using Breakout.Entities;

namespace Breakout.Systems;

/// <summary>
/// Levels are plain text loaded at runtime with TitleContainer.OpenStream —
/// deliberately NOT through the Content Pipeline. The pipeline earns its keep
/// when assets need processing (textures into GPU formats, fonts into glyph
/// atlases); a text grid gains nothing from being compiled to .xnb, and
/// runtime loading keeps levels hand-editable without a rebuild of content.
/// TitleContainer resolves paths relative to the game's root directory in a
/// platform-safe way (forward slashes, even on Windows).
/// The .txt files reach the output folder via a CopyToOutputDirectory entry in
/// Breakout.csproj — the pipeline only copies what it builds.
/// </summary>
public static class LevelLoader
{
    private const int Columns = 13;
    private const int CellWidth = Screen.Width / Columns;
    private const int CellHeight = 22;
    private const int GridOffsetY = 40; // leave the HUD strip clear

    // Integer division above loses a few pixels; center the grid to hide it.
    private static readonly int GridOffsetX = (Screen.Width - Columns * CellWidth) / 2;

    public static List<Brick> Load(string path)
    {
        using Stream stream = TitleContainer.OpenStream(path);
        using var reader = new StreamReader(stream);
        return Parse(reader);
    }

    /// <summary>
    /// The actual parser, split from the file access so that anything able to
    /// produce the text format can feed it — a file via Load above, or
    /// BoardGenerator's output via a StringReader. The grid format is the
    /// contract; where the characters come from is nobody's business.
    /// </summary>
    public static List<Brick> Parse(TextReader reader)
    {
        var bricks = new List<Brick>();

        int row = 0;
        string line;
        while ((line = reader.ReadLine()) != null)
        {
            if (line.Length == 0 || line[0] == '#')
                continue; // comments and blank lines don't advance the grid

            for (int col = 0; col < line.Length && col < Columns; col++)
            {
                char cell = line[col];
                if (cell == '.')
                    continue;

                var bounds = new Rectangle(
                    GridOffsetX + col * CellWidth + 1,
                    GridOffsetY + row * CellHeight + 1,
                    CellWidth - 2,
                    CellHeight - 2);

                if (cell == 'X')
                    bricks.Add(Brick.Unbreakable(bounds));
                else if (cell >= '1' && cell <= '5')
                    bricks.Add(new Brick(bounds, cell - '0'));
            }
            row++;
        }

        // Entrance animation, staggered by column so the wall sweeps in
        // left-to-right. The classic wall deliberately skips this: the 1976
        // machine made bricks appear instantly, and faithful means faithful.
        foreach (Brick brick in bricks)
            brick.StartDropIn((brick.Bounds.X - GridOffsetX) / (float)CellWidth * 0.04f);

        return bricks;
    }
}

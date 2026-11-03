using System;
using System.Collections.Generic;

namespace QapaqInqa.Core
{
    public enum Tile
    {
        Empty,
        /// <summary>Stone masonry: blocks from every side.</summary>
        Solid,
        /// <summary>A wooden ledge: stands on it from above, jumps through it from below.</summary>
        Platform,
        Ladder,
        Spikes,
    }

    public enum ThingKind
    {
        Coin,
        /// <summary>A golden idol; every one of them must be found to open the Sun Gate.</summary>
        Artifact,
        /// <summary>A mullu (Spondylus shell), a rare treasure worth many points.</summary>
        Shell,
        Heart,
        Checkpoint,
        Walker,
        Bat,
        Boss,
    }

    /// <summary>Something placed on the map, at the bottom-left corner of its tile.</summary>
    public readonly struct Placement
    {
        public Placement(ThingKind kind, int x, int y)
        {
            Kind = kind;
            X = x;
            Y = y;
        }

        public ThingKind Kind { get; }
        public int X { get; }
        public int Y { get; }
    }

    /// <summary>
    /// A level parsed from text rows, the top row first. y grows upwards, so tile (x, y) covers
    /// [x, x+1] by [y, y+1] in world units. Legend:
    /// <c>#</c> stone, <c>=</c> ledge, <c>H</c> ladder, <c>^</c> spikes, <c>P</c> player start,
    /// <c>E</c> Sun Gate (its bottom-left tile), <c>o</c> coin, <c>A</c> golden idol, <c>S</c> shell,
    /// <c>+</c> heart, <c>C</c> checkpoint, <c>w</c> walker, <c>b</c> bat, <c>B</c> the boss.
    /// Anything else is empty air.
    /// </summary>
    public sealed class LevelMap
    {
        readonly Tile[,] tiles;
        readonly List<Placement> placements = new List<Placement>();

        public LevelMap(IReadOnlyList<string> rows)
        {
            if (rows == null || rows.Count == 0)
            {
                throw new ArgumentException("A level needs at least one row.", nameof(rows));
            }
            Height = rows.Count;
            int width = 0;
            foreach (string row in rows)
            {
                width = Math.Max(width, row.Length);
            }
            Width = width;
            tiles = new Tile[Width, Height];

            bool hasStart = false;
            bool hasGate = false;
            for (int r = 0; r < Height; r++)
            {
                string row = rows[r];
                int y = Height - 1 - r;
                for (int x = 0; x < row.Length; x++)
                {
                    char c = row[x];
                    switch (c)
                    {
                        case '#': tiles[x, y] = Tile.Solid; break;
                        case '=': tiles[x, y] = Tile.Platform; break;
                        case 'H': tiles[x, y] = Tile.Ladder; break;
                        case '^': tiles[x, y] = Tile.Spikes; break;
                        case 'P':
                            if (hasStart) throw new FormatException("A level has exactly one player start (P).");
                            hasStart = true;
                            Start = new Vec2(x + 0.5f, y);
                            break;
                        case 'E':
                            if (hasGate) throw new FormatException("A level has exactly one Sun Gate (E).");
                            hasGate = true;
                            Gate = new Vec2(x, y);
                            break;
                        case 'o': placements.Add(new Placement(ThingKind.Coin, x, y)); break;
                        case 'A': placements.Add(new Placement(ThingKind.Artifact, x, y)); break;
                        case 'S': placements.Add(new Placement(ThingKind.Shell, x, y)); break;
                        case '+': placements.Add(new Placement(ThingKind.Heart, x, y)); break;
                        case 'C': placements.Add(new Placement(ThingKind.Checkpoint, x, y)); break;
                        case 'w': placements.Add(new Placement(ThingKind.Walker, x, y)); break;
                        case 'b': placements.Add(new Placement(ThingKind.Bat, x, y)); break;
                        case 'B': placements.Add(new Placement(ThingKind.Boss, x, y)); break;
                    }
                }
            }
            if (!hasStart) throw new FormatException("A level has exactly one player start (P).");
            if (!hasGate) throw new FormatException("A level has exactly one Sun Gate (E).");
        }

        public int Width { get; }
        public int Height { get; }
        /// <summary>The player's feet at the start.</summary>
        public Vec2 Start { get; }
        /// <summary>The bottom-left corner of the Sun Gate (two tiles wide, three tall).</summary>
        public Vec2 Gate { get; }
        public IReadOnlyList<Placement> Placements => placements;

        public int Count(ThingKind kind)
        {
            int count = 0;
            foreach (Placement p in placements)
            {
                if (p.Kind == kind) count++;
            }
            return count;
        }

        /// <summary>The tile at (x, y). Beyond the left and right edges is stone; above and below is air.</summary>
        public Tile At(int x, int y)
        {
            if (x < 0 || x >= Width) return Tile.Solid;
            if (y < 0 || y >= Height) return Tile.Empty;
            return tiles[x, y];
        }

        public bool IsSolid(int x, int y) => At(x, y) == Tile.Solid;

        /// <summary>True for a ledge, or the top rung of a ladder (both can be stood on from above).</summary>
        public bool IsStandableTop(int x, int y)
        {
            Tile tile = At(x, y);
            return tile == Tile.Platform || (tile == Tile.Ladder && At(x, y + 1) != Tile.Ladder);
        }

        public static int Floor(float value) => (int)Math.Floor(value);
    }
}

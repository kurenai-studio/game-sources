using System;
using System.Collections.Generic;
using System.Linq;
using NUnit.Framework;
using QapaqInqa.Core;

namespace QapaqInqa.Core.Tests
{
    public class LevelTests
    {
        [Test]
        public void TheLegendIsReadWithYGrowingUpwards()
        {
            var map = new LevelMap(new[]
            {
                "  b   ",
                " =H^ E",
                "P o A#",
                "######",
            });
            Assert.That(map.Width, Is.EqualTo(6));
            Assert.That(map.Height, Is.EqualTo(4));
            Assert.That(map.Start, Is.EqualTo(new Vec2(0.5f, 1f)));
            Assert.That(map.Gate, Is.EqualTo(new Vec2(5f, 2f)));
            Assert.That(map.At(0, 0), Is.EqualTo(Tile.Solid));
            Assert.That(map.At(5, 1), Is.EqualTo(Tile.Solid));
            Assert.That(map.At(1, 2), Is.EqualTo(Tile.Platform));
            Assert.That(map.At(2, 2), Is.EqualTo(Tile.Ladder));
            Assert.That(map.At(3, 2), Is.EqualTo(Tile.Spikes));
            Assert.That(map.Count(ThingKind.Coin), Is.EqualTo(1));
            Assert.That(map.Count(ThingKind.Artifact), Is.EqualTo(1));
            Assert.That(map.Count(ThingKind.Bat), Is.EqualTo(1));
            Assert.That(map.Placements.Single(p => p.Kind == ThingKind.Bat).Y, Is.EqualTo(3));
        }

        [Test]
        public void BeyondTheSidesIsStoneAndAboveAndBelowIsAir()
        {
            var map = new LevelMap(new[] { "P E", "###" });
            Assert.That(map.At(-1, 1), Is.EqualTo(Tile.Solid));
            Assert.That(map.At(3, 1), Is.EqualTo(Tile.Solid));
            Assert.That(map.At(1, 2), Is.EqualTo(Tile.Empty));
            Assert.That(map.At(1, -1), Is.EqualTo(Tile.Empty));
        }

        [Test]
        public void OnlyTheTopRungOfALadderCanBeStoodOn()
        {
            var map = new LevelMap(new[] { " H ", " H ", "PHE", "###" });
            Assert.That(map.IsStandableTop(1, 3), Is.True);
            Assert.That(map.IsStandableTop(1, 2), Is.False);
            Assert.That(map.IsStandableTop(0, 1), Is.False);
        }

        [Test]
        public void ALevelNeedsExactlyOneStartAndOneGate()
        {
            Assert.Throws<FormatException>(() => new LevelMap(new[] { "  E", "###" }));
            Assert.Throws<FormatException>(() => new LevelMap(new[] { "P  ", "###" }));
            Assert.Throws<FormatException>(() => new LevelMap(new[] { "PPE", "###" }));
            Assert.Throws<FormatException>(() => new LevelMap(new[] { "PEE", "###" }));
            Assert.Throws<ArgumentException>(() => new LevelMap(new string[0]));
        }

        static IEnumerable<int> LevelIndices() => Enumerable.Range(0, Levels.All.Count);

        [TestCaseSource(nameof(LevelIndices))]
        public void EveryLevelHasIdolsACheckpointAndWritingForItsCodex(int index)
        {
            LevelInfo level = Levels.All[index];
            var map = new LevelMap(level.Map);
            Assert.That(map.Count(ThingKind.Artifact), Is.GreaterThanOrEqualTo(2));
            Assert.That(map.Count(ThingKind.Checkpoint), Is.GreaterThanOrEqualTo(1));
            Assert.That(map.Count(ThingKind.Coin), Is.GreaterThanOrEqualTo(10));
            Assert.That(level.ParSeconds, Is.GreaterThan(30f));
            Assert.That(level.Name, Is.Not.Empty);
            Assert.That(level.Lore.Text.Length, Is.GreaterThan(40));
        }

        /// <summary>
        /// A coarse check over the tile grid: from the start, walking, falling, climbing and jumps
        /// within the player's reach (2 tiles up and 3 across, or 4 across on the level) must lead to
        /// every idol, checkpoint, treasure and the gate. It caught several typos while drawing the maps.
        /// </summary>
        [TestCaseSource(nameof(LevelIndices))]
        public void EverythingThatMattersCanBeReached(int index)
        {
            var map = new LevelMap(Levels.All[index].Map);
            HashSet<(int, int)> reach = Reach(map);
            var missing = new List<string>();
            foreach (Placement p in map.Placements)
            {
                if (p.Kind == ThingKind.Bat || p.Kind == ThingKind.Walker || p.Kind == ThingKind.Boss) continue;
                if (!Enumerable.Range(p.Y - 3, 4).Any(y => reach.Contains((p.X, y)))) missing.Add($"{p.Kind} at ({p.X}, {p.Y})");
            }
            int gx = (int)map.Gate.X, gy = (int)map.Gate.Y;
            if (!reach.Contains((gx, gy)) && !reach.Contains((gx + 1, gy))) missing.Add("the Sun Gate");
            Assert.That(missing, Is.Empty);
        }

        static HashSet<(int, int)> Reach(LevelMap map)
        {
            bool Solid(int x, int y) => map.IsSolid(x, y);
            bool Free(int x, int y) => !Solid(x, y) && !Solid(x, y + 1) && map.At(x, y) != Tile.Spikes;
            bool Support(int x, int y) => Solid(x, y - 1) || map.IsStandableTop(x, y - 1);
            bool Ladder(int x, int y) => map.At(x, y) == Tile.Ladder || map.At(x, y + 1) == Tile.Ladder;
            (int, int)? Land(int x, int y)
            {
                for (; y >= 0; y--)
                {
                    if (!Free(x, y)) return null;
                    if (Support(x, y) || map.At(x, y) == Tile.Ladder) return (x, y);
                }
                return null;
            }

            var seen = new HashSet<(int, int)>();
            var queue = new Queue<(int, int)>();
            (int, int)? first = Land((int)map.Start.X, (int)map.Start.Y);
            Assert.That(first, Is.Not.Null, "the start stands on something");
            seen.Add(first.Value);
            queue.Enqueue(first.Value);
            while (queue.Count > 0)
            {
                (int x, int y) = queue.Dequeue();
                var next = new List<(int, int)>();
                foreach (int dx in new[] { -1, 1 })
                {
                    if (Free(x + dx, y) && Land(x + dx, y) is { } landed) next.Add(landed);
                }
                if (Ladder(x, y) && Free(x, y + 1)) next.Add((x, y + 1));
                if (map.At(x, y - 1) == Tile.Ladder && Free(x, y - 1)) next.Add((x, y - 1));
                if (Support(x, y) || Ladder(x, y))
                {
                    for (int dy = -12; dy <= 2; dy++)
                    {
                        int range = dy == 2 ? 3 : dy >= -1 ? 4 : 5;
                        for (int dx = -range; dx <= range; dx++)
                        {
                            int tx = x + dx, ty = y + dy;
                            if (!Free(tx, ty) || !Support(tx, ty)) continue;
                            int peak = Math.Max(y, ty) + 1;
                            bool clear = Enumerable.Range(y, 3).All(yy => !Solid(x, yy));
                            int step = dx >= 0 ? 1 : -1;
                            for (int xx = x; dx != 0 && xx != tx + step && clear; xx += step)
                            {
                                if (Solid(xx, peak) || Solid(xx, peak + 1)) clear = false;
                            }
                            if (clear) next.Add((tx, ty));
                        }
                    }
                }
                foreach ((int, int) n in next)
                {
                    if (seen.Add(n)) queue.Enqueue(n);
                }
            }
            return seen;
        }
    }
}

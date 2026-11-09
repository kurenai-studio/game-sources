using System.Collections.Generic;
using System.Linq;
using Codebound.Core;
using NUnit.Framework;

namespace Codebound.Tests
{
    // The Keep panel shows six watch rows. A trace that needs more would cut rows off on screen.
    public class RoomWatchRowLimitTests
    {
        const int MaxRows = 6;

        static int Rows(IReadOnlyList<TraceEvent> events)
        {
            var state = new KeepState();
            foreach (var e in events) state.Apply(e);
            return state.WatchLines().Count;
        }

        [Test]
        public void EveryRoom_FitsTheSixWatchRows()
        {
            var tooLong = new List<string>();
            foreach (var entry in KeepCatalogSeed.Create().SelectMany(c => c.rooms))
            {
                Assert.IsTrue(RoomLibrary.TryCreate(entry.id, out var room), entry.id);
                if (Rows(room.Trace) > MaxRows) tooLong.Add(entry.id + " trace");
                for (var i = 0; i < room.Fixes.Count; i++)
                    if (Rows(room.Fixes[i].Consequence) > MaxRows) tooLong.Add($"{entry.id} fix {i}");
            }

            CollectionAssert.IsEmpty(tooLong, "Too many watch rows: " + string.Join(", ", tooLong));
        }
    }
}

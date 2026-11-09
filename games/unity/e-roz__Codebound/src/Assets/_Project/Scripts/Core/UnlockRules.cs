using System;
using System.Collections.Generic;

namespace Codebound.Core
{
    public static class UnlockRules
    {
        public const int MaxStarsPerRoom = 3;

        public static int GetStars(IReadOnlyList<RoomProgress> progress, string roomId)
        {
            if (progress == null || string.IsNullOrEmpty(roomId)) return 0;

            var best = 0;
            for (var i = 0; i < progress.Count; i++)
            {
                var entry = progress[i];
                if (entry == null || entry.roomId != roomId) continue;
                best = Math.Max(best, ClampStars(entry.bestStars));
            }
            return best;
        }

        public static bool IsCompleted(IReadOnlyList<RoomProgress> progress, string roomId) =>
            GetStars(progress, roomId) >= 1;

        public static bool IsChapterComplete(KeepChapter chapter, IReadOnlyList<RoomProgress> progress)
        {
            if (chapter == null || chapter.rooms == null || chapter.rooms.Count == 0) return false;

            foreach (var room in chapter.rooms)
                if (room == null || !IsCompleted(progress, room.id)) return false;
            return true;
        }

        public static WingState GetWingState(IReadOnlyList<KeepChapter> chapters, int chapterIndex,
            IReadOnlyList<RoomProgress> progress)
        {
            if (chapters == null || chapterIndex < 0 || chapterIndex >= chapters.Count) return WingState.Sealed;

            var chapter = chapters[chapterIndex];
            if (chapter == null || chapter.isSealed) return WingState.Sealed;
            if (chapterIndex > 0 && !IsChapterComplete(chapters[chapterIndex - 1], progress)) return WingState.Locked;
            return IsChapterComplete(chapter, progress) ? WingState.Completed : WingState.Open;
        }

        public static RoomState GetRoomState(IReadOnlyList<KeepChapter> chapters, int chapterIndex, int roomIndex,
            IReadOnlyList<RoomProgress> progress)
        {
            var wing = GetWingState(chapters, chapterIndex, progress);
            if (wing == WingState.Sealed || wing == WingState.Locked) return RoomState.Locked;

            var rooms = chapters[chapterIndex].rooms;
            if (rooms == null || roomIndex < 0 || roomIndex >= rooms.Count || rooms[roomIndex] == null)
                return RoomState.Locked;

            if (IsCompleted(progress, rooms[roomIndex].id)) return RoomState.Completed;
            if (roomIndex == 0) return RoomState.Open;

            var previous = rooms[roomIndex - 1];
            return previous != null && IsCompleted(progress, previous.id) ? RoomState.Open : RoomState.Locked;
        }

        public static bool TryFindNextRoom(IReadOnlyList<KeepChapter> chapters, IReadOnlyList<RoomProgress> progress,
            out int chapterIndex, out int roomIndex)
        {
            chapterIndex = -1;
            roomIndex = -1;
            if (chapters == null) return false;

            for (var c = 0; c < chapters.Count; c++)
            {
                var rooms = chapters[c]?.rooms;
                if (rooms == null) continue;
                for (var r = 0; r < rooms.Count; r++)
                {
                    if (GetRoomState(chapters, c, r, progress) != RoomState.Open) continue;
                    chapterIndex = c;
                    roomIndex = r;
                    return true;
                }
            }
            return false;
        }

        public static int CompletedRooms(IReadOnlyList<KeepChapter> chapters, IReadOnlyList<RoomProgress> progress)
        {
            var count = 0;
            ForEachPlayableRoom(chapters, room => { if (IsCompleted(progress, room.id)) count++; });
            return count;
        }

        public static int TotalStars(IReadOnlyList<KeepChapter> chapters, IReadOnlyList<RoomProgress> progress)
        {
            var total = 0;
            ForEachPlayableRoom(chapters, room => total += GetStars(progress, room.id));
            return total;
        }

        public static int MaxStars(IReadOnlyList<KeepChapter> chapters)
        {
            var total = 0;
            ForEachPlayableRoom(chapters, _ => total += MaxStarsPerRoom);
            return total;
        }

        public static bool Record(List<RoomProgress> progress, string roomId, int stars)
        {
            if (progress == null || string.IsNullOrEmpty(roomId)) return false;

            stars = ClampStars(stars);
            if (stars == 0 || stars <= GetStars(progress, roomId)) return false;

            foreach (var entry in progress)
            {
                if (entry == null || entry.roomId != roomId) continue;
                entry.bestStars = stars;
                return true;
            }

            progress.Add(new RoomProgress { roomId = roomId, bestStars = stars });
            return true;
        }

        static int ClampStars(int stars) => Math.Max(0, Math.Min(MaxStarsPerRoom, stars));

        static void ForEachPlayableRoom(IReadOnlyList<KeepChapter> chapters, Action<KeepRoom> action)
        {
            if (chapters == null) return;
            foreach (var chapter in chapters)
            {
                if (chapter == null || chapter.isSealed || chapter.rooms == null) continue;
                foreach (var room in chapter.rooms)
                    if (room != null) action(room);
            }
        }
    }
}

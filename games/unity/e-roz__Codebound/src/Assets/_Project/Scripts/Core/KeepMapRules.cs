using System.Collections.Generic;

namespace Codebound.Core
{
    public static class KeepMapRules
    {
        public const string HiddenText = "???";

        public static string RoomLabel(int chapterIndex, int roomIndex) => $"{chapterIndex + 1}.{roomIndex + 1}";

        public static string DisplayTitle(KeepRoom room, RoomState state) =>
            state == RoomState.Locked ? HiddenText : room.title;

        public static string DisplayType(KeepRoom room, RoomState state) =>
            state == RoomState.Locked ? HiddenText : room.roomType;

        public static string DisplayConcept(KeepRoom room, RoomState state) =>
            state == RoomState.Locked ? HiddenText : room.concept;

        public static string RoomStatus(RoomState state, int stars)
        {
            switch (state)
            {
                case RoomState.Completed: return stars == 1 ? "1 star" : $"{stars} stars";
                case RoomState.Open: return "Next";
                default: return "Locked";
            }
        }

        public static string WingStatus(IReadOnlyList<KeepChapter> chapters, int chapterIndex,
            IReadOnlyList<RoomProgress> progress)
        {
            switch (UnlockRules.GetWingState(chapters, chapterIndex, progress))
            {
                case WingState.Sealed:
                    return "Sealed, coming soon";
                case WingState.Locked:
                    var previous = chapters[chapterIndex - 1];
                    return $"Locked: finish {previous.name}";
                default:
                    var chapter = chapters[chapterIndex];
                    var done = 0;
                    foreach (var room in chapter.rooms)
                        if (room != null && UnlockRules.IsCompleted(progress, room.id)) done++;
                    return $"{done} / {chapter.rooms.Count} rooms";
            }
        }

        public static bool IsMvpComplete(IReadOnlyList<KeepChapter> chapters, IReadOnlyList<RoomProgress> progress)
        {
            var playable = 0;
            foreach (var chapter in chapters)
            {
                if (chapter == null || chapter.isSealed) continue;
                playable++;
                if (!UnlockRules.IsChapterComplete(chapter, progress)) return false;
            }
            return playable > 0;
        }

        public static string TalaLine(string playerName, int completedRooms, bool mvpComplete)
        {
            if (mvpComplete) return $"You fixed the Keep, {playerName}. It will break again tomorrow. Replay any room for more stars.";
            if (completedRooms == 0) return $"Pick a wing, {playerName}. Start with The Vaults.";
            return $"Welcome back, {playerName}. Your next room is ready.";
        }
    }
}

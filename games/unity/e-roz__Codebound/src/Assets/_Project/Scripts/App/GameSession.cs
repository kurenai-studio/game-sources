using UnityEngine;

namespace Codebound.App
{
    // Small hand-over between scenes: which room to open, and whether the menu should open on the Keep Map.
    public static class GameSession
    {
        public static string SelectedRoomId { get; private set; }
        static bool _returnToKeep;

        public static void SelectRoom(string roomId) => SelectedRoomId = roomId;

        public static void RequestReturnToKeep() => _returnToKeep = true;

        public static bool ConsumeReturnToKeep()
        {
            var value = _returnToKeep;
            _returnToKeep = false;
            return value;
        }

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.SubsystemRegistration)]
        static void Reset()
        {
            SelectedRoomId = null;
            _returnToKeep = false;
        }
    }
}

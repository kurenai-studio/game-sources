using System;
using System.Collections.Generic;

namespace Codebound.Core
{
    [Serializable]
    public class PlayerSave
    {
        public const int CurrentVersion = 1;

        public int version = CurrentVersion;
        public string playerName;
        public int lookId;
        // Set once the player has seen the ending (old saves have no such field and read as false).
        public bool endingSeen;
        public List<RoomProgress> progress = new List<RoomProgress>();

        public bool IsValid() => version >= 1 && !string.IsNullOrWhiteSpace(playerName);

        public void EnsureProgress()
        {
            if (progress == null) progress = new List<RoomProgress>();
        }
    }
}

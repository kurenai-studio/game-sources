using System;
using System.Collections.Generic;

namespace Codebound.Core
{
    [Serializable]
    public class KeepRoom
    {
        public string id;
        public string title;
        public string roomType;
        public string concept;
    }

    [Serializable]
    public class KeepChapter
    {
        public string id;
        public string name;
        public bool isSealed;
        public List<KeepRoom> rooms = new List<KeepRoom>();
    }

    [Serializable]
    public class RoomProgress
    {
        public string roomId;
        public int bestStars;
    }

    public enum RoomState
    {
        Locked,
        Open,
        Completed
    }

    public enum WingState
    {
        Sealed,
        Locked,
        Open,
        Completed
    }
}

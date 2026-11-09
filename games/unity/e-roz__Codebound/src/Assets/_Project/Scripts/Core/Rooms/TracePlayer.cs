using System;
using System.Collections.Generic;

namespace Codebound.Core
{
    public sealed class TracePlayer
    {
        readonly IReadOnlyList<TraceEvent> _events;

        public TracePlayer(IReadOnlyList<TraceEvent> events)
        {
            _events = events ?? throw new ArgumentNullException(nameof(events));
        }

        public event Action<TraceEvent> EventPlayed;
        public event Action WasReset;

        public IReadOnlyList<TraceEvent> Events => _events;
        public int Position { get; private set; }
        public bool HasNext => Position < _events.Count;

        public TraceEvent Step()
        {
            if (!HasNext) return null;

            var played = _events[Position++];
            EventPlayed?.Invoke(played);
            return played;
        }

        public void RunToEnd()
        {
            while (HasNext) Step();
        }

        public void Reset()
        {
            Position = 0;
            WasReset?.Invoke();
        }
    }
}

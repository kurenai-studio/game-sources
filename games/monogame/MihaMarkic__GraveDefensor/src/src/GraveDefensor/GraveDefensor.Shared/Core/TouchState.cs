using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Input.Touch;

namespace GraveDefensor.Shared.Core
{
    public readonly struct TouchState
    {
        public TouchCollection Collection { get;  }
        public int? TrackingId { get; }
        public TouchLocationState? State { get; }
        public Point? Position { get; }

        public TouchState(TouchCollection collection, int? trackingId)
        {
            TrackingId = trackingId;
            State = null;
            Position = null;
            Collection = collection;
            if (trackingId.HasValue)
            {
                foreach (var tc in Collection)
                {
                    if (tc.Id == trackingId)
                    {
                        State = tc.State;
                        Position = tc.Position.AsPoint();
                        break;
                    }
                }
                if (!State.HasValue)
                {
                    TrackingId = null;
                }
            }
            else
            {
                foreach (var tc in Collection)
                {
                    if (tc.State == TouchLocationState.Pressed)
                    {
                        TrackingId = tc.Id;
                        State = tc.State;
                        Position = tc.Position.AsPoint();
                    }
                }
            }
        }
    }
}

using System;

namespace MonoGameLibrary.Components
{
    public struct Timer(long durationTicks, bool shouldRepeat)
    {
        public long DurationTicks = durationTicks;
        public long RemainingTicks = durationTicks;
        public bool ShouldRepeat = shouldRepeat;

        public readonly bool HasElapsed => RemainingTicks <= 0;
        
        public void Restart(TimeSpan duration)
        {
            DurationTicks = duration.Ticks;
            RemainingTicks = DurationTicks;
        }

        public void Stop()
        {
            RemainingTicks = 0;
        }
    }
}

using System;

namespace GraveDefensor.Engine.Core
{
    public abstract class Action
    {
        public TimeSpan Begin { get; private set; }
        public TimeSpan Duration { get; private set; }
        public TimeSpan Expiration { get; private set; }
        public bool HasExpired { get; protected set; } = true;
        bool willExpire;
        protected void Start(TimeSpan currentTime, TimeSpan duration)
        {
            willExpire = false;
            HasExpired = false;
            Begin = currentTime;
            Duration = duration;
            Expiration = currentTime + duration;
        }
        public void Update(TimeSpan totalGameTime)
        {
            if (willExpire)
            {
                HasExpired = true;
            }
            else if (!HasExpired)
            {
                if (totalGameTime > Expiration)
                {
                    willExpire = true;
                    Update(1.0f);
                }
                else
                {
                    var difference = totalGameTime - Begin;
                    double percentage = difference.TotalMilliseconds / Duration.TotalMilliseconds;
                    Update(percentage);
                }
            }
        }
        public virtual void Update(double percentage)
        { }
    }
}

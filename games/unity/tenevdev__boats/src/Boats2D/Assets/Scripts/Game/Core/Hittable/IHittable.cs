using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Assets.Scripts.Game.Core
{
    public interface IHittable
    {
        int HitPoints { get; set; }
        void ReceiveHit(Hittable hitter);
        event HitReceivedEventHandler HitReceived;
    }

    public delegate void HitReceivedEventHandler(Hittable sender, HitEventArgs args);
}

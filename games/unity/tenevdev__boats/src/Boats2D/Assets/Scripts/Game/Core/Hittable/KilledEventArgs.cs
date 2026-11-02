using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Assets.Scripts.Game.Core
{
    public class KilledEventArgs : DeadEventArgs
    {
        public KilledEventArgs(Hittable killer) : base(DeadReason.Killed)
        {
            this.Killer = killer;
        }

        public Hittable Killer { get; set; }
    }
}

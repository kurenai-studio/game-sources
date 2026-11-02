using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Assets.Scripts.Game.Core
{
    public class DeadEventArgs : EventArgs
    {
        public DeadEventArgs(DeadReason reason)
        {
            this.Reason = reason;
        }

        public DeadReason Reason { get; set; }
    }

    public enum DeadReason
    {
        Unknown = 0,
        OutOfScene = 1,
        Killed = 2
    }
}

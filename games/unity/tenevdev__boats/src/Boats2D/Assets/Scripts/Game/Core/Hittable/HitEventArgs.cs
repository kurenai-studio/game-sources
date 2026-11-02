using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Assets.Scripts.Game.Core
{
    public class HitEventArgs
    {
        public HitEventArgs(int hpStart, int hpLeft, Hittable hitter)
        {
            this.HitPointsLeft = hpLeft;
            this.HitPointsPercent = (float)hpLeft / hpStart;
            this.Hitter = hitter;
        }

        public int HitPointsLeft { get; set; }
        public float HitPointsPercent { get; set; }
        public Hittable Hitter { get; set; }
    }
}

using Microsoft.Xna.Framework;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BeeGameMaster
{
    public interface Dies
    {
        bool IsDead { get; set; }
        Rectangle Rect { get; set; }
        int Health { get; set; }
    }
}

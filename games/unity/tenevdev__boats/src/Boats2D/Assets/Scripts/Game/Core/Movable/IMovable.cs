using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Assets.Scripts.Game.Core
{
    public interface IMovable
    {
        void Destroy(Movable sender, DeadEventArgs args);
        event DeadEventHandler Dead;
    }

    public delegate void DeadEventHandler(Movable sender, DeadEventArgs args);
}

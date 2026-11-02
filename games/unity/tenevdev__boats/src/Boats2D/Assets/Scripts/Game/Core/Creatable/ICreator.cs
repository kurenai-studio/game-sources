using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEngine;

namespace Assets.Scripts.Game.Core
{
    interface ICreator
    {
        IEnumerator Run();
        UnityEngine.Object Create();
    }
}

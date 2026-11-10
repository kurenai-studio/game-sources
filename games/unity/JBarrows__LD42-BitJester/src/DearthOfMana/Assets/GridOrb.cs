using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;

public abstract class GridOrb : UIBehaviour
{
    public int Column { get; set; }
    public int Row { get; set; }

    /// <summary>
    ///-1: Dead
    /// 0: Red
    /// 1: yellow
    /// 2: Green
    /// 3: Cyan
    /// 4: Blue
    /// 5: Magenta
    /// </summary>
    /// <value>
    public int OrbTypeID { get; set; }
}
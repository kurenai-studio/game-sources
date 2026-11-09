using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PlayerBlueController : PlayerControllerBase
{
    protected override void Start()
    {
        base.Start();
        moveUpKey = KeyCode.UpArrow;
        moveDownKey = KeyCode.DownArrow;
        rotateRightKey = KeyCode.RightArrow;
        rotateLeftKey = KeyCode.LeftArrow;
        trickKey = KeyCode.RightShift;
    }
}

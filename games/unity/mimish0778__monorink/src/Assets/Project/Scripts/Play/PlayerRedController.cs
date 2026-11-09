using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PlayerRedController : PlayerControllerBase
{
    protected override void Start()
    {
        base.Start();
        moveUpKey = KeyCode.W;
        moveDownKey = KeyCode.S;
        rotateRightKey = KeyCode.D;
        rotateLeftKey = KeyCode.A;
        trickKey = KeyCode.Space;
    }
}

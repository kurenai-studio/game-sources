using UnityEngine;
using System.Collections.Generic;
using System;

public class CollisionChecker: MonoBehaviour
{
    public Action<Collision2D> collisionEnter = x => { };
    public Action<Collision2D> collisionExit = x => { };

    void OnCollisionEnter2D(Collision2D collision)
    {
        collisionEnter(collision);
    }

    void OnCollisionExit2D(Collision2D collision)
    {
        collisionExit(collision);
    }
}

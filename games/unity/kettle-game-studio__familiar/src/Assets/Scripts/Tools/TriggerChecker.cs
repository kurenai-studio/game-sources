using System;
using UnityEngine;
using System.Collections.Generic;

public class TriggerChecker: MonoBehaviour
{
    public HashSet<Collider2D> triggered = new();
    public Action<Collider2D> triggerEnter = x => { };
    public Action<Collider2D> triggerExit = x => { };

    void OnTriggerEnter2D(Collider2D col)
    {
        triggered.Add(col);
        triggerEnter(col);
    }

    void OnTriggerExit2D(Collider2D col)
    {
        triggered.Remove(col);
        triggerExit(col);
    }

    public bool isTriggered() {
        return triggered.Count > 0;
    }
}

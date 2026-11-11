using System;
using UnityEngine;


public class ControllerSettings: ScriptableObject
{
    public virtual IController Construct() { return null; }
}

public interface IController
{
    bool Enabled { set; }
    void Iterate(ControlState state);
}

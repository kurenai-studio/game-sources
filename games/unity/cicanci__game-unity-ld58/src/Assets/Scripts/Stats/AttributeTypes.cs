using UnityEngine;
using System;

[Flags]
public enum AttributeTypes
{
    None            = 0,
    FireAttack      = 1 << 0,
    FireResistence  = 1 << 1,
    IceAttack       = 1 << 2,
    IceResistence   = 1 << 3,
}

using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public interface IEnemy
{
    double Health { get; }
    double TotalHealth { get; }

    void RecieveHit(double damage);
}

using UnityEngine;
using System.Collections;

public class VurnableShipSpot : ShipHealth {

    ShipHealth ship;

    void Awake()
    {
        ship = transform.parent.GetComponent<ShipHealth>();
        if (ship == null)
            ship = transform.parent.GetComponentInParent<ShipHealth>();
    }

    public override float Health
    {
        get
        {
            return ship.Health;
        }
        set
        {
            ship.Health = value;
        }
    }

    public override bool Enemy
    {
        get
        {
            return ship.Enemy;
        }
        set
        {
            ship.Enemy = value;
        }
    }
}

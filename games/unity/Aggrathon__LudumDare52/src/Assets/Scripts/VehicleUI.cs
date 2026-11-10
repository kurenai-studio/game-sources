using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class VehicleUI : MonoBehaviour
{

    public Vehicle vehicle;

    public Image[] gears;
    public Color activeGearColor = Color.yellow;
    public Color inactiveGearColor = Color.white;
    public DoubleEndedMeter speedometer;
    public DoubleEndedMeter steeringWheel;

    int gear;

    private void Start()
    {
        foreach (var g in gears)
        {
            g.color = inactiveGearColor;
        }
        gear = 0;
        Debug.Assert(gears.Length == vehicle.forwardGears + vehicle.reverseGears + 1);
    }

    void Update()
    {
        speedometer.value = vehicle.gear > 0 ? vehicle.gear / vehicle.forwardGears : vehicle.gear / vehicle.reverseGears;
        steeringWheel.value = vehicle.turn;
        var newgear = (int)vehicle.targetGear + vehicle.reverseGears;
        if (newgear != gear)
        {
            gears[gear].color = inactiveGearColor;
            gears[newgear].color = activeGearColor;
            gear = newgear;
        }
    }
}

using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using TMPro;

public class VictoryUI : MonoBehaviour
{

    public Field field;

    private void Start()
    {
        var text = GetComponentInChildren<TextMeshProUGUI>();
        text.text = string.Format(
            text.text,
            Mathf.RoundToInt(Time.timeSinceLevelLoad),
            Mathf.RoundToInt((float)field.HarvestedCrops * 100f / field.TotalCrops),
            Mathf.RoundToInt(Time.timeSinceLevelLoad / ((float)field.HarvestedCrops / field.TotalCrops))
        );
        // You completed the course in {:d} seconds
        // and harvested {:d %} of the crops.
        // Final time: {:d} seconds!
    }
}

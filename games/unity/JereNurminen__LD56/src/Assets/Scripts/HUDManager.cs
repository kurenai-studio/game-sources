using System.Linq;
using NUnit.Framework.Constraints;
using Unity.Collections;
using Unity.VisualScripting.Dependencies.NCalc;
using UnityEngine;
using UnityEngine.UI;

public class HUDManager : MonoBehaviour
{
    private SheepController[] sheepControllers;
    private int initialSheepCount = 0;
    private SheepIcon[] sheepIcons;

    private
    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start()
    {
        sheepControllers = FindObjectsByType<SheepController>(FindObjectsSortMode.None);
        sheepIcons = FindObjectsByType<SheepIcon>(FindObjectsSortMode.None);

        initialSheepCount = sheepControllers.Length;
    }

    // Update is called once per frame
    void Update()
    {
        var deadSheepCount = sheepControllers.Count(sheepController => !sheepController.isAlive);
        var successSheepCount = sheepControllers.Count(
            sheepController => sheepController.isSuccess
        );

        foreach (var sheepIcon in sheepIcons)
        {
            if (sheepIcon.id < initialSheepCount)
            {
                if (sheepIcon.id < deadSheepCount)
                {
                    sheepIcon.SetState(SheepIconState.Dead);
                }
                else if (sheepIcon.id < deadSheepCount + successSheepCount)
                {
                    sheepIcon.SetState(SheepIconState.Success);
                }
                else
                {
                    sheepIcon.SetState(SheepIconState.Default);
                }
            }
        }
    }
}

using UnityEngine;


public class HomeBottlePhase : BattlePhase
{
    public Transform[] bottles;

    void Update()
    {
        foreach (Transform bottle in bottles)
            if (bottle != null)
                return;
        phaseOver = true;
    }
}

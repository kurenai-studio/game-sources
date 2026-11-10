using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class MilkDisplay : MonoBehaviour
{
    // Update is called once per frame
    void Update()
    {
        if (PlayerManager.Inst.unlocked_milk)
            GetComponent<Text>().text = PlayerManager.Inst.milk.ToString("N0") + " Cartons of Milk";
    }
}

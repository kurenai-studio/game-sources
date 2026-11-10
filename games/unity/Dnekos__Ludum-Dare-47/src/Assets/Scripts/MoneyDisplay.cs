using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class MoneyDisplay : MonoBehaviour
{
    void Update()
    {
        GetComponent<Text>().text = PlayerManager.Inst.money.ToString("C");
    }
}

using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MessageWindow : MonoBehaviour
{
    public TMPro.TextMeshProUGUI prefab;

    public void Alert(string msg) {
        Instantiate(prefab, transform).text = msg;
    }
}

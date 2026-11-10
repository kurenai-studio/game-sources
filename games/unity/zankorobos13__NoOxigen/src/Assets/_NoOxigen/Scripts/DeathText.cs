using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using TMPro;

public class DeathText : MonoBehaviour
{
    
    void Start()
    {
        gameObject.GetComponent<TextMeshProUGUI>().text = G.death_msg;
    }

    
}

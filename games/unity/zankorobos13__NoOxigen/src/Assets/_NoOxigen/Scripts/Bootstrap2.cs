using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Bootstrap2 : MonoBehaviour
{
    void Awake()
    {
        G.ClearAllEvents();
        gameObject.GetComponent<Main2>().OnBreakingUpdated(); 
    }
}

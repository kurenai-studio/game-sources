using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class StartupActiveState : MonoBehaviour
{
    public List<GameObject> shouldBeActive;
    public List<GameObject> shouldBeInactive;

    void Start()
    {
        foreach (var go in shouldBeActive)
        {
            go.SetActive(true);
        }
        foreach (var go in shouldBeInactive)
        {
            go.SetActive(false);
        }
        enabled = false;
    }
}

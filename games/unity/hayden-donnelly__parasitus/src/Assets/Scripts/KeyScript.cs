using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class KeyScript : MonoBehaviour
{
    [SerializeField] private DoorScript doorScript;

    private void Start()
    {
        doorScript.Lock();
    }

    public void Pickup()
    {
        doorScript.Unlock();
        Destroy(gameObject);
    }
}

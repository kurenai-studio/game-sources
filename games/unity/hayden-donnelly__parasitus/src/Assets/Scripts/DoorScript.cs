using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DoorScript : MonoBehaviour
{
    [SerializeField] private Transform doorTarget;
    private bool locked = false;

    public bool IsLocked()
    {
        return locked;
    }

    public Transform GetDoorTarget()
    {
        return doorTarget;
    }

    public void Lock()
    {
        locked = true;
    }

    public void Unlock()
    {
        locked = false;
    }
}

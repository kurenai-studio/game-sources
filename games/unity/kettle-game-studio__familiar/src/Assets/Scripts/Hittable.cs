using System;
using UnityEngine;

public class Hittable : MonoBehaviour
{
    [HideInInspector]
    public Action<Transform> callback = from => { };

    public void Hit(Transform from)
    {
        callback(from);
    }
}

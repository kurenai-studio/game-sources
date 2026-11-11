using System;
using UnityEngine;
using UnityEngine.Events;

public class Stompable : MonoBehaviour
{
    public UnityEvent OnStomp;
    public bool bouncy = false;
    public float bounceForce = 100f;
}

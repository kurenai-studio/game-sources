using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(Collider))]
public class Portal : MonoBehaviour
{

    private void OnTriggerEnter(Collider other)
    {
        other.attachedRigidbody?.GetComponent<PlayerController>()?.Victory();
    }
}

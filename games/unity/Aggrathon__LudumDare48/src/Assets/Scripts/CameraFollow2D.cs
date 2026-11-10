using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraFollow2D : MonoBehaviour
{
    public Transform target;

    public float smoothTime = 0.5f;

    Vector3 velocity;

    void Update()
    {
        Vector3 goal = target.position;
        goal.z = transform.position.z;
        transform.position = Vector3.SmoothDamp(transform.position, goal, ref velocity, smoothTime);
    }
}

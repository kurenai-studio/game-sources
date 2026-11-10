using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(Rigidbody))]
public class Vehicle : MonoBehaviour
{
    Rigidbody rb;

    [Header("Movement")]

    public int forwardGears = 3;
    public int reverseGears = 1;

    public float speed = 1f;
    public float speedChange = 1f;
    public float turning = 45f;
    public float turningChange = 1f;

    public float targetGear { get; protected set; }
    public float targetTurn { get; protected set; }

    public float gear { get; protected set; }
    public float turn { get; protected set; }

    public void Forward()
    {
        targetGear = Mathf.Min(forwardGears, targetGear + 1);
    }

    public void Reverse()
    {
        targetGear = Mathf.Max(-reverseGears, targetGear - 1);
    }

    public void Steer(float amount)
    {
        targetTurn = Mathf.Clamp(amount, -1, 1);
    }

    private void Start()
    {
        rb = GetComponent<Rigidbody>();
        targetGear = 0f;
        targetTurn = 0f;
        turn = 0f;
        gear = 0f;
    }


    private void FixedUpdate()
    {
        if (targetGear != gear)
        {
            gear = Mathf.MoveTowards(gear, targetGear, Time.deltaTime * speedChange);
        }
        if (targetTurn != turn)
        {
            turn = Mathf.MoveTowards(turn, targetTurn, Time.deltaTime * turningChange);
        }

        var rot = rb.rotation;
        var pos = rb.position;

        rot *= Quaternion.AngleAxis(turn * turning * Time.deltaTime * Mathf.Clamp(gear, -1, 1), rot * Vector3.up);
        pos += rot * Vector3.forward * (gear * speed * Time.deltaTime);
        rb.MovePosition(pos);
        rb.MoveRotation(rot);
    }
}

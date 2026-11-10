using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(Vehicle))]
public class VehicleAudio : MonoBehaviour
{

    public AudioSource engineAudio;
    [Min(0)] public float enginePitch = 0.1f;
    [Min(0)] public float engineVolume = 0.1f;
    public AudioSource gearAudio;
    [Min(0)] public float gearPitch = 0.05f;
    public AudioSource steeringAudio;
    [Min(0)] public float steeringPitch = 0.1f;

    Vehicle vehicle;
    float lastGear;
    float lastTurn;

    private void Start()
    {
        vehicle = GetComponent<Vehicle>();
        lastGear = vehicle.targetGear;
        lastTurn = vehicle.turn;
    }

    void Update()
    {
        var speed = Mathf.Abs(vehicle.gear);
        engineAudio.pitch = 1f + (speed - 1) * enginePitch;
        engineAudio.volume = 1f + (speed - vehicle.forwardGears) * engineVolume;

        if (lastGear != vehicle.targetGear)
        {
            lastGear = vehicle.targetGear;
            if (!gearAudio.isPlaying)
            {
                gearAudio.pitch = Random.Range(1 - gearPitch, 1 + gearPitch);
                gearAudio.Play();
            }
        }

        if (Mathf.Abs(lastTurn - vehicle.turn) > 0.1f)
        {
            lastTurn = vehicle.turn;
            if (steeringAudio.enabled && !steeringAudio.isPlaying)
            {
                steeringAudio.pitch = Random.Range(1 - steeringPitch, 1 + steeringPitch);
                steeringAudio.Play();
            }
        }
    }
}

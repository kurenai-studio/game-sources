using UnityEngine;
using System.Collections;

public class HangarLauncher : MonoBehaviour {

    public GameObject fighter;
    public GameObject launchPoint;
    public float launchSpeed = 30f;

    void OnEnable()
    {
        fighter.transform.position = launchPoint.transform.position;
        fighter.transform.rotation = launchPoint.transform.rotation;
        Rigidbody rig = fighter.GetComponent<Rigidbody>();
        rig.AddForce(fighter.transform.forward*launchSpeed, ForceMode.VelocityChange);
        rig.AddTorque(Vector3.zero, ForceMode.VelocityChange);
    }
}

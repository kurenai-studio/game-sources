using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Cinemachine;

public class CameraController : MonoBehaviour
{
    public static CameraController active { get; protected set; }

    public CinemachineVirtualCamera topCamera;
    public CinemachineVirtualCamera shoulderCamera;
    public CinemachineVirtualCamera overCamera;
    public CinemachineBrain cameraBrain;

    public Transform activeUnit;

    Transform target;

    public float turnSpeed = 1f;
    public float moveSpeed = 10f;

    enum State {
        shoulder,
        over,
        top
    }

    State state;

    void Start()
    {
        var go = new GameObject();
        go.name = "Camera Target";
        target = go.transform;
        target.parent = transform;
        overCamera.Follow = target;
        active = this;
    }

    void Update() {
        if (state == State.shoulder) {
            if (Input.GetMouseButton(1))
                shoulderCamera.transform.Rotate(Vector3.up, -Input.GetAxis("Mouse X") * turnSpeed);
            if (Input.GetKeyUp(KeyCode.Tab))
                FocusOver();
            if (Input.GetKeyUp(KeyCode.Space))
                shoulderCamera.transform.Rotate(0f, 90f, 0f, Space.World);
        } else if (state == State.over) {
            if (Input.GetKeyUp(KeyCode.Tab))
                FocusShoulder();
            if (Input.GetKeyUp(KeyCode.Space))
                FocusOver();
            if (Input.GetMouseButton(1))
                overCamera.transform.Rotate(0f, -Input.GetAxis("Mouse X") * turnSpeed, 0f, Space.World);
            float rotation = overCamera.transform.rotation.eulerAngles.y;
            Vector3 dir = new Vector3(Input.GetAxis("Horizontal"), 0f, Input.GetAxis("Vertical"));
            target.position += Quaternion.Euler(0f, rotation, 0f) * dir * (Time.deltaTime * moveSpeed);
        } else {
            if (Input.GetMouseButton(1))
                topCamera.transform.Rotate(0f, -Input.GetAxis("Mouse X") * turnSpeed, 0f, Space.World);
        }
    }


    public void FocusShoulder(Transform tracker = null) {
        if (tracker != null)
            activeUnit = tracker;
        shoulderCamera.Follow = activeUnit;
        shoulderCamera.transform.rotation = Quaternion.Euler(0f, overCamera.transform.rotation.eulerAngles.y, 0f);
        topCamera.Priority = 0;
        overCamera.Priority = 0;
        shoulderCamera.Priority = 10;
        state = State.shoulder;
    }

    public void FocusTop(Transform tracker = null) {
        if (tracker != null)
            activeUnit = tracker;
        topCamera.Follow = activeUnit;
        topCamera.transform.rotation = Quaternion.Euler(80f, overCamera.transform.rotation.eulerAngles.y, 0f);
        topCamera.Priority = 10;
        overCamera.Priority = 0;
        shoulderCamera.Priority = 0;
        state = State.top;
    }

    public void FocusOver(Transform tracker = null) {
        if (tracker != null)
            activeUnit = tracker;
        target.position = activeUnit.position;
        topCamera.Priority = 0;
        overCamera.Priority = 10;
        shoulderCamera.Priority = 0;
        state = State.over;
    }
}

using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraController : MonoBehaviour
{
    public Vector3 kCameraOffset = new Vector3(0, -3, -10);
    private GameObject mPlayer;
    private Vector3 mVelocity = Vector3.zero;

    // Use this for initialization
    private void Start()
    {
        mPlayer = GameObject.Find("Player");
    }

    private void FixedUpdate()
    {
        // For some reason this works by splitting up Y and X/Z movement for the camera so #CLAMJAM
        // Move toward the player
        Vector3 targetPosition = (mPlayer.transform.position + kCameraOffset);
        Debug.DrawLine(transform.position, targetPosition, Color.yellow);
        Vector3 moveEase = (targetPosition - transform.position) * 0.25f;
        moveEase.y = 0;
        //transform.position = Vector3.SmoothDamp(transform.position, targetPosition, ref mVelocity, 0.1f);
        transform.Translate(moveEase);
    }

    // Update is called once per frame
    private void LateUpdate()
    {
        // Move toward the player
        Vector3 targetPosition = (mPlayer.transform.position + kCameraOffset);
        Debug.DrawLine(transform.position, targetPosition, Color.yellow);
        Vector3 moveEase = (targetPosition - transform.position) * 0.25f;
        moveEase.x = moveEase.z = 0;
        //transform.position = Vector3.SmoothDamp(transform.position, targetPosition, ref mVelocity, 0.1f);
        transform.Translate(moveEase);
    }
}
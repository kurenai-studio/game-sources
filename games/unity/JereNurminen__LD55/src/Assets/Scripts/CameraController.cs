using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraController : MonoBehaviour
{
    public GameObject player;
    public Vector3 offset;
    public float speed;
    public Vector2 bossFightPosition;
    public bool shouldFollowPlayer = true;

    private Vector3 targetPosition;

    // Start is called before the first frame update
    void Start() { }

    void UpdateTargetPosition()
    {
        var flippedOffset = new Vector3(offset.x * player.transform.localScale.x, offset.y, -10);
        targetPosition =
            new Vector3(player.transform.position.x, player.transform.position.y, -10)
            + flippedOffset;
    }

    public void LockToArena()
    {
        shouldFollowPlayer = false;
        targetPosition = new Vector3(bossFightPosition.x, bossFightPosition.y, -10);
    }

    // Update is called once per frame
    void FixedUpdate()
    {
        if (shouldFollowPlayer)
        {
            UpdateTargetPosition();
        }
        transform.position = Vector3.Lerp(transform.position, targetPosition, speed);
    }
}

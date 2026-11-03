
using UnityEngine;

public class CameraFollow : MonoBehaviour
{
    public Transform player;
    public float speed = 5f;

    void LateUpdate()
    {
        if (player.position.y > transform.position.y)
        {
            Vector3 newPosition = new Vector3(
                transform.position.x,
                player.position.y,
                transform.position.z
            );

            transform.position = Vector3.Lerp(
                transform.position,
                newPosition,
                speed * Time.deltaTime
            );
        }
    }
}

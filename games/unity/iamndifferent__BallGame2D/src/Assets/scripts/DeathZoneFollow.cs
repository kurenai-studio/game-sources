
using UnityEngine;

public class DeathZoneFollow : MonoBehaviour
{
    public Transform player;
    public float distanceBelowPlayer = 8f;

    void Update()
    {
        float targetY = player.position.y - distanceBelowPlayer;

        if (targetY > transform.position.y)
        {
            transform.position = new Vector3(
                transform.position.x,
                targetY,
                transform.position.z
            );
        }
    }
}

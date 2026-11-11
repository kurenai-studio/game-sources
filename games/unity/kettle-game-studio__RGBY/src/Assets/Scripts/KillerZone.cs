using UnityEngine;

public class KillerZone : MonoBehaviour
{
    void OnTriggerExit(Collider other) {
        var player = other.gameObject.GetComponent<PlayerController>();
        if (player != null)
            player.Die();
    }
}

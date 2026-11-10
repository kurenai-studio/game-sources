using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PlayerHeadCollision : MonoBehaviour {

    [SerializeField]
    Player player;

    private void OnCollisionEnter2D(Collision2D collision) {
        if (collision.gameObject.tag == "Box") {
            if (collision.relativeVelocity.magnitude > 5) {
                player.Kill("head");
            }
        }
    }
}

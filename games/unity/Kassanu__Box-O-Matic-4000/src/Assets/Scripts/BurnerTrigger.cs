using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BurnerTrigger : MonoBehaviour {

    [SerializeField]
    Game game;

    [SerializeField]
    Burner burner;

    private void OnTriggerEnter2D(Collider2D other) {
        burner.triggerFlameBurst();
        if (other.tag == "Player") {
            other.GetComponent<Player>().Kill("burner");
        } else {
            if (other.tag == "Box") {
                this.game.BoxBurned();
            }
            Destroy(other.gameObject);
        }
        print("Trigger Entered");
    }

}
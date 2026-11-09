using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Court : MonoBehaviour {

    private void OnCollisionEnter(Collision collision) {
        if (collision.gameObject.tag == "Ball") {

        }
    }
}

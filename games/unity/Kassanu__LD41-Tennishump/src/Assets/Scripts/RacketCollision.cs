using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RacketCollision : MonoBehaviour {

    Racket parentRacket;

    private void Awake() {
        this.parentRacket = GetComponentInParent<Racket>();
    }

    private void OnCollisionEnter(Collision collision) {
        this.parentRacket.OnChildCollisionEnter(collision);
    }
}

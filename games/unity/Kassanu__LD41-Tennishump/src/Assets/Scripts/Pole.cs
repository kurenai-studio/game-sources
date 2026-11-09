using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Pole : MonoBehaviour {

    private AudioSource audioSource;
    [SerializeField] private AudioClip poleHit;

    private void Awake() {
        this.audioSource = GetComponent<AudioSource>();
    }

    private void OnCollisionEnter(Collision collision) {
        if (collision.gameObject.tag == "Ball") {
            this.audioSource.Stop();
            this.audioSource.PlayOneShot(this.poleHit);
        }
    }

}

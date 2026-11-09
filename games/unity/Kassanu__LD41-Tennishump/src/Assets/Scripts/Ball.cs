using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Ball : MonoBehaviour {

    private AudioSource audioSource;
    [SerializeField] private AudioClip ballBounce;

    [SerializeField] bool active = false;
    public bool Active
    {
        get
        {
            return active;
        }

        set
        {
            active = value;
        }
    }

    private void Awake() {
        this.audioSource = GetComponent<AudioSource>();
    }

    private void OnCollisionEnter(Collision collision) {
        this.audioSource.Stop();
        this.audioSource.PlayOneShot(this.ballBounce);
    }
}

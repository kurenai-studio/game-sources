using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;

[RequireComponent(typeof(Collider))]
[RequireComponent(typeof(AudioSource))]
public class Tresher : MonoBehaviour
{
    AudioSource audioSource;

    private void Start()
    {
        audioSource = GetComponent<AudioSource>();
    }

    public bool Harvest()
    {
        // TODO: harvest FX
        if (!audioSource.isPlaying)
            audioSource.Play();
        return true;
    }

}

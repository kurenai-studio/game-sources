using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(AudioSource))]
public class PlayerAudio : MonoBehaviour
{

    public List<AudioClip> errorSounds;
    public List<AudioClip> moveSounds;
    public List<AudioClip> alertSounds;

    AudioSource audioSource;

    void Start()
    {
        audioSource = GetComponent<AudioSource>();
    }


    public void PlayError()
    {
        audioSource.pitch = Random.Range(0.9f, 1.1f);
        audioSource.PlayOneShot(errorSounds.Sample());
    }

    public void PlaySteps()
    {
        audioSource.pitch = Random.Range(0.9f, 1.1f);
        audioSource.PlayOneShot(moveSounds.Sample());
    }

    public void PlayAlert()
    {
        audioSource.pitch = Random.Range(0.9f, 1.1f);
        audioSource.PlayOneShot(alertSounds.Sample());
    }
}

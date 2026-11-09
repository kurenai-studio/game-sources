using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MusicButton : MonoBehaviour
{

    public AudioSource audioSource;
    
    void Start()
    {
        DontDestroyOnLoad(gameObject);
    }
    
    public void OnMusicClick() {
        if (audioSource.isPlaying)
            audioSource.Pause();
        else
            audioSource.Play();
    }
}

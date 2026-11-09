using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class AudioManager : MonoBehaviour
{
    AudioSource[] sources;

    private void Awake()
    {
        sources = GetComponentsInChildren<AudioSource>();
    }

    public void Play(Vector3 position, int index)
    {
        if (index >= 0 && index < sources.Length)
        {
            sources[index].transform.position = position;
            sources[index].Play();
        }
    }
}

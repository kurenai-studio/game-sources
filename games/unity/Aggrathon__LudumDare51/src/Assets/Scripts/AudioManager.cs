using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class AudioManager : MonoBehaviour
{
    Queue<AudioSource> sources;

    void Start()
    {
        var source = GetComponentInChildren<AudioSource>();
        sources = new Queue<AudioSource>();
        sources.Enqueue(source);
    }

    AudioSource GetSource(bool variation)
    {
        var source = sources.Dequeue();
        if (source.isPlaying)
        {
            sources.Enqueue(source);
            source = Instantiate(source, transform);
        }
        if (variation)
        {
            source.pitch = Random.Range(0.85f, 1.2f);
            source.panStereo = Random.Range(-0.4f, 0.4f);
            source.volume = Random.Range(0.9f, 1f);
        }
        else
        {
            source.pitch = 1f;
            source.panStereo = 0f;
            source.volume = 1f;
        }
        sources.Enqueue(source);
        return source;
    }

    public void PlayOneShot(AudioClip clip)
    {
        PlayOneShot(clip, true);
    }

    public void PlayOneShot(AudioClipCollection clip)
    {
        PlayOneShot(clip.GetRandomClip(), true);
    }

    public void PlayOneShot(AudioClip clip, bool variation)
    {
        var source = GetSource(variation);
        source.PlayOneShot(clip);
    }

    public void PlayOneShot(AudioClipCollection clip, bool variation)
    {
        PlayOneShot(clip.GetRandomClip(), variation);
    }
}

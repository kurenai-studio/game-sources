using UnityEngine;
using System.Collections.Generic;

[CreateAssetMenu(fileName = "AudioClipCollection", menuName = "AudioClipCollection", order = 1)]
public class AudioClipCollection : ScriptableObject
{
    public List<AudioClip> clips;

    public AudioClip GetRandomClip()
    {
        return clips[Random.Range(0, clips.Count)];
    }
}
using UnityEngine;

public class Soundtrack : MonoBehaviour
{
    public AudioClip[] tracks;
    public AudioSource source;

    int idx = 0;

    void Update()
    {
        if (source.isPlaying) return;

        source.resource = tracks[idx];
        source.Play();

        idx = (idx + 1) % tracks.Length;
    }
}

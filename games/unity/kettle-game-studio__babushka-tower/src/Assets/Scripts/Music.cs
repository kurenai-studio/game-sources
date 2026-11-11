using UnityEngine;

public class Music : MonoBehaviour
{
    public AudioClip[] musics;
    public AudioSource source;
    private int idx = 0;

    public bool pause = false;


    void Update()
    {
        if (pause)
        {
            source.Stop();
        }

        if (!source.isPlaying)
        {
            source.clip = musics[idx];
            idx = (idx + 1) % musics.Length;
            source.Play();
        }
    }
}

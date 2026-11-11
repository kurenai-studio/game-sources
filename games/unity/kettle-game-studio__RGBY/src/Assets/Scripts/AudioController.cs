using UnityEngine;

public class AudioController : MonoBehaviour
{
    public AudioSource audioSource;
    public AudioClip walking;
    public AudioClip flap;
    public enum Sounds { Walk, Flap }

    public void Play(Sounds sound)
    {
        switch (sound)
        {
            case Sounds.Walk:
                PlayClip(walking);
                break;
            case Sounds.Flap:
                PlayClip(flap);
                break;
        }
    }
    public void Stop(Sounds sound)
    {
        switch (sound)
        {
            case Sounds.Walk:
                StopClip(walking);
                break;
            case Sounds.Flap:
                StopClip(flap);
                break;
        }
    }
    void PlayClip(AudioClip clip)
    {
        if (audioSource.clip != clip)
            audioSource.clip = clip;
        if (audioSource.isPlaying) return;
        audioSource.Play();
    }
    void StopClip(AudioClip clip)
    {
        if (audioSource.clip != clip)
            return;
        audioSource.Stop();
    }
    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start()
    {

    }

    // Update is called once per frame
    void Update()
    {

    }
}

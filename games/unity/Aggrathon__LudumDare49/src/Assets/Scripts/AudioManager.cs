using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.Audio;

public class AudioManager : MonoBehaviour
{
    public enum SoundType
    {
        Alert,
        Music,
        Ambient,
        SFX,
    }

    private static AudioManager instance;

    [SerializeField] private List<AudioSource> alertSource;
    [SerializeField] private List<AudioSource> ambientSource;
    [SerializeField] private List<AudioSource> musicSource;
    [SerializeField] private List<AudioSource> sfxSource;

    public List<AudioClip> sceneMusic;

    bool muteMusic;

    void Awake()
    {
        if (instance)
        {
            Destroy(gameObject);
            instance.sceneMusic = sceneMusic;
        }
        else
        {
            instance = this;
            DontDestroyOnLoad(gameObject);
            SceneManager.activeSceneChanged += (a, b) => OnSceneChanged();
        }
    }

    public static void Play(AudioClip clip, SoundType type = SoundType.Alert)
    {
        if (instance)
            instance.PlayClipAt(clip, Vector2.zero, type);
    }

    public static void Play(AudioClip clip, Vector2 position, SoundType type = SoundType.Alert)
    {
        if (instance)
            instance.PlayClipAt(clip, position, type);
    }

    void Update()
    {
        if (!muteMusic)
        {
            for (int i = 0; i < musicSource.Count; i++)
            {
                if (musicSource[i].isPlaying)
                    return;
            }
            if (sceneMusic.Count > 0)
                musicSource[0].PlayOneShot(sceneMusic.Sample());
        }
    }

    public static void ToggleMusic(bool on)
    {
        if (instance)
            instance.InsToggleMusic(on);
    }

    public static bool IsMusicMuted { get { if (instance) return instance.muteMusic; else return false; } }

    void InsToggleMusic(bool on)
    {
        if (!on && !muteMusic)
        {
            foreach (var src in musicSource)
            {
                src.Stop();
            }
        }
        muteMusic = !on;
    }

    void PlayClipAt(AudioClip clip, Vector2 pos, SoundType type)
    {
        List<AudioSource> list = type switch
        {
            SoundType.Alert => alertSource,
            SoundType.Music => ambientSource,
            SoundType.Ambient => musicSource,
            SoundType.SFX => sfxSource,
            _ => alertSource,
        };
        float pitch = 1f;
        if (type == SoundType.Alert || type == SoundType.SFX)
        {
            pitch = Random.Range(0.9f, 1.1f);
        }
        foreach (var source in list)
        {
            if (!source.isPlaying)
            {
                source.transform.position = pos;
                source.pitch = pitch;
                source.PlayOneShot(clip);
                return;
            }
        }
        var source2 = Instantiate(list[0], pos, Quaternion.identity, transform);
        list.Add(source2);
        source2.pitch = pitch;
        source2.PlayOneShot(clip);
    }

    void OnSceneChanged()
    {
        foreach (var source in alertSource)
        {
            source.Stop();
        }
        foreach (var source in ambientSource)
        {
            source.Stop();
        }
    }
}

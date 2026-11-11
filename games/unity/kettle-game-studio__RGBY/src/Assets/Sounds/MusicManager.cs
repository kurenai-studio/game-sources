using UnityEngine;

public class MusicManager : MonoBehaviour 
{
    private static MusicManager _instance;
    public AudioClip main;
    public AudioClip final;
    public AudioSource source;
    public static MusicManager instance
    {
        get
        {
            if(_instance == null)
            {
                _instance = FindFirstObjectByType<MusicManager>();
 
                //Tell unity not to destroy this object when loading a new scene!
                DontDestroyOnLoad(_instance.gameObject);
            }
 
            return _instance;
        }
    }
 
    void Awake() 
    {
        if(_instance == null)
        {
            //If I am the first instance, make me the Singleton
            _instance = this;
            Play();
            DontDestroyOnLoad(this);
        }
        else
        {
            //If a Singleton already exists and you find
            //another reference in scene, destroy it!
            if(this != _instance)
                Destroy(this.gameObject);
        }
    }
 
    public void Play()
    {
        source.clip = main;
        source.Play();
    }
    public void PlayFinish()
    {
        source.clip = final;
        source.Play();
    }
}
using UnityEngine;

public class SoundController : MonoBehaviour
{
    public GameObject MusicSourcePrefab;
    private SoundScript _sound;

    private void Start()
    {
        _sound = FindObjectOfType<SoundScript>();
        if (_sound == null)
        {
            var obj = Instantiate(MusicSourcePrefab);
            DontDestroyOnLoad(obj);
            _sound = obj.GetComponent<SoundScript>();
        }
    }

    private void Update()
    {
        if (!_sound.Source.isPlaying)
            _sound.Source.Play();
    }
}

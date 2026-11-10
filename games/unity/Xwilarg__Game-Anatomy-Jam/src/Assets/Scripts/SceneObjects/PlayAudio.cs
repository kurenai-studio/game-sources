using UnityEngine;

namespace AnatomyJam.SceneObjects
{
    public class PlayAudio : MonoBehaviour
    {
        private AudioSource _source;

        private void Start()
        {
            _source = GetComponent<AudioSource>();
        }

        public void Play()
        {
            _source.Play();
        }
    }
}

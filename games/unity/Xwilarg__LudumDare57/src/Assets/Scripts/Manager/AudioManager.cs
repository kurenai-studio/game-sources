using UnityEngine;

namespace LudumDare57.Manager
{
    public class AudioManager : MonoBehaviour
    {
        public static AudioManager Instance { private set; get; }

        [SerializeField]
        private AudioSource _sfx;

        [SerializeField]
        private AudioClip _onHit, _drill, _buy, _stun;

        private void Awake()
        {
            Instance = this;
        }

        public void PlayPlayerHit() => _sfx.PlayOneShot(_onHit);
        public void PlayDrill() => _sfx.PlayOneShot(_drill);
        public void PlayBuy() => _sfx.PlayOneShot(_buy);
        public void PlayStun() => _sfx.PlayOneShot(_stun);
    }
}
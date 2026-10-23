using System;
using UnityEngine;
using Playfield;

namespace Audio
{
    public class AudioManager : MonoBehaviour
    {
        public static AudioManager Instance;

        [Header("Audio Clips")]
        [SerializeField] private AudioClip paddleBounceSound;
        [SerializeField] private AudioClip wallBounceSound;
        [SerializeField] private AudioClip pointClip;
        
        private AudioSource audioSource;
        
        private void Awake()
        {
            if (!Instance)
            {
                Instance = this;
            }
            else
            {
                Destroy(gameObject);
            }
            
            audioSource = GetComponent<AudioSource>();
        }

        public void Play(SurfaceType surfaceType)
        {
            switch (surfaceType)
            {
                case SurfaceType.Wall:
                    audioSource.PlayOneShot(wallBounceSound);
                    break;
                case SurfaceType.Paddle:
                    audioSource.PlayOneShot(paddleBounceSound);
                    break;
                default:
                    throw new ArgumentOutOfRangeException(nameof(surfaceType), surfaceType, null);
            }
        }

        public void PlayPointClip()
        {
            audioSource.PlayOneShot(pointClip);
        }
    }
}

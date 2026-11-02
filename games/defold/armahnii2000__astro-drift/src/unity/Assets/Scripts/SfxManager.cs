using UnityEngine;

namespace AstroDrift
{
	// Singleton audio manager. Attach to a persistent GameObject in the
	// scene root and assign clips in the inspector. Other scripts call
	// SfxManager.Instance.Play(...) from gameplay events (shoot, hit,
	// death, wave-start). Built procedurally so you can swap clips
	// without rewiring code.
	public class SfxManager : MonoBehaviour
	{
		public static SfxManager Instance { get; private set; }

		public AudioClip shoot;
		public AudioClip asteroidHit;
		public AudioClip playerDeath;
		public AudioClip waveStart;

		private AudioSource _source;

		void Awake()
		{
			if (Instance != null && Instance != this) { Destroy(gameObject); return; }
			Instance = this;
			_source = gameObject.AddComponent<AudioSource>();
			_source.playOnAwake = false;
		}

		public void Play(SoundId id)
		{
			var clip = id switch
			{
				SoundId.Shoot => shoot,
				SoundId.AsteroidHit => asteroidHit,
				SoundId.PlayerDeath => playerDeath,
				SoundId.WaveStart => waveStart,
				_ => null,
			};
			if (clip != null) _source.PlayOneShot(clip, 0.6f);
		}

		public enum SoundId { Shoot, AsteroidHit, PlayerDeath, WaveStart }
	}
}

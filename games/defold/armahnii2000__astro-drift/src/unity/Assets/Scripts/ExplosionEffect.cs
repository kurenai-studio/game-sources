using UnityEngine;

namespace AstroDrift
{
	// A burst-particle GameObject. Spawn one of these from
	// AsteroidController.Hit() with size-scaled emission, then auto-destroy
	// after the particle system finishes. Also pings the CameraShake on the
	// main camera so the screen recoils proportionally to the asteroid size.
	[RequireComponent(typeof(ParticleSystem))]
	public class ExplosionEffect : MonoBehaviour
	{
		public float traumaPerExplosion = 0.35f;
		public AudioClip impactClip;

		private ParticleSystem _ps;

		void Awake()
		{
			_ps = GetComponent<ParticleSystem>();
		}

		void Start()
		{
			_ps.Play();
			if (Camera.main != null)
			{
				var shake = Camera.main.GetComponent<CameraShake>();
				if (shake != null) shake.AddTrauma(traumaPerExplosion);
			}
			if (impactClip != null)
				AudioSource.PlayClipAtPoint(impactClip, transform.position, 0.6f);
			Destroy(gameObject, _ps.main.duration + _ps.main.startLifetime.constantMax);
		}

		public void ScaleTo(float sizeMultiplier)
		{
			var main = _ps.main;
			main.startSize = main.startSize.constant * sizeMultiplier;
			traumaPerExplosion *= sizeMultiplier;
		}
	}
}

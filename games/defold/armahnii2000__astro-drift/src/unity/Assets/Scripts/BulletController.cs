using UnityEngine;

namespace AstroDrift
{
	public class BulletController : MonoBehaviour
	{
		public float lifetime = 1.0f;

		private Camera _cam;
		private float _life;

		void Start()
		{
			_cam = Camera.main;
			_life = lifetime;
		}

		void Update()
		{
			_life -= Time.deltaTime;
			if (_life <= 0f)
			{
				Destroy(gameObject);
				return;
			}
			WrapScreen();
		}

		void WrapScreen()
		{
			if (_cam == null) return;
			Vector3 view = _cam.WorldToViewportPoint(transform.position);
			if (view.x < 0f) view.x = 1f;
			else if (view.x > 1f) view.x = 0f;
			if (view.y < 0f) view.y = 1f;
			else if (view.y > 1f) view.y = 0f;
			transform.position = _cam.ViewportToWorldPoint(view);
		}

		void OnTriggerEnter2D(Collider2D other)
		{
			var asteroid = other.GetComponent<AsteroidController>();
			if (asteroid != null)
			{
				asteroid.Hit();
				Destroy(gameObject);
			}
		}
	}
}

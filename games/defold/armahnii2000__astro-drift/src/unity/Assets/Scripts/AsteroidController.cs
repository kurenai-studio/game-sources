using UnityEngine;

namespace AstroDrift
{
	public class AsteroidController : MonoBehaviour
	{
		public enum SizeTier { Small, Medium, Large }

		public SizeTier size = SizeTier.Large;
		public Vector2 velocity;
		public float spin = 1f;
		public GameObject smallerAsteroidPrefab;

		[HideInInspector] public System.Action<AsteroidController> onDestroyed;

		private Camera _cam;

		void Start()
		{
			_cam = Camera.main;
		}

		void Update()
		{
			transform.position += (Vector3)velocity * Time.deltaTime;
			transform.Rotate(0f, 0f, spin * Time.deltaTime * Mathf.Rad2Deg);
			WrapScreen();
		}

		void WrapScreen()
		{
			if (_cam == null) return;
			Vector3 view = _cam.WorldToViewportPoint(transform.position);
			if (view.x < -0.05f) view.x = 1.05f;
			else if (view.x > 1.05f) view.x = -0.05f;
			if (view.y < -0.05f) view.y = 1.05f;
			else if (view.y > 1.05f) view.y = -0.05f;
			transform.position = _cam.ViewportToWorldPoint(view);
		}

		public void Hit()
		{
			onDestroyed?.Invoke(this);
			if (size != SizeTier.Small && smallerAsteroidPrefab != null)
			{
				for (int i = 0; i < 2; i++)
				{
					var clone = Instantiate(smallerAsteroidPrefab, transform.position, Quaternion.identity);
					var ctl = clone.GetComponent<AsteroidController>();
					if (ctl != null)
					{
						ctl.size = (SizeTier)((int)size - 1);
						float angle = Random.Range(0f, Mathf.PI * 2f);
						ctl.velocity = new Vector2(Mathf.Cos(angle), Mathf.Sin(angle)) * Random.Range(3f, 5f);
						ctl.spin = Random.Range(-2f, 2f);
					}
				}
			}
			Destroy(gameObject);
		}
	}
}

using UnityEngine;

namespace AstroDrift
{
	public class PlayerController : MonoBehaviour
	{
		[Header("Movement")]
		public float thrust = 12f;
		public float rotationSpeed = 240f;
		public float drag = 0.55f;
		public float brakeDrag = 0.08f;
		public float maxSpeed = 16f;

		[Header("Combat")]
		public GameObject bulletPrefab;
		public float bulletSpeed = 24f;
		public float shootCooldown = 0.18f;

		private Vector2 _velocity;
		private float _cooldown;
		private Camera _cam;

		void Start()
		{
			_cam = Camera.main;
		}

		void Update()
		{
			HandleRotation();
			HandleThrust();
			HandleShoot();
			ApplyMotion();
			WrapScreen();
		}

		void HandleRotation()
		{
			float rotInput = 0f;
			if (Input.GetKey(KeyCode.LeftArrow)) rotInput -= 1f;
			if (Input.GetKey(KeyCode.RightArrow)) rotInput += 1f;
			transform.Rotate(0f, 0f, -rotInput * rotationSpeed * Time.deltaTime);
		}

		void HandleThrust()
		{
			if (!Input.GetKey(KeyCode.UpArrow)) return;
			float angle = transform.eulerAngles.z * Mathf.Deg2Rad;
			Vector2 forward = new Vector2(-Mathf.Sin(angle), Mathf.Cos(angle));
			_velocity += forward * thrust * Time.deltaTime;
		}

		void HandleShoot()
		{
			_cooldown -= Time.deltaTime;
			bool firing = Input.GetKey(KeyCode.Delete);
			if (!firing || _cooldown > 0f || bulletPrefab == null) return;
			_cooldown = shootCooldown;
			float angle = transform.eulerAngles.z * Mathf.Deg2Rad;
			Vector2 forward = new Vector2(-Mathf.Sin(angle), Mathf.Cos(angle));
			var bullet = Instantiate(bulletPrefab, transform.position + (Vector3)forward * 0.5f, transform.rotation);
			var rb = bullet.GetComponent<Rigidbody2D>();
			if (rb != null) rb.linearVelocity = forward * bulletSpeed;
		}

		void ApplyMotion()
		{
			bool braking = Input.GetKey(KeyCode.DownArrow);
			float damp = braking ? brakeDrag : drag;
			_velocity *= Mathf.Pow(damp, Time.deltaTime);
			_velocity = Vector2.ClampMagnitude(_velocity, maxSpeed);
			transform.position += (Vector3)_velocity * Time.deltaTime;
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
	}
}

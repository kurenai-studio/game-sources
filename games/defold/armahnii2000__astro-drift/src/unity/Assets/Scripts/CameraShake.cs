using UnityEngine;

namespace AstroDrift
{
	// Attach to the main camera. Other scripts call AddTrauma(amount) on hits
	// or destruction events. Trauma decays exponentially each frame; the actual
	// shake offset is trauma^2 so small impacts barely register but large ones
	// (player death, big asteroid split) really rattle the screen.
	public class CameraShake : MonoBehaviour
	{
		[Range(0f, 1f)] public float trauma = 0f;
		public float decay = 1.6f;
		public float maxOffset = 0.6f;
		public float maxAngle = 4f;

		private Vector3 _baseLocalPos;
		private Quaternion _baseLocalRot;

		void Awake()
		{
			_baseLocalPos = transform.localPosition;
			_baseLocalRot = transform.localRotation;
		}

		public void AddTrauma(float amount)
		{
			trauma = Mathf.Clamp01(trauma + amount);
		}

		void LateUpdate()
		{
			trauma = Mathf.Max(0f, trauma - decay * Time.deltaTime);
			float shake = trauma * trauma;
			Vector3 offset = new Vector3(
				(Random.value * 2f - 1f) * maxOffset * shake,
				(Random.value * 2f - 1f) * maxOffset * shake,
				0f);
			float roll = (Random.value * 2f - 1f) * maxAngle * shake;
			transform.localPosition = _baseLocalPos + offset;
			transform.localRotation = _baseLocalRot * Quaternion.Euler(0f, 0f, roll);
		}
	}
}

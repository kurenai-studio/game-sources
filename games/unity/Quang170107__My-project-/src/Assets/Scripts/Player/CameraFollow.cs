using UnityEngine;

namespace SimpleRPG
{
    public class CameraFollow : MonoBehaviour
    {
        public static CameraFollow Instance { get; private set; }

        public Transform target;
        public float smoothSpeed = 8f;
        public Vector2 minBounds = new Vector2(-15, -15);
        public Vector2 maxBounds = new Vector2(15, 15);

        private Vector3 _shakeOffset = Vector3.zero;
        private float _shakeDuration = 0f;
        private float _shakeMagnitude = 0f;

        private void Awake()
        {
            Instance = this;
        }

        public void SetTarget(Transform newTarget)
        {
            target = newTarget;
            if (target != null)
            {
                transform.position = new Vector3(target.position.x, target.position.y, -10f);
            }
        }

        public void Shake(float duration = 0.15f, float magnitude = 0.2f)
        {
            if (!SettingsManager.IsVibrationOn) return;

            _shakeDuration = duration;
            _shakeMagnitude = magnitude;
        }

        public void StopShake()
        {
            _shakeDuration = 0f;
            _shakeMagnitude = 0f;
            _shakeOffset = Vector3.zero;
        }

        private void LateUpdate()
        {
            if (target == null) return;

            Vector3 desiredPos = new Vector3(
                Mathf.Clamp(target.position.x, minBounds.x, maxBounds.y),
                Mathf.Clamp(target.position.y, minBounds.y, maxBounds.y),
                -10f
            );

            // Screen shake is part of the Vibration setting — skip it when the player turns that off.
            if (SettingsManager.IsVibrationOn && _shakeDuration > 0f)
            {
                _shakeOffset = (Vector3)(Random.insideUnitCircle * _shakeMagnitude);
                _shakeDuration -= Time.deltaTime;
            }
            else
            {
                _shakeOffset = Vector3.zero;
                if (!SettingsManager.IsVibrationOn)
                    _shakeDuration = 0f;
            }

            Vector3 smoothed = Vector3.Lerp(transform.position, desiredPos, smoothSpeed * Time.deltaTime);
            transform.position = smoothed + _shakeOffset;
        }
    }
}

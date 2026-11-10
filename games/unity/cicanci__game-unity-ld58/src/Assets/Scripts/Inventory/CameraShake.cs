using System.Collections;
using UnityEngine;

public class CameraShake : MonoBehaviour
{
    [SerializeField]
    private float _shakeIntensity;

    [SerializeField]
    private float _shakeDuration;

    private float _shakeCounter;
    private Vector3 _originalPos;
    private Coroutine _shakeCameraCoroutine;

    private void Start()
    {
        _originalPos = transform.localPosition;
    }

    private void OnEnable()
    {
        MessageQueue.Instance.AddListener<HealthUpdateMessage>(OnHealthUpdated);
    }

    private void OnDisable()
    {
        MessageQueue.Instance.RemoveListener<HealthUpdateMessage>(OnHealthUpdated);
    }

    private void ShakeCamera()
    {
        if (_shakeCameraCoroutine != null)
        {
            StopCoroutine(_shakeCameraCoroutine);
        }
        _shakeCameraCoroutine = StartCoroutine(ShakeCameraCoroutine());
    }

    private IEnumerator ShakeCameraCoroutine()
    {
        while (_shakeCounter > 0)
        {
            yield return null;
            transform.localPosition = _originalPos + Random.insideUnitSphere * _shakeIntensity;
            _shakeCounter -= Time.deltaTime;
        }

        _shakeCounter = 0;
        transform.localPosition = _originalPos;
    }

    private void OnHealthUpdated(HealthUpdateMessage message)
    {
        _shakeCounter = _shakeDuration;
        ShakeCamera();
    }
}
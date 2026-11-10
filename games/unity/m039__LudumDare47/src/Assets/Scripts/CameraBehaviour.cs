using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class CameraBehaviour : MonoBehaviour
{
    const float ReferenOrbitRadius = 11.57f; // Magic number.

    [Header("Settings")]
    public Transform targetToLock;

    public Vector3 offset = Vector3.one;

    [Header("Dependencies")]
    public PlayerBehaviour player;

    public float moveSpeed = 20;

    public float moveSpeedBoost = 40f;

    public float lookAtSpeed = 10f;

    public float lookAtSpeedBoost = 20f;

    Vector3 _newPosition;

    Vector3 _lookAtPosition;

    public bool UseBoostSpeed { get; set; } = false;

    private void OnEnable()
    {
        ResetCamera();
    }

    private void OnValidate()
    {
        ResetCamera();
    }

    void LateUpdate()
    {
        UpdateCameraWithOffset();

        if (!Application.isPlaying)
            return;

        // Move to new position.
        {
            var delta = GetRightSpeed(moveSpeed, moveSpeedBoost) * Time.deltaTime;
            var direction = (_newPosition - Camera.main.transform.position);
            if (direction.magnitude > delta)
            {
                direction = direction.normalized * delta;
            }

            Camera.main.transform.position += direction;
        }

        // Lock to target.

        if (targetToLock != null)
        {
            var delta = GetRightSpeed(lookAtSpeed, lookAtSpeedBoost) * Time.deltaTime;
            var direction = (targetToLock.position - _lookAtPosition);
            if (direction.magnitude > delta)
            {
                direction = direction.normalized * delta;
            }

            _lookAtPosition += direction;

            Camera.main.transform.LookAt(_lookAtPosition);
        }
    }

    float GetRightSpeed(float normalSpeed, float boostSpeed)
    {
        var currentOrbitRadius = GameScene.Instance.CurrentOrbit.radius;
        var coeff = 1f;
        if (currentOrbitRadius > ReferenOrbitRadius)
        {
            coeff = ReferenOrbitRadius / currentOrbitRadius;
        }

        return (UseBoostSpeed ? boostSpeed : normalSpeed) * coeff;
    }

    public void ResetCamera()
    {
        UpdateCameraWithOffset();

        // Reset position.

        if (Application.isPlaying)
        {
            Camera.main.transform.position = _newPosition;
        }

        // Reset look at.

        if (targetToLock != null)
        {
            _lookAtPosition = targetToLock.transform.position;
        }
    }

    void UpdateCameraWithOffset()
    {
        if (player == null)
            return;

        var rotation = Quaternion.Euler(0, player.BulletRotation.eulerAngles.y, 0);
        var newPosition = player.transform.position + rotation * offset;

        if (Application.isPlaying)
        {
            _newPosition = newPosition;
        } else
        {
            transform.position = newPosition;
        }
    }
}

using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MenuPlayerBehaviour : MonoBehaviour
{
    public BaseOrbit orbit;

    public float speed = 10f;

    float _angle;

    private void Start()
    {
        UpdatePositionAndRotation();
    }

    void Update()
    {
        UpdatePositionAndRotation();
    }

    void UpdatePositionAndRotation()
    {
        var rotation = Quaternion.Euler(0, _angle, 0);

        transform.rotation = rotation;
        transform.position = orbit.transform.position + rotation * Vector3.forward * orbit.radius;

        _angle += Time.deltaTime * speed;

        if (_angle > 360)
        {
            _angle = 0;
        } else if (_angle < 0)
        {
            _angle = 360;
        }
    }
}

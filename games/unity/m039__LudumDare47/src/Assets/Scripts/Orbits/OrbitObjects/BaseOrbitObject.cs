using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class BaseOrbitObject : MonoBehaviour
{

    [Range(0, 1)]
    public float position;

    [Range(0, 1)]
    public float positionOffsetMagnitude;

    [Range(0, 360)]
    public float positionOffsetAngle;

    public AudioClip pickSound;

    public BaseOrbit orbit;

    [NonSerialized]
    Transform _renderer;

    bool _visibility = true;

    protected virtual void Awake()
    {
        _renderer = transform.Find("Renderer");
    }

    protected virtual void OnEnable()
    {
        UpdatePosition();
    }

    protected virtual void OnValidate()
    {
        UpdatePosition();
    }

    void UpdatePosition()
    {
        if (orbit != null)
        {
            var angle = position * 2 * Mathf.PI * Mathf.Rad2Deg;

            var positionOffset = Vector2.zero;

            positionOffset.y = Mathf.Sin(positionOffsetAngle * Mathf.Deg2Rad);
            positionOffset.x = Mathf.Cos(positionOffsetAngle * Mathf.Deg2Rad);

            positionOffset *= positionOffsetMagnitude;

            transform.position = orbit.GetPositionAlognOrbit(angle, positionOffset);
        }
    }

    public bool GetVisibility() => _visibility;

    public virtual void SetVisibility(bool visibility)
    {
        if (_renderer != null)
        {
            _renderer.gameObject.SetActive(visibility);
        }

        if (GetComponent<Collider>() is Collider collider)
        {
            collider.enabled = visibility;
        }

        _visibility = visibility;
    }

}

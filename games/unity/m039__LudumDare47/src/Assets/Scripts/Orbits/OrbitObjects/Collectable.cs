using m039.Common;
using System;
using UnityEngine;
using UnityEngine.Rendering;

public class Collectable : BaseOrbitObject
{

    const float CoeffEmissionMultiplier = 1.5f;

    [HideInInspector]
    public float EmissionValue = 0f;

    public Color EmissionColor = Color.green;

    float _previousEmissionValue = float.NaN;

    [NonSerialized]
    Renderer _renderer;

    //MaterialPropertyBlock _materialPropertyBlock;

    protected override void Awake()
    {
        base.Awake();

        if (!Application.isPlaying)
            return;

        _renderer = GetComponentInChildren<Renderer>();
        _renderer.material = new Material(_renderer.material);

        //_materialPropertyBlock = new MaterialPropertyBlock();
    }

    private void LateUpdate()
    {
        if (!Application.isPlaying)
            return;

        if (_previousEmissionValue != EmissionValue)
        {
            SetEmissionValue(EmissionValue);
            _previousEmissionValue = EmissionValue;
        }
    }

    void SetEmissionValue(float value)
    {
        if (_renderer == null)
            return;

        //_renderer.GetPropertyBlock(_materialPropertyBlock);

        //_materialPropertyBlock.SetColor("_EmissionColor", EmissionColor.WithValue(value * CoeffEmissionMultiplier));

        //_renderer.SetPropertyBlock(_materialPropertyBlock);

        _renderer.material.SetColor("_EmissionColor", EmissionColor.WithValue(value * CoeffEmissionMultiplier));
        _renderer.material.EnableKeyword("_EMISSION");
    }

}
